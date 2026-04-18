# frozen_string_literal: true

module DiscordDatastore
  module DiscordIdResolvable
    extend ActiveSupport::Concern

    # Returns the Discord snowflake id the current request is authorized to
    # query, or -1 when the caller asked for someone else's data without
    # staff permission, or nil when no identifier was supplied.
    def resolve_discord_id
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
  end
end
