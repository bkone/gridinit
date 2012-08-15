class CreateAttachments < ActiveRecord::Migration
  def self.up
    create_table :attachments do |t|
      t.column :filename, :string
      # t.column :data, :binary
    end
    execute 'ALTER TABLE attachments ADD COLUMN data MEDIUMBLOB'
  end

  def self.down
    drop_table :attachments
  end
end
