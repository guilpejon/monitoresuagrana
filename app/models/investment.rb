class Investment < ApplicationRecord
  belongs_to :user

  TYPES = %w[stock crypto fund].freeze

  validates :name, presence: true
  validates :investment_type, inclusion: { in: TYPES }
  validates :quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :average_price, numericality: { greater_than_or_equal_to: 0 }

  def total_invested
    quantity * average_price
  end

  def current_value
    quantity * current_price
  end

  def profit_loss
    current_value - total_invested
  end

  def profit_loss_percent
    return 0 if total_invested.zero?
    (profit_loss / total_invested * 100).round(2)
  end
end
