# Plan: Bank Notification Automation

## Context
The app is a multi-user personal finance tracker. Users manually add variable expenses and manually mark fixed expenses as "paid." The goal is to automate both by intercepting bank push notifications (Nubank, MercadoPago, and others) on the user's phone and forwarding them to the Rails app via a webhook. The Rails app parses the notification, then either auto-marks a matching fixed expense as paid or creates a new variable expense.

The mobile side uses:
- **iOS:** Apple Shortcuts automation (no extra app needed)
- **Android:** Tasker or similar

---

## Architecture Overview

```
Phone (bank notification arrives)
  → iOS Shortcut / Android Tasker
    → POST /api/notifications  (with user API token)
      → BankNotifications::ParseService  (extracts amount, description, type)
        → BankTransactions::ProcessService
            ├── match pending fixed expense → mark as paid
            └── no match → create variable expense (apply category rules)
```

---

## Phase 1: Rails Webhook Infrastructure

### 1.1 Database Migrations

**Add `api_token` to users:**
```ruby
add_column :users, :api_token, :string
add_index :users, :api_token, unique: true
```
Auto-generate on user creation (SecureRandom.hex(32)).

**Create `category_rules` table:**
```ruby
create_table :category_rules do |t|
  t.string   :keyword,     null: false
  t.bigint   :category_id, null: false
  t.bigint   :user_id,     null: false
  t.integer  :priority,    default: 0
  t.timestamps
end
```
Rules are evaluated in priority order; first match wins.

**Add `external_transaction_id` to expenses:**
```ruby
add_column :expenses, :external_transaction_id, :string
add_index :expenses, [:user_id, :external_transaction_id], unique: true
```
Prevents duplicate imports when notification is forwarded multiple times.

### 1.2 Models

**`CategoryRule`** (`app/models/category_rule.rb`):
- `belongs_to :user`, `belongs_to :category`
- `validates :keyword, :category_id, :user_id, presence: true`
- Scope: `ordered` (by priority desc, then id asc)

**User model additions** (`app/models/user.rb`):
- `before_create :generate_api_token`
- `has_many :category_rules`

### 1.3 API Endpoint

**Route** (`config/routes.rb`):
```ruby
namespace :api do
  post :notifications, to: "notifications#create"
end
```

**Controller** (`app/controllers/api/notifications_controller.rb`):
- Authenticate via `Authorization: Bearer <api_token>` header
- Find user by token; return 401 if not found
- Accept JSON body: `{ app_name:, title:, body: }`
- Enqueue `BankNotifications::ProcessJob.perform_later(user_id:, payload:)`
- Return 200 immediately (async processing)
- Skip CSRF verification (API endpoint)
- Add to rack-attack rate limiting: 60 req/min per token

### 1.4 Background Job

**`app/jobs/bank_notifications/process_job.rb`**:
- Calls `BankNotifications::ParseService.call(payload)`
- If parse fails / amount is nil: log and return (ignore non-transaction notifications)
- Calls `BankTransactions::ProcessService.call(user:, transaction:)`

### 1.5 Parser Service

**`app/services/bank_notifications/parse_service.rb`**:
- Routes to parser based on `app_name` (case-insensitive partial match)
- Falls back to `Generic` parser if no specific parser matches
- Returns a `ParsedTransaction` struct: `{ amount, description, payment_method, external_id }`

**Parser classes** (all inherit from `Base`):
- `app/services/bank_notifications/parsers/base.rb` — defines interface
- `app/services/bank_notifications/parsers/nubank.rb` — Nubank patterns
- `app/services/bank_notifications/parsers/mercado_pago.rb` — MercadoPago patterns
- `app/services/bank_notifications/parsers/generic.rb` — regex for "R$ X,XX" pattern

**Parser registry** in `ParseService` maps app names → parser classes:
```ruby
PARSERS = {
  /nubank/i        => Parsers::Nubank,
  /mercado.?pago/i => Parsers::MercadoPago,
}
```
New banks just require adding a new parser class and a registry entry — no core changes.

**`payment_method` detection:**
- "Pix" in notification text → `:pix`
- "crédito" / "débito" / credit card name → `:credit_card`
- Boleto keywords → `:boleto`
- Default → `:cash`

**`external_id` generation:**
- SHA256 of `"#{user_id}:#{app_name}:#{title}:#{body}"` (idempotent deduplication)

### 1.6 Transaction Processor

**`app/services/bank_transactions/process_service.rb`**:
1. Check `expenses.where(external_transaction_id: transaction.external_id)` — skip if already processed
2. Call `MatchFixedExpenseService.call(user:, transaction:)`
3. If match found: update expense `payment_status: :paid`, set `external_transaction_id`
4. If no match: call `CreateVariableExpenseService.call(user:, transaction:)`

**`app/services/bank_transactions/match_fixed_expense_service.rb`**:
- Query: `user.expenses.fixed.where(payment_status: [:pending, :scheduled])`
- Filter: `amount == transaction.amount`
- Filter: `date BETWEEN (today - 5 days) AND (today + 5 days)`
- Optionally filter by `payment_method` if notification clearly indicates Pix/credit card
- Return first match (or nil)

