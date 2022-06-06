# frozen_string_literal: true

class CreateDiscordUser < ActiveRecord::Migration[6.0]
  def change
    create_table :discord_users do |t|
      t.string :tag
      t.string :nickname
      t.string :avatar
      t.bigint :roles, array: true, default: []
      t.boolean :verified
      t.bigint :discourse_account_id

      t.timestamps
    end
  end
end