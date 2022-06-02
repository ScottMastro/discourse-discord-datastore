# frozen_string_literal: true

class CreateDiscordMessage < ActiveRecord::Migration[6.0]
  def change
    create_table :discord_messages do |t|
      t.bigint :discord_user_id
      t.bigint :discord_channel_id
      t.text :content
      t.datetime :date
      
      t.timestamps
    end

    add_index :discord_messages, :discord_user_id
    add_index :discord_messages, :discord_channel_id   
  end
end
