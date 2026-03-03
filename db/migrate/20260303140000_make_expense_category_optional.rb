class MakeExpenseCategoryOptional < ActiveRecord::Migration[8.1]
  def change
    change_column_null :expenses, :category_id, true
  end
end
