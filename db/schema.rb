# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_13_235000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "bank_accounts", force: :cascade do |t|
    t.string "account_type", default: "checking", null: false
    t.decimal "balance", precision: 15, scale: 2, default: "0.0"
    t.string "bank_name"
    t.decimal "cdi_multiplier", precision: 8, scale: 4, default: "100.0"
    t.string "color", default: "#6C63FF"
    t.datetime "created_at", null: false
    t.string "currency", default: "BRL"
    t.decimal "interest_rate", precision: 8, scale: 4, default: "0.0"
    t.string "name", null: false
    t.string "rate_type", default: "fixed", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_bank_accounts_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "color", default: "#6C63FF", null: false
    t.datetime "created_at", null: false
    t.string "icon"
    t.string "name", null: false
    t.string "slug"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "slug"], name: "index_categories_on_user_id_and_slug", unique: true
    t.index ["user_id"], name: "index_categories_on_user_id"
  end

  create_table "credit_cards", force: :cascade do |t|
    t.integer "billing_day", default: 1
    t.string "brand"
    t.string "color", default: "#6C63FF"
    t.datetime "created_at", null: false
    t.integer "due_day", default: 10
    t.string "last4"
    t.decimal "limit", precision: 10, scale: 2, default: "0.0"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_credit_cards_on_user_id"
  end

  create_table "expenses", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.bigint "bank_account_id"
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.bigint "credit_card_id"
    t.date "date", null: false
    t.string "description"
    t.string "expense_type", default: "variable", null: false
    t.string "installment_group_id"
    t.integer "installment_number", default: 1, null: false
    t.string "payment_method", default: "credit_card", null: false
    t.string "payment_status"
    t.integer "recurrence_day"
    t.boolean "recurring", default: false
    t.bigint "recurring_source_id"
    t.integer "total_installments", default: 1, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["bank_account_id"], name: "index_expenses_on_bank_account_id"
    t.index ["category_id"], name: "index_expenses_on_category_id"
    t.index ["credit_card_id"], name: "index_expenses_on_credit_card_id"
    t.index ["recurring_source_id"], name: "index_expenses_on_recurring_source_id"
    t.index ["user_id"], name: "index_expenses_on_user_id"
  end

  create_table "incomes", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.string "description", null: false
    t.string "income_type", default: "salary", null: false
    t.integer "recurrence_day"
    t.boolean "recurring", default: false
    t.bigint "recurring_source_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_incomes_on_user_id"
  end

  create_table "investments", force: :cascade do |t|
    t.decimal "average_price", precision: 20, scale: 8, default: "0.0"
    t.datetime "created_at", null: false
    t.string "currency", default: "BRL"
    t.decimal "current_price", precision: 20, scale: 8, default: "0.0"
    t.string "investment_type", default: "stock", null: false
    t.datetime "last_price_update_at"
    t.string "name", null: false
    t.decimal "quantity", precision: 20, scale: 8, default: "0.0"
    t.string "ticker"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["ticker", "investment_type"], name: "index_investments_on_ticker_and_investment_type"
    t.index ["user_id"], name: "index_investments_on_user_id"
  end

  create_table "possessions", force: :cascade do |t|
    t.string "color", default: "#6C63FF"
    t.datetime "created_at", null: false
    t.string "currency", default: "BRL"
    t.decimal "current_value", precision: 10, scale: 2
    t.string "name", null: false
    t.text "notes"
    t.string "possession_type", default: "other", null: false
    t.date "purchase_date"
    t.decimal "purchase_price", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_possessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency"
    t.integer "default_category_id"
    t.integer "default_credit_card_id"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.string "locale", default: "pt-BR", null: false
    t.datetime "locked_at"
    t.string "name"
    t.boolean "password_set", default: false, null: false
    t.string "provider"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "uid"
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.index ["default_category_id"], name: "index_users_on_default_category_id"
    t.index ["default_credit_card_id"], name: "index_users_on_default_credit_card_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "bank_accounts", "users"
  add_foreign_key "categories", "users"
  add_foreign_key "credit_cards", "users"
  add_foreign_key "expenses", "bank_accounts"
  add_foreign_key "expenses", "categories"
  add_foreign_key "expenses", "credit_cards"
  add_foreign_key "expenses", "users"
  add_foreign_key "incomes", "users"
  add_foreign_key "investments", "users"
  add_foreign_key "possessions", "users"
  add_foreign_key "users", "categories", column: "default_category_id"
  add_foreign_key "users", "credit_cards", column: "default_credit_card_id"
end
