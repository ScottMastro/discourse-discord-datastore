module DiscordDatastore
    class DiscordUsersController < ApplicationController
    
      requires_login
  
      def index
        Rails.logger.info 'Called DiscordUsersController#index'
        
        users = DiscordDatastore::DiscordUser.order(created_at: :desc)
        render json: { discord_users: users }
        end

    end
  end