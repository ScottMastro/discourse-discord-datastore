# frozen_string_literal: true

class CreateDiscordChannel < ActiveRecord::Migration[6.0]
  def change
    create_table :discord_channels do |t|
      t.string :name
      t.boolean :voice
      t.bigint :permissions, array: true, default: []

      t.timestamps
    end
  end
end
