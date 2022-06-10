module DiscordDatastore
  class DiscordUsersController < ApplicationController

    requires_login

    def index
      Rails.logger.info 'Called DiscordUsersController#index'

      discord_id = nil
      discord_account = UserAssociatedAccount.find_by(provider_name: "discord", user_id: current_user.id)
      unless discord_account.nil? then
        discord_id = discord_account.user_id
      end

      if current_user.staff? || ! discord_account.nil?

        users = DiscordDatastore::DiscordUser.order(created_at: :desc)
        if params[:user_id]
          user_id=params[:user_id]
          discord_account = UserAssociatedAccount.find_by(provider_name: "discord", user_id: user_id)

          if discord_account.nil?
            users = []
          else
            discord_id = discord_account.user_id
            users = users.where(id: discord_id)
          end
        end

        users = users.map { |u| u.as_json.merge({
          #avoid javascript rounding issues
          :id => u.id.to_s
        })}  

        render json: { discord_users: users }
      else
        render json: { discord_users: [] }
      end
    end
  end
end