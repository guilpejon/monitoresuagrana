require "test_helper"

class InstallmentSplitTest < ActiveSupport::TestCase
  test "splits evenly when there is no remainder" do
    assert_equal [ BigDecimal("100"), BigDecimal("100"), BigDecimal("100") ],
                 InstallmentSplit.amounts(300, 3)
  end

  test "puts rounding remainder on last installment" do
    amounts = InstallmentSplit.amounts(1000, 12).map(&:to_f)
    assert_equal 11, amounts.count(83.33)
    assert_in_delta 83.37, amounts.last, 0.001
    assert_in_delta 1000.0, amounts.sum, 0.001
  end

  test "single installment returns total" do
    assert_equal [ BigDecimal("42.50") ], InstallmentSplit.amounts(42.50, 1)
  end
end
