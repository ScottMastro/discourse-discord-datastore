module DiscordDatastore
    class DiscordChannelsController < ApplicationController
    
      requires_login
  
      def index
        Rails.logger.info 'Called DiscordChannelsController#index'
        
        chs = DiscordDatastore::DiscordChannel.order(created_at: :desc)
        channels = chs.map { |ch| ch.as_json.merge(:length => DiscordDatastore::DiscordMessage.where(channel_id: ch.id).length) }
        
        render json: { discord_channels: channels} 
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