module DiscordDatastore
    class DiscordChannelsController < ApplicationController
    
      requires_login
  
      def index
        Rails.logger.info 'Called DiscordChannelsController#index'

        user_id = current_user.id

        discord_id = nil
        discord_account = UserAssociatedAccount.find_by(provider_name: "discord", user_id: user_id)
        unless discord_account.nil? then
          discord_id = discord_account.user_id
        end

        unless discord_id.nil? then
          
          channels = DiscordDatastore::DiscordChannel.order(:position )
          
          channels = channels.map { |ch| ch.as_json.merge({
            :length => DiscordDatastore::DiscordMessage.where(discord_user_id: discord_id, discord_channel_id: ch.id).length,
            #avoid javascript rounding issues
            :id => ch.id.to_s
          })}
    
          render json: { discord_channels: channels}
        else
          render json: { discord_channels: []}
        end
      end

      def admin
        Rails.logger.info 'Called DiscordChannelsController#admin'

        if ! current_user.staff?
          render json: { "error": "permission_denied" }
          return
        end

        discord_id = nil
        if params[:discord_id]
          discord_id = params[:discord_id].to_i
        end

        channels = DiscordDatastore::DiscordChannel.order(:position)

        if discord_id.nil? 
          channels = channels.map { |ch| ch.as_json.merge({
            :length => DiscordDatastore::DiscordMessage.where(discord_channel_id: ch.id).length,
            #avoid javascript rounding issues
            :id => ch.id.to_s
          })}
        else
          channels = channels.map { |ch| ch.as_json.merge({
            :length => DiscordDatastore::DiscordMessage.where(discord_user_id: discord_id, discord_channel_id: ch.id).length,
            #avoid javascript rounding issues
            :id => ch.id.to_s
          })}
        end

        render json: { discord_channels: channels}
      end

    end
  end