class AddNotesToRuns < ActiveRecord::Migration
  def change
    add_column :runs, :notes, :string

  end
end
