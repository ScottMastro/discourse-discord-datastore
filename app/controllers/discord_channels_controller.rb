module DiscordDatastore
    class DiscordChannelsController < ApplicationController
    
      requires_login
  
      def index
        page = params[:page].to_i || 2
        Rails.logger.info 'Called DiscordChannelsController#index'
        
        channels = DiscordDatastore::DiscordChannel.order(created_at: :desc)
        render json: { discord_channels: channels }
        end

      def create
        Rails.logger.info 'Called DiscordChannelsController#create'
  
        channel = {
          'id' => params[:channel_id],
          'name' => "fake-channel",
          'voice' => false,
          'permissions' => [],
        }
  
        channel = DiscordDatastore::DiscordChannel.create(channel)
        render json: success_json
      end

    end
  end