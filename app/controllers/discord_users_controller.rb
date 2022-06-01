module DiscordDatastore
    class DiscordUsersController < ApplicationController
    
      requires_login
  
      def index
        Rails.logger.info 'Called DiscordUsersController#index'
        
        users = DiscordDatastore::DiscordChannel.order(created_at: :desc)
        render json: { discord_users: users }
        end

      def create
        Rails.logger.info 'Called DiscordUsersController#create'
  
        user = {
          'id' => params[:user_id],
          'name' => "fake-channel",
          'voice' => false,
          'permissions' => [],
        }
  
        user = DiscordDatastore::DiscordUser.create(user)
        render json: success_json
      end

    end
  end