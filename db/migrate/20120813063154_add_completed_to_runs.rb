class AddCompletedToRuns < ActiveRecord::Migration
  def change
    add_column :runs, :completed, :timestamp
  end
end
