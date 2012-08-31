class AddRegionToNodes < ActiveRecord::Migration
  def change
    add_column :nodes, :region, :string
  end
end
