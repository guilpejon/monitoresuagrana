class Category < ApplicationRecord
  belongs_to :user
  has_many :expenses, dependent: :nullify

  before_destroy :clear_user_default
  before_validation :generate_slug

  validates :name, presence: true, length: { maximum: 20 }
  validates :color, presence: true
  validates :icon, presence: true
  validates :slug, presence: true, uniqueness: { scope: :user_id }

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = name.parameterize if name.present? && slug.blank?
  end

  def clear_user_default
    user.update_column(:default_category_id, nil) if user.default_category_id == id
  end
end
