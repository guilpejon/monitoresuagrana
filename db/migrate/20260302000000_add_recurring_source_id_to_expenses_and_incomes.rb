class AddRecurringSourceIdToExpensesAndIncomes < ActiveRecord::Migration[8.1]
  def change
    add_column :expenses, :recurring_source_id, :bigint
    add_column :incomes, :recurring_source_id, :bigint
  end
end
