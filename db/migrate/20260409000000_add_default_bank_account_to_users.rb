class AddDefaultBankAccountToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :default_bank_account_id, :integer
    add_foreign_key :users, :bank_accounts, column: :default_bank_account_id
    add_index :users, :default_bank_account_id
  end
end
