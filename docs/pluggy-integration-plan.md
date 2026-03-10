# Plan: Pluggy Open Finance Integration

## Context
The app currently has no automatic bank data ingestion — all expenses, incomes, and bank balances are entered manually. This plan integrates [Pluggy](https://pluggy.ai) (a Brazilian Open Finance aggregator) so the user can connect real bank accounts and have transactions and balances synced automatically. The feature is gated behind a per-user on/off toggle.

**User decisions:**
- Import debits → Expenses, credits → Incomes, and update BankAccount balances
- Auto-skip duplicates (same date + amount already in DB → don't import)
- Auto-categorize by matching Pluggy's transaction category to existing user categories (ILIKE)
- Global per-user toggle (`pluggy_sync_enabled`)

---

## New DB Tables

### `pluggy_items` (one row = one bank connection)
| column | type | notes |
|---|---|---|
| id | bigint PK | |
| user_id | bigint FK | |
| pluggy_item_id | string | Pluggy's item ID |
| bank_name | string | |
| status | string | active / error / updating |
| last_synced_at | datetime | |
| timestamps | | |

### `pluggy_accounts` (one row = one account within a bank)
| column | type | notes |
|---|---|---|
| id | bigint PK | |
| pluggy_item_id | bigint FK | → pluggy_items |
| pluggy_account_id | string | Pluggy's account ID |
| name | string | |
| account_type | string | bank / credit |
| local_account_id | integer | optional FK to bank_accounts or credit_cards |
| local_account_type | string | "BankAccount" or "CreditCard" |
| enabled | boolean | default true |
| timestamps | | |

## Modified Tables

- **`expenses`**: add `external_id` (string, indexed), `source` (string, default: "manual")
- **`incomes`**: add `external_id` (string, indexed), `source` (string, default: "manual")
- **`users`**: add `pluggy_sync_enabled` (boolean, default: false)

---

## New Files

### Models
- `app/models/pluggy_item.rb` — belongs_to :user, has_many :pluggy_accounts; status enum (active/error/updating)
- `app/models/pluggy_account.rb` — belongs_to :pluggy_item; optional link to local bank_accounts/credit_cards

### API Client
- `app/lib/pluggy/client.rb` — HTTParty client (same pattern as `app/lib/cdi_rate.rb`)
  - `authenticate` → `POST /auth` with clientId + clientSecret, cache api_key for 2h in Rails.cache
  - `create_connect_token(item_id: nil)` → `POST /connect_token`
  - `get_item(item_id)` → `GET /items/:id`
  - `get_accounts(item_id)` → `GET /accounts?itemId=:id`
  - `get_transactions(account_id, from:, to:)` → `GET /transactions?accountId=:id&from=&to=`
  - Credentials from `Rails.application.credentials.pluggy` (client_id, client_secret)

### Transaction Importer
- `app/lib/pluggy/transaction_importer.rb`
  - `import(pluggy_account:, user:)` — main entry point
  - Fetches transactions from `last_synced_at` (or 30 days back on first sync)
  - For each transaction:
    - `DEBIT` → Expense, `CREDIT` → Income
    - Skip if `external_id` already exists (already imported)
    - Skip if same `date` + `amount` already exists without external_id (auto-dedup for manual entries)
    - Auto-categorize: `user.categories.where("name ILIKE ?", pluggy_category).first`
  - After import: updates `PluggyItem#last_synced_at`

### Background Job
- `app/jobs/pluggy/sync_item_job.rb` — `perform(pluggy_item_id)`
  - Loads PluggyItem, iterates enabled PluggyAccounts
  - Calls `Pluggy::TransactionImporter.import(pluggy_account:, user:)` for each
  - Updates linked BankAccount balance if `local_account_id` set and `account_type == "bank"`

### Controllers
- `app/controllers/pluggy/items_controller.rb`
  - `index` — list user's connections (scoped to current_user)
  - `create` — receive `item_id` from JS widget callback → create PluggyItem, fetch+create PluggyAccounts, enqueue SyncItemJob
  - `destroy` — delete PluggyItem + cascade accounts (does NOT delete imported expenses/incomes)

- `app/controllers/pluggy/connect_tokens_controller.rb`
  - `create` — calls `Pluggy::Client.new.create_connect_token`, returns JSON `{access_token:}`

- `app/controllers/pluggy/webhooks_controller.rb`
  - `receive` (POST) — verify Pluggy signature header, find PluggyItem, enqueue SyncItemJob
  - Skips CSRF (external webhook source)

### Views
- `app/views/pluggy/items/index.html.erb` — Connections management page
  - List of connected banks (name, status, last_synced_at, # accounts)
  - "Connect bank" button → opens Pluggy widget via Stimulus controller
  - Disconnect button (destroy)
  - Each row shows linked local accounts (editable mapping)

### JavaScript
- `app/javascript/controllers/pluggy_connect_controller.js` — Stimulus controller
  - `openWidget()` — POST to `/pluggy/connect_tokens`, opens PluggyConnect widget
  - `onSuccess(itemData)` — POST to `/pluggy/items` with `item_id`, Turbo reload
  - Load Pluggy Connect JS from CDN in layout or items view only:
    `<script src="https://cdn.pluggy.ai/pluggy-connect/v2/pluggy-connect.js"></script>`

### Routes
Add to `config/routes.rb`:
```ruby
namespace :pluggy do
  resources :items, only: [:index, :create, :destroy]
  resources :connect_tokens, only: [:create]
  post :webhooks, to: "webhooks#receive"
end
```

---

## Modified Files

### `app/controllers/user/settings_controller.rb`
- `update_profile` branch: permit `pluggy_sync_enabled`

### `app/views/user/settings/edit.html.erb`
- Add "Connections" section with toggle for `pluggy_sync_enabled`
- Link to `/pluggy/items` when enabled

### `app/views/expenses/_expense.html.erb`
- Add small "imported" badge/icon when `expense.source == "pluggy"`

### `app/views/incomes/` (relevant partial)
- Same imported badge for pluggy-sourced incomes

### `config/locales/en.yml`, `pt-BR.yml`, `es.yml`
- Add keys for: Connections section title, status labels (active/error/updating), "imported" badge text, settings toggle label

---

## Migrations (5 files)
1. `create_pluggy_items`
2. `create_pluggy_accounts`
3. `add_pluggy_sync_enabled_to_users` (default: false)
4. `add_source_and_external_id_to_expenses` (source default: "manual", index on external_id)
5. `add_source_and_external_id_to_incomes` (source default: "manual", index on external_id)

---

## Environment / Credentials
Add to Rails credentials (`rails credentials:edit`):
```yaml
pluggy:
  client_id: "..."
  client_secret: "..."
```
Get these from the [Pluggy dashboard](https://dashboard.pluggy.ai).

---

## Tests to Write
- `test/models/pluggy_item_test.rb`
- `test/models/pluggy_account_test.rb`
- `test/jobs/pluggy/sync_item_job_test.rb` (mock Pluggy API responses with HTTParty stubs)
- `test/controllers/pluggy/items_controller_test.rb`
- `test/controllers/pluggy/webhooks_controller_test.rb`

## Manual Verification Steps
1. Obtain Pluggy sandbox credentials from the dashboard
2. Add credentials via `rails credentials:edit`
3. Enable Pluggy sync in user settings
4. Go to `/pluggy/items`, click "Connect bank", authenticate with a sandbox bank
5. Verify expenses/incomes appear with `source: "pluggy"`
6. Add a manual expense with the same date + amount → verify no duplicate is created on next sync
7. Verify BankAccount balance updates after sync
8. Disable toggle in settings → verify no new syncs run
