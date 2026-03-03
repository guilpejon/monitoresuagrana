module Incomes
  class GenerateRecurringJob < ApplicationJob
    queue_as :default

    def perform(template_id: nil)
      today = Date.current
      templates = template_id ? Income.where(id: template_id, recurring: true) : Income.where(recurring: true)

      templates.each do |template|
        12.times do |i|
          target = today >> i
          next if already_generated?(template, target)

          day = [ template.recurrence_day || 1, target.end_of_month.day ].min
          template.user.incomes.create!(
            description: template.description,
            amount: template.amount,
            date: Date.new(target.year, target.month, day),
            income_type: template.income_type,
            recurring: false,
            recurring_source_id: template.id
          )
        end
      end
    rescue StandardError => e
      Rails.logger.error "Incomes::GenerateRecurringJob error: #{e.message}"
    end

    private

    def already_generated?(template, date)
      return true if template.date.beginning_of_month == date.beginning_of_month

      Income.where(recurring_source_id: template.id)
        .where(date: date.beginning_of_month..date.end_of_month)
        .exists?
    end
  end
end
