module Expenses
  class GenerateRecurringJob < ApplicationJob
    queue_as :default

    def perform(template_id: nil)
      today = Date.current
      templates = template_id ? Expense.where(id: template_id, recurring: true) : Expense.where(recurring: true)

      templates.each do |template|
        12.times do |i|
          target = today >> i
          next if already_generated?(template, target)

          day = [ template.date.day, target.end_of_month.day ].min
          template.user.expenses.create!(
            description: template.description,
            amount: template.amount,
            date: Date.new(target.year, target.month, day),
            expense_type: template.expense_type,
            category_id: template.category_id,
            credit_card_id: template.credit_card_id,
            payee_id: template.payee_id,
            payment_method: template.payment_method,
            total_installments: 1,
            installment_number: 1,
            recurring: false,
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
