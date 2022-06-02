# frozen_string_literal: true

module DiscordDatastore
  class DiscordUser < ActiveRecord::Base
    self.table_name = 'discord_users'
    has_many :discord_messages
  end
end
