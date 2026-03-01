class Expense < ApplicationRecord
  belongs_to :user
  belongs_to :category
  belongs_to :credit_card, optional: true

  TYPES = %w[fixed variable].freeze
  PAYMENT_METHODS = %w[cash pix boleto credit_card].freeze

  validates :description, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :date, presence: true
  validates :expense_type, inclusion: { in: TYPES }
  validates :recurrence_day, numericality: { in: 1..28 }, allow_nil: true
  validates :payment_method, inclusion: { in: PAYMENT_METHODS }
  validates :total_installments, numericality: { in: 1..60 }
  validates :installment_number, numericality: { in: 1..60 }

  def installment?
    total_installments > 1
  end

  def installment_label
    "#{installment_number}/#{total_installments}"
  end

  scope :for_month, ->(date) { where(date: date.beginning_of_month..date.end_of_month) }
  scope :ordered, -> { order(date: :desc) }
  scope :fixed, -> { where(expense_type: "fixed") }
  scope :variable, -> { where(expense_type: "variable") }
  scope :recurring, -> { where(recurring: true) }
end
