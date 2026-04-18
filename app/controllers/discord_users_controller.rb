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

      #avoid javascript rounding
      users = users.map { |u| u.as_json(only: u.attribute_names).merge({ id: u.id.to_s }) }

      render json: { discord_users: users }
    end
  end
end
