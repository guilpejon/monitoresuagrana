class AddBankAccountToExpenses < ActiveRecord::Migration[8.1]
  def change
    add_reference :expenses, :bank_account, null: true, foreign_key: true
  end
end
