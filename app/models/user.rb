# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :categories, dependent: :destroy
  has_many :incomes, dependent: :destroy
  has_many :expenses, dependent: :destroy
  has_many :credit_cards, dependent: :destroy
  has_many :investments, dependent: :destroy

  after_create :create_default_categories

  def currency_symbol
    currency == "BRL" ? "R$" : "$"
  end

  private

  def create_default_categories
    default_categories = [
      { name: "Housing",       color: "#6C63FF", icon: "home" },
      { name: "Food",          color: "#00D4AA", icon: "utensils" },
      { name: "Transport",     color: "#F7B731", icon: "car" },
      { name: "Health",        color: "#FF6B6B", icon: "heart-pulse" },
      { name: "Entertainment", color: "#A78BFA", icon: "gamepad-2" },
      { name: "Shopping",      color: "#34D399", icon: "shopping-cart" },
      { name: "Education",     color: "#60A5FA", icon: "book-open" },
      { name: "Utilities",     color: "#FBBF24", icon: "zap" },
      { name: "Travel",        color: "#F472B6", icon: "plane" },
      { name: "Other",         color: "#8892A4", icon: "circle-dollar-sign" }
    ]

    default_categories.each do |cat|
      categories.create!(cat)
    end
  end
end
