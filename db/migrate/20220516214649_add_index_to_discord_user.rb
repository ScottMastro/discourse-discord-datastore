# frozen_string_literal: true

class AddIndexToDiscordUser < ActiveRecord::Migration[6.0]
  def change
    add_index :discord_users, :discourse_account_id
  end
end