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
