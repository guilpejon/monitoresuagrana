class Expense < ApplicationRecord
  belongs_to :user
  belongs_to :category
  belongs_to :credit_card, optional: true
  belongs_to :bank_account, optional: true
  belongs_to :payee, optional: true

  TYPES = %w[fixed variable].freeze
  PAYMENT_METHODS = %w[cash pix boleto credit_card debito_automatico].freeze
  BANK_DEBIT_METHODS = %w[pix boleto debito_automatico].freeze
  PAYMENT_STATUSES = %w[pending scheduled paid].freeze

  validates :description, length: { maximum: 255 }, allow_blank: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :date, presence: true
  validates :expense_type, inclusion: { in: TYPES }
  validates :recurrence_day, numericality: { in: 1..31 }, allow_nil: true
  validate :recurring_only_allowed_for_fixed
  validate :installment_cannot_be_recurring
  validate :installments_only_allowed_for_variable
  validate :variable_expense_cannot_be_future_dated
  validates :payment_method, inclusion: { in: PAYMENT_METHODS }
  validates :total_installments, numericality: { in: 1..60 }
  validates :installment_number, numericality: { in: 1..60 }
  validates :payment_status, inclusion: { in: PAYMENT_STATUSES }, allow_nil: true

  before_validation :clear_credit_card_unless_credit_card_method
  before_validation :clear_bank_account_unless_bank_debit_method
  before_create :set_default_payment_status

  after_create :sync_bank_account_on_create
  after_update :sync_bank_account_balance
  before_destroy :restore_bank_account_if_paid

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
      (recurring? && payment_method.in?(%w[credit_card pix]))
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

  def installments_only_allowed_for_variable
    errors.add(:total_installments, :fixed_not_allowed) if installment? && expense_type == "fixed"
  end

  def clear_credit_card_unless_credit_card_method
    self.credit_card_id = nil unless payment_method == "credit_card"
  end

  def clear_bank_account_unless_bank_debit_method
    self.bank_account_id = nil unless payment_method.in?(BANK_DEBIT_METHODS)
  end

  def sync_bank_account_balance
    return unless bank_account.present? && saved_change_to_payment_status?
    was, now = saved_change_to_payment_status
    if now == "paid" && was != "paid"
      bank_account.decrement!(:balance, amount)
    elsif was == "paid" && now != "paid"
      bank_account.increment!(:balance, amount)
    end
  end

  def restore_bank_account_if_paid
    return unless bank_account.present? && payment_status == "paid"
    bank_account.increment!(:balance, amount)
  end

  def set_default_payment_status
    return if payment_status.present?
    if scheduled_payment?
      self.payment_status = "scheduled"
    elsif expense_type == "variable" && !installment?
      self.payment_status = "paid"
    elsif payment_method.in?(%w[boleto pix])
      self.payment_status = "pending"
    end
  end

  def variable_expense_cannot_be_future_dated
    return unless expense_type == "variable"
    return if installment?
    errors.add(:date, :variable_future) if date.present? && date > Date.current
  end

  def sync_bank_account_on_create
    return unless bank_account.present? && payment_status == "paid"
    bank_account.decrement!(:balance, amount)
  end
end
