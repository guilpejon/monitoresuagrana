class ClearPaymentStatusForCashAndCreditCard < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE expenses SET payment_status = NULL WHERE payment_method IN ('cash', 'credit_card')"
  end

  def down
    execute "UPDATE expenses SET payment_status = 'pending' WHERE payment_method IN ('cash', 'credit_card')"
  end
end
