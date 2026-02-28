class CreateInvestments < ActiveRecord::Migration[8.1]
  def change
    create_table :investments do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :ticker
      t.string :investment_type, null: false, default: "stock"
      t.decimal :quantity, precision: 20, scale: 8, default: 0
      t.decimal :average_price, precision: 20, scale: 8, default: 0
      t.decimal :current_price, precision: 20, scale: 8, default: 0
      t.string :currency, default: "BRL"
      t.datetime :last_price_update_at

      t.timestamps
    end
  end
end