**`app/services/bank_transactions/create_variable_expense_service.rb`**:
- Apply category rules: check `user.category_rules.ordered` for keyword match in `transaction.description`
- Use fallback category if no rule matches (create a system default "Uncategorized" or use first user category)
- Build and save `Expense` with: `expense_type: :variable`, `date: Date.today`, `amount:`, `description:`, `category_id:`, `external_transaction_id:`

---

## Phase 2: Category Rules UI

**Routes:**
```ruby
resources :category_rules
```

**Controller** (`app/controllers/category_rules_controller.rb`): standard CRUD, scoped to `current_user`.

**Views** (`app/views/category_rules/`):
- `index.html.erb` — table of rules with keyword, category, priority, edit/delete
- `_form.html.erb` — keyword text field, category select, priority number field
- Consistent with existing dark-theme UI styles

---

## Phase 3: User API Token UI

Add to the user's settings/profile page:
- Display their API token (masked by default, show on click)
- "Regenerate token" button
- Step-by-step instructions for setting up iOS Shortcuts and Android Tasker

**Routes:**
```ruby
resource :profile do
  post :regenerate_api_token
end
```

---

## Mobile Setup

### iOS Shortcut (per bank app):
1. Open Shortcuts → Automations → New Automation
2. Trigger: "When I receive a notification from [Nubank]"
3. Action: "Get Details of Notification" (get Body + Title + App Name)
4. Action: "Get Contents of URL" — POST to `https://yourapp.com/api/notifications`
   - Headers: `Authorization: Bearer <token>`, `Content-Type: application/json`
   - Body: `{ "app_name": "Nubank", "title": <title>, "body": <body> }`
5. Run without asking — enable "Always Run"

### Android (Tasker):
1. Event: Notification → App: [Nubank]
2. Task: HTTP POST to `/api/notifications` with same payload

---

## Critical Files to Modify/Create

| File | Action |
|------|--------|
| `db/migrate/..._add_api_token_to_users.rb` | Create |
| `db/migrate/..._create_category_rules.rb` | Create |
| `db/migrate/..._add_external_transaction_id_to_expenses.rb` | Create |
| `app/models/user.rb` | Modify (api_token, has_many :category_rules) |
| `app/models/category_rule.rb` | Create |
| `app/models/expense.rb` | Modify (add external_transaction_id) |
| `config/routes.rb` | Modify (api namespace, category_rules, profile) |
| `app/controllers/api/notifications_controller.rb` | Create |
| `app/controllers/category_rules_controller.rb` | Create |
| `app/jobs/bank_notifications/process_job.rb` | Create |
| `app/services/bank_notifications/parse_service.rb` | Create |
| `app/services/bank_notifications/parsers/base.rb` | Create |
| `app/services/bank_notifications/parsers/nubank.rb` | Create |
| `app/services/bank_notifications/parsers/mercado_pago.rb` | Create |
| `app/services/bank_notifications/parsers/generic.rb` | Create |
| `app/services/bank_transactions/process_service.rb` | Create |
| `app/services/bank_transactions/match_fixed_expense_service.rb` | Create |
| `app/services/bank_transactions/create_variable_expense_service.rb` | Create |
| `app/views/category_rules/` | Create |
| Profile/settings view | Modify |
| `config/locales/en.yml`, `pt-BR.yml`, `es.yml` | Modify (new i18n keys) |

---

## Reuse Existing Patterns

- `app/jobs/investments/fetch_price_job.rb` — pattern for background jobs
- `app/lib/cdi_rate.rb` — pattern for service objects with external data
- `app/controllers/expenses_controller.rb` — `update_status` for marking paid
- `Expense#next_payment_status` — reuse or call `update!(payment_status: :paid)` directly
- `config/initializers/rack_attack.rb` — add rate limiting for new API endpoint

---

## Verification / Testing

### Unit Tests
- `test/services/bank_notifications/parsers/nubank_test.rb` — parse Pix/credit card notifications
- `test/services/bank_notifications/parsers/mercado_pago_test.rb`
- `test/services/bank_notifications/parsers/generic_test.rb` — R$ regex fallback
- `test/services/bank_transactions/process_service_test.rb` — match + mark paid, no match + create
- `test/services/bank_transactions/match_fixed_expense_service_test.rb`
- `test/models/category_rule_test.rb`

### Controller Tests
- `test/controllers/api/notifications_controller_test.rb`
  - Valid token → 200, job enqueued
  - Invalid token → 401
  - Rate limit → 429

### End-to-End Test
1. Create a fixed expense with `payment_status: :pending`, amount: 150.00, date: today
2. POST to `/api/notifications` with a fake Nubank Pix notification for R$ 150,00
3. Verify expense is now `payment_status: :paid`
4. POST same notification again → verify no duplicate processing
5. POST a notification with no matching fixed expense → verify new variable expense created
6. Add a category rule for "iFood" → Post an iFood notification → verify correct category assigned
