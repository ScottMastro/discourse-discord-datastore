# frozen_string_literal: true

module DiscordDatastore
  class DiscordChannel < ActiveRecord::Base
    self.table_name = 'discord_channels'
    has_many :discord_messages
  end
end
