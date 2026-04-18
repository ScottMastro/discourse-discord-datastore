# frozen_string_literal: true
module DiscordDatastore
  class DiscordChannelsController < ApplicationController
    include DiscordIdResolvable

    requires_plugin "discourse-discord-datastore"
    requires_login

    def channels
      discord_id = resolve_discord_id

      channels = DiscordDatastore::DiscordChannel.order(:position)

      if discord_id.nil?
        channels =
          channels.map do |ch|
            ch.as_json(only: ch.attribute_names).merge(
              {
                total: DiscordDatastore::DiscordMessage.where(discord_channel_id: ch.id).size,
                id: ch.id.to_s,
              },
            )
          end
      else
        channels =
          channels.map do |ch|
            ch.as_json(only: ch.attribute_names).merge(
              {
                total:
                  DiscordDatastore::DiscordMessage.where(
                    discord_channel_id: ch.id,
                    discord_user_id: discord_id,
                  ).size,
                id: ch.id.to_s,
              },
            )
          end
      end

      filtered_channels = []
      channels.each { |channel| filtered_channels.push(channel) if channel[:total] > 0 }

      if current_user.staff?
        render json: { discord_channels: channels }
      else
        render json: { discord_channels: filtered_channels }
      end
    end
  end
end
