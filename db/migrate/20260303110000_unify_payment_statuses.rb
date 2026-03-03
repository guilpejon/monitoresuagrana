class UnifyPaymentStatuses < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE expenses SET payment_status = 'pending' WHERE payment_status = 'awaiting_boleto'"
    execute "UPDATE expenses SET payment_status = 'pending' WHERE payment_method IN ('cash', 'credit_card')"
  end

  def down
    execute "UPDATE expenses SET payment_status = 'awaiting_boleto' WHERE payment_method = 'boleto' AND payment_status = 'pending'"
    execute "UPDATE expenses SET payment_status = NULL WHERE payment_method IN ('cash', 'credit_card')"
  end
end
