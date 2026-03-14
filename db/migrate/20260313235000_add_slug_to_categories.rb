class AddSlugToCategories < ActiveRecord::Migration[8.0]
  def up
    add_column :categories, :slug, :string
    add_index :categories, [ :user_id, :slug ], unique: true

    Category.find_each { |c| c.update_columns(slug: c.name.parameterize) }
  end

  def down
    remove_index :categories, [ :user_id, :slug ]
    remove_column :categories, :slug
  end
end
