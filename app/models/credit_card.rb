class CreditCard < ApplicationRecord
  belongs_to :user
  has_many :expenses, dependent: :nullify

  BRANDS = %w[visa mastercard amex elo hipercard other].freeze

  validates :name, presence: true
  validates :billing_day, numericality: { in: 1..28 }
  validates :due_day, numericality: { in: 1..28 }

  def current_bill(reference_date = Date.current)
    # Bill covers from last billing_day+1 to current billing_day
    period_start = reference_date.change(day: billing_day) - 1.month + 1.day
    period_end = reference_date.change(day: billing_day)
    expenses.where(date: period_start..period_end).sum(:amount)
  end

  def color_hex
    color.presence || "#6C63FF"
  end
end
