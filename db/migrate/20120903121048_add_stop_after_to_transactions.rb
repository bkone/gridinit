class AddStopAfterToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :stop_after, :int
  end
end
