module DiscordDatastore
    class DiscordChannelsController < ApplicationController
    
      requires_login
  
      def index
        Rails.logger.info 'Called DiscordChannelsController#index'
        
        user_id = params[:user_id] || nil
        if ! current_user.staff?
          user_id = current_user.id
          #current_user.associated_accounts
        end  

        channels = DiscordDatastore::DiscordChannel.order(created_at: :desc)

        #todo: hide channels based on permissions
        
        if user_id
          channels = channels.map { |ch| ch.as_json.merge(:length => 
            DiscordDatastore::DiscordMessage.where(discord_user_id: user_id, discord_channel_id: ch.id).length) }
        else
          channels = channels.map { |ch| ch.as_json.merge(:length => 
            DiscordDatastore::DiscordMessage.where(discord_channel_id: ch.id).length) }
        end
        
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