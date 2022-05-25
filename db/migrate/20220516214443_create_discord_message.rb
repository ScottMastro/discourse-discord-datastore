# frozen_string_literal: true

class CreateDiscordMessage < ActiveRecord::Migration[6.0]
  def change
    create_table :discord_messages do |t|
      t.bigint :author_id
      t.bigint :channel_id
      t.text :content
      t.datetime :date
      
      t.timestamps
    end

    add_index :discord_messages, :author_id
    add_index :discord_messages, :channel_id   
  end
end
