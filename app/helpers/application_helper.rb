module ApplicationHelper
  include Pagy::Frontend
  include IconHelper

  def format_brl(amount)
    number = amount.to_f
    "R$ #{format('%.2f', number).gsub('.', ',').gsub(/(\d)(?=(\d{3})+,)/, '\1.')}"
  end

  def pnl_color(value)
    value.to_f >= 0 ? "#00D4AA" : "#FF6B6B"
  end

  def expense_type_badge(type)
    color = type == "fixed" ? "#6C63FF" : "#F7B731"
    label = type.capitalize
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
    content_tag(:span, type.capitalize, class: "px-2 py-0.5 rounded text-xs font-medium", style: "background-color: #{color}22; color: #{color};")
  end
end
