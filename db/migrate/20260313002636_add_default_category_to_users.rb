class AddDefaultCategoryToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :default_category_id, :integer
    add_index :users, :default_category_id
    add_foreign_key :users, :categories, column: :default_category_id
  end
end
