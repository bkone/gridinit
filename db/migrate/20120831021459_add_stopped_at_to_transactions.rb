class AddStoppedAtToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :stopped_at, :timestamp
  end
end
