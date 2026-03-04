module ApplicationHelper
  include IconHelper

  def format_currency(amount)
    number = amount.to_f
    case current_user&.currency || "BRL"
    when "USD"
      number_to_currency(number, unit: "$", separator: ".", delimiter: ",", precision: 2)
    when "EUR"
      number_to_currency(number, unit: "€", separator: ",", delimiter: ".", format: "%n %u", precision: 2)
    else # BRL
      number_to_currency(number, unit: "R$", separator: ",", delimiter: ".", format: "%u %n", precision: 2)
    end
  end

  def category_display_name(category)
    I18n.t("category_names.#{category.name}", default: category.name)
  end

  def pnl_color(value)
    value.to_f >= 0 ? "#00D4AA" : "#FF6B6B"
  end

  def expense_type_badge(type)
    color = type == "fixed" ? "#6C63FF" : "#F7B731"
    label = I18n.t("expenses.form.#{type}", default: type.capitalize)
    content_tag(:span, label, class: "px-2 py-0.5 rounded text-xs font-medium", style: "background-color: #{color}22; color: #{color};")
  end

  def income_type_badge(type)
    colors = {
      "salary" => "#00D4AA",
      "freelance" => "#6C63FF",
      "dividend" => "#F7B731",
      "other" => "#8892A4"
    }
    color = colors[type] || "#8892A4"
    label = I18n.t("incomes.form.#{type}", default: type.capitalize)
    content_tag(:span, label, class: "px-2 py-0.5 rounded text-xs font-medium", style: "background-color: #{color}22; color: #{color};")
  end
end
