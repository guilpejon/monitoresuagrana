class AddDefaultCreditCardToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :default_credit_card_id, :integer
    add_foreign_key :users, :credit_cards, column: :default_credit_card_id
    add_index :users, :default_credit_card_id
  end
end
