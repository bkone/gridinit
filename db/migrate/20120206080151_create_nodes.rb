class CreateNodes < ActiveRecord::Migration
  def change
    create_table :nodes do |t|
      t.string   :host
      t.string   :role, :default => 'standalone'
      t.string   :master
      t.timestamps
    end
  end
end
