class CreateIncomes < ActiveRecord::Migration[8.1]
  def change
    create_table :incomes do |t|
      t.references :user, null: false, foreign_key: true
      t.string :description, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.date :date, null: false
      t.string :income_type, null: false, default: "salary"
      t.boolean :recurring, default: false
      t.integer :recurrence_day

      t.timestamps
    end
  end
end
