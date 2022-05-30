module DiscordDatastore
    class DiscordChannelsController < ApplicationController
    
      requires_login
  
      def index
        page = params[:page].to_i || 2
        Rails.logger.info 'Called DiscordChannelsController#index'
        
        channels = DiscordDatastore::DiscordChannel.order(created_at: :desc)
        nChannels = channels.length

        render json: { discord_channels: "hello" }
      end
    end
  end