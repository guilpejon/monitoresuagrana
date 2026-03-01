require "test_helper"

class BankAccounts::FetchCdiRateJobTest < ActiveSupport::TestCase
  test "perform calls CdiRate.fetch_from_bcb!" do
    called = false
    original = CdiRate.method(:fetch_from_bcb!)
    CdiRate.define_singleton_method(:fetch_from_bcb!) { called = true }
    BankAccounts::FetchCdiRateJob.new.perform
    assert called
  ensure
    CdiRate.define_singleton_method(:fetch_from_bcb!, &original)
  end

  test "perform rescues StandardError without re-raising" do
    original = CdiRate.method(:fetch_from_bcb!)
    CdiRate.define_singleton_method(:fetch_from_bcb!) { raise StandardError, "API down" }
    assert_nothing_raised { BankAccounts::FetchCdiRateJob.new.perform }
  ensure
    CdiRate.define_singleton_method(:fetch_from_bcb!, &original)
  end
end
