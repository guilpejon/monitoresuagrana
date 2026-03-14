module Expenses
  class GenerateRecurringJob < ApplicationJob
    queue_as :default

    def perform(template_id: nil)
      templates = template_id ? Expense.where(id: template_id, recurring: true, recurring_source_id: nil) : Expense.where(recurring: true, recurring_source_id: nil)

      templates.each do |template|
        reference = Expense.where(recurring_source_id: template.id).order(date: :desc).first || template

        12.times do |i|
          target = Date.today >> i
          next if already_generated?(template, target)

          day = [ template.recurrence_day || reference.date.day, target.end_of_month.day ].min
          template.user.expenses.create!(
            description: reference.description,
            amount: reference.amount,
            date: Date.new(target.year, target.month, day),
            expense_type: reference.expense_type,
            category_id: reference.category_id,
            credit_card_id: reference.credit_card_id,
            bank_account_id: reference.bank_account_id,
            payment_method: reference.payment_method,
            total_installments: 1,
            installment_number: 1,
            recurring: true,
            recurring_source_id: template.id
          )
        end
      end
    rescue StandardError => e
      Rails.logger.error "Expenses::GenerateRecurringJob error: #{e.message}"
    end

    private

    def already_generated?(template, date)
      return true if template.date.beginning_of_month == date.beginning_of_month

      Expense.where(recurring_source_id: template.id)
        .where(date: date.beginning_of_month..date.end_of_month)
        .exists?
    end
  end
end
