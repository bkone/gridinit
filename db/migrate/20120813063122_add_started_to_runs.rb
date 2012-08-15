class AddStartedToRuns < ActiveRecord::Migration
  def change
    add_column :runs, :started, :timestamp
  end
end
