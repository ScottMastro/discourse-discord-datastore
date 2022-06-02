module DiscordDatastore
    class DiscordUsersController < ApplicationController
    
      requires_login
  
      def index
        Rails.logger.info 'Called DiscordUsersController#index'
        
        users = DiscordDatastore::DiscordUser.order(created_at: :desc)
        render json: { discord_users: users }
        end

      def create
        Rails.logger.info 'Called DiscordUsersController#create'
  
        #https://i.imgur.com/Xz4OOh9.png

        user = {
          'id' => params[:user_id],
          'tag' => params[:tag],
          'nickname' => params[:nickname],
          'avatar' => params[:avatar],
          'roles' => [],
          'verified' => params[:verified],
          'discourse_account_id' => params[:discourse_account_id]
        }
  
        user = DiscordDatastore::DiscordUser.create(user)
        render json: success_json
      end

    end
  end