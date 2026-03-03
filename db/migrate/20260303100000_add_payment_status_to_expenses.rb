class AddPaymentStatusToExpenses < ActiveRecord::Migration[8.1]
  def up
    add_column :expenses, :payment_status, :string

    execute "UPDATE expenses SET payment_status = 'awaiting_boleto' WHERE payment_method = 'boleto'"
    execute "UPDATE expenses SET payment_status = 'pending' WHERE payment_method = 'pix'"
  end

  def down
    remove_column :expenses, :payment_status
  end
end
