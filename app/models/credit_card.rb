class CreditCard < ApplicationRecord
  belongs_to :user
  has_many :expenses, dependent: :nullify

  before_destroy :clear_user_default

  BRANDS = %w[visa mastercard amex elo hipercard other].freeze

  validates :name, presence: true
  validates :billing_day, numericality: { in: 1..28 }
  validates :due_day, numericality: { in: 1..28 }

  def current_bill(reference_date = Date.current)
    # Bill covers from last billing_day+1 to current billing_day
    period_start = reference_date.change(day: billing_day) - 1.month + 1.day
    period_end = reference_date.change(day: billing_day)

    if expenses.loaded?
      expenses.select { |e| e.date.between?(period_start, period_end) }.sum(&:amount)
    else
      expenses.where(date: period_start..period_end).sum(:amount)
    end
  end

  def color_hex
    color.presence || "#6C63FF"
  end

  private

  def clear_user_default
    user.update_column(:default_credit_card_id, nil) if user.default_credit_card_id == id
  end
end
