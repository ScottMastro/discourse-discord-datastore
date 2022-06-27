# frozen_string_literal: true

class AddIndexToDiscordMessage < ActiveRecord::Migration[6.0]
  def change
    add_index :discord_messages, [:date, :discord_channel_id, :discord_user_id], name: 'date_channel_user_index'
  end
end