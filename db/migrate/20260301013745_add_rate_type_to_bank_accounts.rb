class AddRateTypeToBankAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :bank_accounts, :rate_type, :string, null: false, default: "fixed"
    add_column :bank_accounts, :cdi_multiplier, :decimal, precision: 8, scale: 4, default: "100.0"
  end
end
