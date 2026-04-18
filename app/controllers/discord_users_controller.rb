# frozen_string_literal: true
module DiscordDatastore
  class DiscordUsersController < ApplicationController
    requires_login

    def get_discord_id(params)
      if params[:discord_id]
        return params[:discord_id].to_i if current_user.staff?

        discord_account =
          UserAssociatedAccount.find_by(provider_name: "discord", user_id: current_user.id)
        return -1 if discord_account.nil?
        return params[:discord_id].to_i if discord_account.provider_uid.to_s == params[:discord_id]

        return -1
      end

      if params[:user_id]
        if params[:user_id] == "me"
          params[:user_id] = current_user.id
        elsif !current_user.staff? && current_user.id != params[:user_id].to_i
          return -1
        end

        discord_account =
          UserAssociatedAccount.find_by(provider_name: "discord", user_id: params[:user_id].to_i)
        return -1 if discord_account.nil?
        discord_account.provider_uid.to_i
      end
    end

    def users
      discord_id = get_discord_id params

      users = DiscordDatastore::DiscordUser.order(created_at: :desc)
      users = users.where(id: discord_id) if !discord_id.nil?

      #avoid javascript rounding
      users = users.map { |u| u.as_json(only: u.attribute_names).merge({ id: u.id.to_s }) }

      render json: { discord_users: users }
    end
  end
end
