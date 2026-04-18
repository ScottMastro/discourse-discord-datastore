# frozen_string_literal: true
module DiscordDatastore
  class DiscordChannelsController < ApplicationController
    include DiscordIdResolvable

    requires_plugin "discourse-discord-datastore"
    requires_login

    def channels
      discord_id = resolve_discord_id

      channels =
        ActiveModel::ArraySerializer.new(
          DiscordDatastore::DiscordChannel.order(:position),
          each_serializer: DiscordChannelSerializer,
          discord_id: discord_id,
        ).as_json

      channels = channels.select { |ch| ch["total"] > 0 } unless current_user.staff?

      render json: { discord_channels: channels }
    end
  end
end
