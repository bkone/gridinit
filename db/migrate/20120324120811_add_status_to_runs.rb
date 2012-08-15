class AddStatusToRuns < ActiveRecord::Migration
  def change
    add_column :runs, :status, :string

  end
end
