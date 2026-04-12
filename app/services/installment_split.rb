# frozen_string_literal: true

# Splits a total into N installment amounts with 2-decimal currency rounding.
# First (n-1) installments use (total/n).round(2); the last absorbs the remainder
# so the parts always sum exactly to +total+.
class InstallmentSplit
  def self.amounts(total, count)
    count = count.to_i
    total = BigDecimal(total.to_s)
    return [ total ] if count <= 1

    per = (total / count).round(2)
    last = (total - per * (count - 1)).round(2)
    Array.new(count - 1, per) + [ last ]
  end
end
