module Incomes
  class GenerateRecurringJob < ApplicationJob
    queue_as :default

    def perform(template_id: nil)
      templates = template_id ? Income.where(id: template_id, recurring: true, recurring_source_id: nil) : Income.where(recurring: true, recurring_source_id: nil)

      templates.each do |template|
        reference = Income.where(recurring_source_id: template.id).order(date: :desc).first || template

        12.times do |i|
          target = Date.today >> i
          next if already_generated?(template, target)

          day = [ reference.date.day, target.end_of_month.day ].min
          template.user.incomes.create!(
            description: reference.description,
            amount: reference.amount,
            date: Date.new(target.year, target.month, day),
            income_type: reference.income_type,
            recurring: true,
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
