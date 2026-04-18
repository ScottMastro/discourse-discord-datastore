# frozen_string_literal: true

module DiscordDatastore
  class DiscordMessage < ActiveRecord::Base
    self.table_name = "discord_messages"
    belongs_to :discord_channel, class_name: "DiscordDatastore::DiscordChannel"
    belongs_to :discord_user, class_name: "DiscordDatastore::DiscordUser"
  end
end
