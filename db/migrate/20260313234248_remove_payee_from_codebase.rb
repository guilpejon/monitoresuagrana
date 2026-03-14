class RemovePayeeFromCodebase < ActiveRecord::Migration[8.1]
  def change
    remove_reference :expenses, :payee, foreign_key: true
    drop_table :payees
  end
end
