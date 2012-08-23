class CreateTransactions < ActiveRecord::Migration
  def change
    create_table :transactions do |t|
      t.integer :user_id
      t.integer :node_id
      t.string :instance_id
      t.string :instance_type
      t.integer :hours
      t.integer :rate
      t.integer :amount
      t.string :card_token
      t.boolean :success
      t.string :purchase_id

      t.timestamps
    end
  end
end
