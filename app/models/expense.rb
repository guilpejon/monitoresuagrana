class Expense < ApplicationRecord
  belongs_to :user
  belongs_to :category
  belongs_to :credit_card, optional: true
  belongs_to :payee, optional: true

  TYPES = %w[fixed variable].freeze
  PAYMENT_METHODS = %w[cash pix boleto credit_card debito_automatico].freeze
  PAYMENT_STATUSES = %w[pending scheduled paid].freeze

  validates :description, length: { maximum: 255 }, allow_blank: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :date, presence: true
  validates :expense_type, inclusion: { in: TYPES }
  validates :recurrence_day, numericality: { in: 1..31 }, allow_nil: true
  validate :recurring_only_allowed_for_fixed
  validate :installment_cannot_be_recurring
  validates :payment_method, inclusion: { in: PAYMENT_METHODS }
  validates :total_installments, numericality: { in: 1..60 }
  validates :installment_number, numericality: { in: 1..60 }
  validates :payment_status, inclusion: { in: PAYMENT_STATUSES }, allow_nil: true

  before_validation :clear_credit_card_unless_credit_card_method
  before_create :set_default_payment_status

  def installment?
    total_installments > 1
  end

  def installment_label
    "#{installment_number}/#{total_installments}"
  end

  def recurring_credit_card?
    recurring? && payment_method == "credit_card"
  end

  def scheduled_payment?
    payment_method == "debito_automatico" ||
      (recurring? && payment_method.in?(%w[credit_card pix])) ||
      (installment? && payment_method == "pix")
  end

  def next_payment_status
    if scheduled_payment?
      payment_status == "scheduled" ? "paid" : "scheduled"
    else
      current_index = PAYMENT_STATUSES.index(payment_status) || 0
      PAYMENT_STATUSES[(current_index + 1) % PAYMENT_STATUSES.length]
    end
  end

  scope :for_month, ->(date) { where(date: date.beginning_of_month..date.end_of_month) }
  scope :ordered, -> { order(date: :asc) }
  scope :fixed, -> { where(expense_type: "fixed") }
  scope :variable, -> { where(expense_type: "variable") }
  scope :recurring, -> { where(recurring: true) }

  private

  def recurring_only_allowed_for_fixed
    errors.add(:recurring, :invalid) if recurring? && expense_type == "variable"
  end

  def installment_cannot_be_recurring
    errors.add(:recurring, :invalid) if recurring? && installment?
  end

  def clear_credit_card_unless_credit_card_method
    self.credit_card_id = nil unless payment_method == "credit_card"
  end

  def set_default_payment_status
    return if payment_status.present?
    if payment_method == "boleto"
      self.payment_status = "pending"
    elsif scheduled_payment?
      self.payment_status = "scheduled"
    end
  end
end
