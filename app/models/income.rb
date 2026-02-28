class Income < ApplicationRecord
  belongs_to :user

  TYPES = %w[salary freelance dividend other].freeze

  validates :description, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :date, presence: true
  validates :income_type, inclusion: { in: TYPES }
  validates :recurrence_day, numericality: { in: 1..28 }, allow_nil: true

  scope :for_month, ->(date) { where(date: date.beginning_of_month..date.end_of_month) }
  scope :ordered, -> { order(date: :desc) }
end
