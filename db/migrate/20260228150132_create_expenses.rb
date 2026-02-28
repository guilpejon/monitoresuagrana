class CreateExpenses < ActiveRecord::Migration[8.1]
  def change
    create_table :expenses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.references :credit_card, null: true, foreign_key: true
      t.string :description, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.date :date, null: false
      t.string :expense_type, null: false, default: "variable"
      t.boolean :recurring, default: false
      t.integer :recurrence_day

      t.timestamps
    end
  end
end
