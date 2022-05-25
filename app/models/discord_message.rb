# frozen_string_literal: true

module DiscordDatastore
  class DiscordMessage < ActiveRecord::Base
    self.table_name = 'discord_messages'

  end
end
