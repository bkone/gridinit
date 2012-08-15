class CreateRuns < ActiveRecord::Migration
  def change
    create_table :runs do |t|
      t.text :params
      t.timestamps
    end
  end
end
