class AddPrivacyFlagToRuns < ActiveRecord::Migration
  def change
    add_column :runs, :privacy_flag, :integer

  end
end
