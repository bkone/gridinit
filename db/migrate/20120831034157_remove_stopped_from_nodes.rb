class RemoveStoppedFromNodes < ActiveRecord::Migration
  def up
    remove_column :nodes, :stopped
  end

  def down
    add_column :nodes, :stopped, :timestamp
  end
end
