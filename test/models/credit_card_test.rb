require "test_helper"

class CreditCardTest < ActiveSupport::TestCase
  test "is valid with valid attributes" do
    card = build(:credit_card)
    assert card.valid?
  end

  test "requires name" do
    card = build(:credit_card, name: nil)
    assert_not card.valid?
    assert card.errors[:name].any?
  end

  test "validates billing_day is between 1 and 28" do
    card = build(:credit_card, billing_day: 0)
    assert_not card.valid?

    card2 = build(:credit_card, billing_day: 29)
    assert_not card2.valid?

    card3 = build(:credit_card, billing_day: 15)
    assert card3.valid?
  end

  test "validates due_day is between 1 and 28" do
    card = build(:credit_card, due_day: 0)
    assert_not card.valid?

    card2 = build(:credit_card, due_day: 29)
    assert_not card2.valid?

    card3 = build(:credit_card, due_day: 15)
    assert card3.valid?
  end

  test "current_bill sums expenses in the billing period" do
    user = create(:user)
    category = user.categories.first
    card = create(:credit_card, user: user, billing_day: 10)

    # Use a reference_date where billing_day hasn't passed yet (day 5 < billing_day 10)
    reference_date = Date.current.change(day: 5)
    period_end = reference_date.change(day: card.billing_day)
    period_start = period_end - 1.month + 1.day

    in_period = create(:expense, user: user, category: category, credit_card: card,
                       date: period_start + 3.days, amount: 200.00)
    out_of_period = create(:expense, user: user, category: category, credit_card: card,
                           date: period_start - 5.days, amount: 100.00)

    bill = card.current_bill(reference_date)
    assert_equal 200.00, bill.to_f
  end

  test "current_bill uses next billing_day when billing_day has already passed" do
    # Travel to the last day of the month so the billing period's expense dates (mid-month) are in the past
    travel_to Date.current.end_of_month do
      user = create(:user)
      category = user.categories.first
      card = create(:credit_card, user: user, billing_day: 10)

      # Use a reference_date where billing_day has already passed (day 20 > billing_day 10)
      reference_date = Date.current.change(day: 20)
      period_end = (reference_date + 1.month).change(day: card.billing_day)
      period_start = period_end - 1.month + 1.day

      in_period = create(:expense, user: user, category: category, credit_card: card,
                         date: period_start + 3.days, amount: 300.00)
      old_period = create(:expense, user: user, category: category, credit_card: card,
                          date: period_start - 5.days, amount: 100.00)

      bill = card.current_bill(reference_date)
      assert_equal 300.00, bill.to_f
    end
  end

  test "current_bill returns 0 when no expenses" do
    card = create(:credit_card)
    assert_equal 0, card.current_bill.to_f
  end

  test "previous_billing_period returns the month before the current billing period" do
    card = build(:credit_card, billing_day: 10)
    reference_date = Date.new(2024, 3, 5) # day < billing_day, so period_end = Mar 10

    prev_start, prev_end = card.previous_billing_period(reference_date)

    assert_equal Date.new(2024, 1, 11), prev_start
    assert_equal Date.new(2024, 2, 10), prev_end
  end

  test "previous_billing_period works when billing_day has already passed" do
    card = build(:credit_card, billing_day: 10)
    reference_date = Date.new(2024, 3, 20) # day > billing_day, so period_end = Apr 10

    prev_start, prev_end = card.previous_billing_period(reference_date)

    assert_equal Date.new(2024, 2, 11), prev_start
    assert_equal Date.new(2024, 3, 10), prev_end
  end

  test "previous_bill sums expenses in the previous billing period" do
    user = create(:user)
    category = user.categories.first
    card = create(:credit_card, user: user, billing_day: 10)

    reference_date = Date.new(2024, 3, 5)
    prev_start, prev_end = card.previous_billing_period(reference_date)

    create(:expense, user: user, category: category, credit_card: card,
           date: prev_start + 2.days, amount: 150.00)
    create(:expense, user: user, category: category, credit_card: card,
           date: prev_start - 1.day, amount: 999.00) # outside previous period

    assert_equal 150.00, card.previous_bill(reference_date).to_f
  end

  test "usage_percentage returns correct percentage" do
    user = create(:user)
    category = user.categories.first
    card = create(:credit_card, user: user, billing_day: 1, limit: 1000)

    reference_date = Date.new(2024, 3, 15)
    period_start, period_end = card.billing_period(reference_date)
    create(:expense, user: user, category: category, credit_card: card,
           date: period_start + 1.day, amount: 250.00)

    assert_equal 25, card.usage_percentage(reference_date)
  end

  test "usage_percentage caps at 100 when over limit" do
    user = create(:user)
    category = user.categories.first
    card = create(:credit_card, user: user, billing_day: 1, limit: 100)

    reference_date = Date.new(2024, 3, 15)
    period_start, = card.billing_period(reference_date)
    create(:expense, user: user, category: category, credit_card: card,
           date: period_start + 1.day, amount: 500.00)

    assert_equal 100, card.usage_percentage(reference_date)
  end

  test "usage_percentage returns 0 when limit is zero" do
    card = build(:credit_card, limit: 0)
    assert_equal 0, card.usage_percentage
  end

  test "color_hex returns color when present" do
    card = build(:credit_card, color: "#FF0000")
    assert_equal "#FF0000", card.color_hex
  end

  test "color_hex returns default color when blank" do
    card = build(:credit_card, color: nil)
    assert_equal "#6C63FF", card.color_hex

    card2 = build(:credit_card, color: "")
    assert_equal "#6C63FF", card2.color_hex
  end
end
