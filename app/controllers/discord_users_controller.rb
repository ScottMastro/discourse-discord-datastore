module DiscordDatastore
    class DiscordUsersController < ApplicationController
    
      requires_login
  
      def index
          render json: { discord_users: "hello" }
      end
    end
  end