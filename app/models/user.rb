# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :timeoutable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]

  def self.from_omniauth(auth)
    # Returning Google user
    user = find_by(provider: auth.provider, uid: auth.uid)
    return user if user

    # Existing email account — connect Google to it
    user = find_by(email: auth.info.email)
    if user
      user.update!(provider: auth.provider, uid: auth.uid)
      return user
    end

    # New user via Google
    create!(
      provider: auth.provider,
      uid: auth.uid,
      email: auth.info.email,
      password: Devise.friendly_token[0, 20],
      name: auth.info.name,
      locale: I18n.locale.to_s,
      currency: I18n.locale.to_s == "pt-BR" ? "BRL" : "USD"
    )
  end

  validates :locale, inclusion: { in: %w[en pt-BR es] }

  has_many :expenses, dependent: :destroy
  has_many :incomes, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :credit_cards, dependent: :destroy
  belongs_to :default_credit_card, class_name: "CreditCard", optional: true
  belongs_to :default_category, class_name: "Category", optional: true
  has_many :investments, dependent: :destroy
  has_many :bank_accounts, dependent: :destroy
has_many :possessions, dependent: :destroy

  after_create :create_default_categories

  def currency_symbol
    case currency
    when "BRL" then "R$"
    when "EUR" then "€"
    else "$"
    end
  end

  private

  def create_default_categories
    # All colours must be members of ColorPalette::COLORS
    default_categories = [
      { name: "Housing",       color: "#6C63FF", icon: "home" },
      { name: "Food",          color: "#00D4AA", icon: "utensils" },
      { name: "Transport",     color: "#F7B731", icon: "car" },
      { name: "Health",        color: "#FF6B6B", icon: "heart-pulse" },
      { name: "Entertainment", color: "#A78BFA", icon: "gamepad-2" },
      { name: "Shopping",      color: "#84CC16", icon: "shopping-cart" },
      { name: "Education",     color: "#60A5FA", icon: "book-open" },
      { name: "Travel",        color: "#F472B6", icon: "plane" },
      { name: "Fitness",       color: "#FB923C", icon: "dumbbell" },
      { name: "Utilities",     color: "#60A5FA", icon: "zap" },
      { name: "Kids",          color: "#00D4AA", icon: "baby" },
      { name: "Other",         color: "#8892A4", icon: "layers" }
    ]

    default_categories.each do |cat|
      categories.create!(cat)
    end
  end
end
