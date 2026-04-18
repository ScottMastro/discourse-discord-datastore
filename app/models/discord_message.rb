# frozen_string_literal: true

module DiscordDatastore
  class DiscordMessage < ActiveRecord::Base
    self.table_name = 'discord_messages'
    belongs_to :discord_channel
    belongs_to :discord_user
  end
end
