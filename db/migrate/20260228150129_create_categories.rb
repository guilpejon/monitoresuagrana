class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :color, null: false, default: "#6C63FF"
      t.string :icon, default: "💰"

      t.timestamps
    end
  end
end
