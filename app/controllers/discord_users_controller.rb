# frozen_string_literal: true
module DiscordDatastore
  class DiscordUsersController < ApplicationController
    include DiscordIdResolvable

    requires_plugin "discourse-discord-datastore"
    requires_login

    def users
      discord_id = resolve_discord_id

      users = DiscordDatastore::DiscordUser.order(created_at: :desc)
      users = users.where(id: discord_id) if !discord_id.nil?

      render json: {
               discord_users:
                 ActiveModel::ArraySerializer.new(
                   users,
                   each_serializer: DiscordUserSerializer,
                 ).as_json,
             }
    end
  end
end
