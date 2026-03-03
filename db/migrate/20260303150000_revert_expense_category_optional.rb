class RevertExpenseCategoryOptional < ActiveRecord::Migration[8.1]
  def change
    change_column_null :expenses, :category_id, false
  end
end
