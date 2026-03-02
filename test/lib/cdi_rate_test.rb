require "test_helper"

class CdiRateTest < ActiveSupport::TestCase
  # current
  test "current returns nil when cache is empty" do
    assert_nil CdiRate.current
  end

  test "current returns rate from cached payload" do
    original = Rails.cache.method(:read)
    Rails.cache.define_singleton_method(:read) { |*| { rate: 12.5, date: "01/03/2026" } }
    assert_equal 12.5, CdiRate.current
  ensure
    Rails.cache.define_singleton_method(:read, &original)
  end

  # cached_info
  test "cached_info returns nil when cache is empty" do
    assert_nil CdiRate.cached_info
  end

  test "cached_info returns full payload from cache" do
    payload = { rate: 12.5, date: "01/03/2026", updated_at: Time.current }
    original = Rails.cache.method(:read)
    Rails.cache.define_singleton_method(:read) { |*| payload }
    assert_equal payload, CdiRate.cached_info
  ensure
    Rails.cache.define_singleton_method(:read, &original)
  end

  # fetch_from_bcb!
  test "fetch_from_bcb! computes annual rate and returns it" do
    daily = 0.05
    expected_annual = (((1 + daily / 100.0)**CdiRate::BUSINESS_DAYS_PER_YEAR) - 1) * 100

    fake_response = Object.new
    fake_response.define_singleton_method(:success?) { true }
    fake_response.define_singleton_method(:parsed_response) { [ { "valor" => daily.to_s, "data" => "01/03/2026" } ] }

    original = HTTParty.method(:get)
    HTTParty.define_singleton_method(:get) { |*| fake_response }
    result = CdiRate.fetch_from_bcb!
    assert_in_delta expected_annual.round(6), result, 0.001
  ensure
    HTTParty.define_singleton_method(:get, &original)
  end

  test "fetch_from_bcb! raises when HTTP response indicates failure" do
    fake_response = Object.new
    fake_response.define_singleton_method(:success?) { false }
    fake_response.define_singleton_method(:code) { 500 }

    original = HTTParty.method(:get)
    HTTParty.define_singleton_method(:get) { |*| fake_response }
    assert_raises(RuntimeError) { CdiRate.fetch_from_bcb! }
  ensure
    HTTParty.define_singleton_method(:get, &original)
  end

  test "fetch_from_bcb! raises when API returns empty data" do
    fake_response = Object.new
    fake_response.define_singleton_method(:success?) { true }
    fake_response.define_singleton_method(:parsed_response) { [] }

    original = HTTParty.method(:get)
    HTTParty.define_singleton_method(:get) { |*| fake_response }
    assert_raises(RuntimeError) { CdiRate.fetch_from_bcb! }
  ensure
    HTTParty.define_singleton_method(:get, &original)
  end
end
