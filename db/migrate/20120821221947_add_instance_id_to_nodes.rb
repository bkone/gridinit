class AddInstanceIdToNodes < ActiveRecord::Migration
  def change
    add_column :nodes, :instance_id, :string
  end
end
