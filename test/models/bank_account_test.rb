require "test_helper"

class BankAccountTest < ActiveSupport::TestCase
  test "is valid with valid attributes" do
    account = build(:bank_account)
    assert account.valid?
  end

  test "requires name" do
    account = build(:bank_account, name: nil)
    assert_not account.valid?
    assert_includes account.errors[:name], "can't be blank"
  end

  test "validates account_type inclusion" do
    account = build(:bank_account, account_type: "invalid")
    assert_not account.valid?
  end

  test "accepts all valid account types" do
    %w[checking savings other].each do |type|
      account = build(:bank_account, account_type: type)
      assert account.valid?, "Expected #{type} to be valid"
    end
  end

  test "requires balance >= 0" do
    account = build(:bank_account, balance: -1)
    assert_not account.valid?

    account2 = build(:bank_account, balance: 0)
    assert account2.valid?
  end

  test "validates rate_type inclusion" do
    account = build(:bank_account, rate_type: "invalid")
    assert_not account.valid?
  end

  test "accepts all valid rate types" do
    %w[fixed cdi_percentage].each do |type|
      account = build(:bank_account, rate_type: type)
      assert account.valid?, "Expected #{type} to be valid"
    end
  end

  test "validates cdi_multiplier > 0 when cdi_percentage" do
    account = build(:bank_account, :cdi, cdi_multiplier: 0)
    assert_not account.valid?
    assert_includes account.errors[:cdi_multiplier], "must be greater than 0"
  end

  test "does not validate cdi_multiplier when fixed rate" do
    account = build(:bank_account, rate_type: "fixed", cdi_multiplier: 0)
    assert account.valid?
  end

  test "effective_rate returns interest_rate for fixed accounts" do
    account = build(:bank_account, rate_type: "fixed", interest_rate: 8.5)
    assert_equal 8.5, account.effective_rate
  end

  test "effective_rate returns CDI-based rate for cdi_percentage accounts" do
    original = CdiRate.method(:current)
    CdiRate.define_singleton_method(:current) { 10.0 }
    account = build(:bank_account, :cdi, cdi_multiplier: 120.0)
    assert_in_delta 12.0, account.effective_rate, 0.0001
  ensure
    CdiRate.define_singleton_method(:current, &original)
  end

  test "effective_rate returns 0 when CDI cache is empty" do
    # NullStore returns nil so CdiRate.current is nil — no stubbing needed
    account = build(:bank_account, :cdi, cdi_multiplier: 120.0)
    assert_equal 0, account.effective_rate
  end

  test "monthly_interest uses effective_rate" do
    account = build(:bank_account, rate_type: "fixed", balance: 12000.0, interest_rate: 12.0)
    assert_in_delta 120.0, account.monthly_interest, 0.01
  end

  test "yearly_interest uses effective_rate" do
    account = build(:bank_account, rate_type: "fixed", balance: 10000.0, interest_rate: 10.0)
    assert_in_delta 1000.0, account.yearly_interest, 0.01
  end

  test "monthly_interest for CDI account uses cached CDI rate" do
    original = CdiRate.method(:current)
    CdiRate.define_singleton_method(:current) { 12.0 }
    account = build(:bank_account, :cdi, balance: 12000.0, cdi_multiplier: 100.0)
    assert_in_delta 120.0, account.monthly_interest, 0.01
  ensure
    CdiRate.define_singleton_method(:current, &original)
  end
end
