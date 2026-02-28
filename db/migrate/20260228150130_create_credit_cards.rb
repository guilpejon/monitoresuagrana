class CreateCreditCards < ActiveRecord::Migration[8.1]
  def change
    create_table :credit_cards do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.decimal :limit, precision: 10, scale: 2, default: 0
      t.string :last4
      t.string :brand
      t.string :color, default: "#6C63FF"
      t.integer :billing_day, default: 1
      t.integer :due_day, default: 10

      t.timestamps
    end
  end
end
