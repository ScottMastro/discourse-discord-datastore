# frozen_string_literal: true
module DiscordDatastore
  class DiscordChannelsController < ApplicationController
    requires_login

    def get_discord_id(params)
      if params[:discord_id]
        return params[:discord_id].to_i if current_user.staff?

        discord_account =
          UserAssociatedAccount.find_by(provider_name: "discord", user_id: current_user.id)
        return -1 if discord_account.nil?
        return params[:discord_id].to_i if discord_account.provider_uid.to_s == params[:discord_id]

        return -1
      end

      if params[:user_id]
        if params[:user_id] == "me"
          params[:user_id] = current_user.id
        elsif !current_user.staff? && current_user.id != params[:user_id].to_i
          return -1
        end

        discord_account =
          UserAssociatedAccount.find_by(provider_name: "discord", user_id: params[:user_id].to_i)
        return -1 if discord_account.nil?
        discord_account.provider_uid.to_i
      end
    end

    def channels
      discord_id = get_discord_id params

      channels = DiscordDatastore::DiscordChannel.order(:position)

      if discord_id.nil?
        channels =
          channels.map do |ch|
            ch.as_json(only: ch.attribute_names).merge(
              {
                total: DiscordDatastore::DiscordMessage.where(discord_channel_id: ch.id).size,
                id: ch.id.to_s,
              },
            )
          end
      else
        channels =
          channels.map do |ch|
            ch.as_json(only: ch.attribute_names).merge(
              {
                total:
                  DiscordDatastore::DiscordMessage.where(
                    discord_channel_id: ch.id,
                    discord_user_id: discord_id,
                  ).size,
                id: ch.id.to_s,
              },
            )
          end
      end

      filtered_channels = []
      channels.each { |channel| filtered_channels.push(channel) if channel[:total] > 0 }

      if current_user.staff?
        render json: { discord_channels: channels }
      else
        render json: { discord_channels: filtered_channels }
      end
    end
  end
end
