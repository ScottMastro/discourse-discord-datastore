# frozen_string_literal: true

class CreateDiscordMessage < ActiveRecord::Migration[6.0]
  def change
    create_table :discord_messages do |t|
      #t.bigint :message_id
      #t.bigint :user_id
      #t.bigint :channel_id
      t.text :content
      #t.datetime :date
      
      t.timestamps
      #add_index :user_id
      #add_index :channel_id    
    end
  end
end
