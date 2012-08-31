class RemoveHoursFromTransactions < ActiveRecord::Migration
  def up
    remove_column :transactions, :hours
  end

  def down
    add_column :transactions, :hours, :integer
  end
end
