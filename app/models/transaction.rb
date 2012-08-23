class Transaction < ActiveRecord::Base
  belongs_to :users
  belongs_to :nodes
  attr_accessible :amount, :card_token, :hours, :instance_id, :instance_type, :node_id, :purchase_id, :rate, :success, :user_id
end
