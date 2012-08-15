class AddThreadsToRuns < ActiveRecord::Migration
  def change
    add_column :runs, :threads, :integer

  end
end
