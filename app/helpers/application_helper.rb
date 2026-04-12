module ApplicationHelper
  include IconHelper

  def format_currency(amount)
    number = amount.to_f
    formatted = case current_user&.currency || "BRL"
    when "USD"
      number_to_currency(number, unit: "$", separator: ".", delimiter: ",", precision: 2)
    when "EUR"
      number_to_currency(number, unit: "€", separator: ",", delimiter: ".", format: "%n %u", precision: 2)
    else # BRL
      number_to_currency(number, unit: "R$", separator: ",", delimiter: ".", format: "%u %n", precision: 2)
    end
    content_tag(:span, formatted, class: "sensitive-value")
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

  # Background + border for the expenses "Filtrando por cartão" filter strip (not global flash toasts).
  def credit_card_filter_banner_style(hex)
    h = hex.to_s.delete("#")
    unless h.length == 6 && h.match?(/\A[0-9a-fA-F]+\z/)
      return "background-color: rgba(108,99,255,0.12); border: 1px solid rgba(108,99,255,0.3);"
    end
    r, g, b = h.scan(/../).map(&:hex)
    "background-color: rgba(#{r},#{g},#{b},0.15); border: 1px solid rgba(#{r},#{g},#{b},0.35);"
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
