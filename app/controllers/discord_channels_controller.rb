module DiscordDatastore
    class DiscordChannelsController < ApplicationController
    
      requires_login
  
      def index
        Rails.logger.info 'Called DiscordChannelsController#index'

        user_id = current_user.id
        #current_user.associated_accounts
        #todo
        user_id=366068461027459073

        channels = DiscordDatastore::DiscordChannel.order(:position )

        #todo: hide channels based on permissions
        
        channels = channels.map { |ch| ch.as_json.merge(:length => 
          DiscordDatastore::DiscordMessage.where(discord_user_id: user_id, discord_channel_id: ch.id).length) }
        
        render json: { discord_channels: channels}
      end

      def admin
        Rails.logger.info 'Called DiscordChannelsController#admin'

        if ! current_user.staff?
          render json: { "error": "permission_denied" }
          return
        end

        channels = DiscordDatastore::DiscordChannel.order(:position)
        channels = channels.map { |ch| ch.as_json.merge(:length => 
            DiscordDatastore::DiscordMessage.where(discord_channel_id: ch.id).length) }
        
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