class CreditCard < ApplicationRecord
  belongs_to :user
  has_many :expenses, dependent: :nullify

  before_destroy :clear_user_default

  BRANDS = %w[visa mastercard amex elo hipercard other].freeze

  validates :name, presence: true
  validates :billing_day, numericality: { in: 1..28 }
  validates :due_day, numericality: { in: 1..28 }

  def billing_period(reference_date = Date.current)
    period_end = if reference_date.day < billing_day
      reference_date.change(day: billing_day)
    else
      (reference_date + 1.month).change(day: billing_day)
    end
    [ period_end - 1.month + 1.day, period_end ]
  end

  def current_bill(reference_date = Date.current)
    period_start, period_end = billing_period(reference_date)
    if expenses.loaded?
      expenses.select { |e| e.date.between?(period_start, period_end) }.sum(&:amount)
    else
      expenses.where(date: period_start..period_end).sum(:amount)
    end
  end

  def previous_billing_period(reference_date = Date.current)
    period_start, = billing_period(reference_date)
    prev_end   = period_start - 1.day
    prev_start = prev_end - 1.month + 1.day
    [ prev_start, prev_end ]
  end

  def previous_bill(reference_date = Date.current)
    prev_start, prev_end = previous_billing_period(reference_date)
    if expenses.loaded?
      expenses.select { |e| e.date.between?(prev_start, prev_end) }.sum(&:amount)
    else
      expenses.where(date: prev_start..prev_end).sum(:amount)
    end
  end

  def billing_periods_history(count = 12)
    periods = []
    period_end = billing_period(Date.current).first - 1.day
    count.times do
      period_start = period_end - 1.month + 1.day
      periods << [ period_start, period_end ]
      period_end = period_start - 1.day
    end
    periods
  end

  def billing_periods_upcoming(count = 6)
    periods = []
    _, current_end = billing_period(Date.current)
    period_start = current_end + 1.day
    count.times do
      period_end = period_start + 1.month - 1.day
      periods << [ period_start, period_end ]
      period_start = period_end + 1.day
    end
    periods
  end

  def usage_percentage(reference_date = Date.current)
    return 0 unless limit.positive?
    [ (current_bill(reference_date) / limit * 100).round, 100 ].min
  end

  def due_date(reference_date = Date.current)
    _, period_end = billing_period(reference_date)
    due_day > billing_day ? period_end.change(day: due_day) : (period_end + 1.month).change(day: due_day)
  end

  def days_until_close(reference_date = Date.current)
    _, period_end = billing_period(reference_date)
    (period_end - reference_date).to_i
  end

  def color_hex
    color.presence || "#6C63FF"
  end

  private

  def clear_user_default
    user.update_column(:default_credit_card_id, nil) if user.default_credit_card_id == id
  end
end
