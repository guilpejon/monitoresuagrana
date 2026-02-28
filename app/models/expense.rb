class Expense < ApplicationRecord
  belongs_to :user
  belongs_to :category
  belongs_to :credit_card, optional: true

  TYPES = %w[fixed variable].freeze

  validates :description, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :date, presence: true
  validates :expense_type, inclusion: { in: TYPES }
  validates :recurrence_day, numericality: { in: 1..28 }, allow_nil: true

  scope :for_month, ->(date) { where(date: date.beginning_of_month..date.end_of_month) }
  scope :ordered, -> { order(date: :desc) }
  scope :fixed, -> { where(expense_type: "fixed") }
  scope :variable, -> { where(expense_type: "variable") }
  scope :recurring, -> { where(recurring: true) }
end
