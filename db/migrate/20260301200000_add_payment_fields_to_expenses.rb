class AddPaymentFieldsToExpenses < ActiveRecord::Migration[8.1]
  def change
    add_column :expenses, :payment_method, :string, default: "cash", null: false
    add_column :expenses, :total_installments, :integer, default: 1, null: false
    add_column :expenses, :installment_number, :integer, default: 1, null: false
    add_column :expenses, :installment_group_id, :string

    reversible do |dir|
      dir.up { execute "UPDATE expenses SET payment_method = 'credit_card' WHERE credit_card_id IS NOT NULL" }
    end
  end
end
