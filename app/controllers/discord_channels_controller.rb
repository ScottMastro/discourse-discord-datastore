module DiscordDatastore
  class DiscordChannelsController < ApplicationController
  
    requires_login
    
    def get_discord_id(params)
      
      if params[:discord_id]
        if current_user.staff?
          return params[:discord_id].to_i
        end

        discord_account = UserAssociatedAccount.find_by(provider_name: "discord", user_id: current_user.id)
        if discord_account.nil?
          return -1
        end
        if discord_account.provider_uid.to_s == params[:discord_id]
          return params[:discord_id].to_i
        end

        return -1
      end

      if params[:user_id]
        if params[:user_id] == "me"
          params[:user_id] = current_user.id

        elsif ! current_user.staff? && current_user.id != params[:user_id].to_i
          return -1
        end

        discord_account = UserAssociatedAccount.find_by(provider_name: "discord", user_id: params[:user_id].to_i)
        if discord_account.nil?
          return -1
        end
          return discord_account.provider_uid.to_i
      end
    end

    def channels

      discord_id = get_discord_id params
      
      channels = DiscordDatastore::DiscordChannel.order(:position )

      if discord_id.nil? 
        channels = channels.map { |ch| ch.as_json.merge({
          :total => DiscordDatastore::DiscordMessage.where(discord_channel_id: ch.id).length,
          :id => ch.id.to_s
        })}
      else
        channels = channels.map { |ch| ch.as_json.merge({
          :total => DiscordDatastore::DiscordMessage.where(discord_user_id: discord_id, discord_channel_id: ch.id).length,
          :id => ch.id.to_s
        })}
      end

      filtered_channels=[]
      channels.each do |channel|
        filtered_channels.push(channel) if channel[:total] > 0
      end
      
      if current_user.staff?
        render json: { discord_channels: channels}
      else
        render json: { discord_channels: filtered_channels}
      end

    end
  end
end