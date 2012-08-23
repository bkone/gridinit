class AddStoppedToNodes < ActiveRecord::Migration
  def change
    add_column :nodes, :stopped, :timestamp
  end
end
