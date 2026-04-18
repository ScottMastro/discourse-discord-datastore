# frozen_string_literal: true

module DiscordDatastore
  class DiscordChannelSerializer < ApplicationSerializer
    attributes :id, :name, :voice, :position, :total

    def id
      object.id.to_s
    end

    def total
      scope = DiscordDatastore::DiscordMessage.where(discord_channel_id: object.id)
      scope = scope.where(discord_user_id: @options[:discord_id]) if @options[:discord_id]
      scope.size
    end
  end
end
