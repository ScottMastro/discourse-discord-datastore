class AddPositionToDiscordChannel < ActiveRecord::Migration[6.1]
  def change
    add_column :discord_channels, :position, :int
  end
end
