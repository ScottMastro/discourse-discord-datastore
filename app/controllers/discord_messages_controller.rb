module DiscordDatastore
  class DiscordMessagesController < ApplicationController

    requires_login
    PAGE_SIZE = 20

    def index
      page = params[:page].to_i || 1
      Rails.logger.info 'Called DiscordMessagesController#index'
      
      messages = DiscordDatastore::DiscordMessage.order(created_at: :desc)
      nMessages = messages.length
      messages = messages.offset(page * PAGE_SIZE).limit(PAGE_SIZE)
      messages = messages.includes(:discord_user).includes(:discord_channel)

      messages = messages.map { |msg| msg.as_json.merge({
        :channel_name => msg.discord_channel.name,
        :user_nickname => msg.discord_user.nickname,
        :user_tag => msg.discord_user.tag,
        :user_avatar => msg.discord_user.avatar
      }) }

      render json: { discord_messages: messages, total: nMessages }
    end

    def create
      Rails.logger.info 'Called DiscordMessagesController#create'

      message = {
        'id' => params[:message_id],
        'discord_user_id' => 6969420,
        'discord_channel_id' => 42069,
        'date' => Time.now,
        'content' => params[:discord_message][:content]
      }

      message = DiscordDatastore::DiscordMessage.create(message)
      render json: { message_id: message }
    end

    def destroy
      Rails.logger.info 'Called DiscordMessagesController#destroy'
      DiscordDatastore::DiscordMessage.destroy_by(id: params[:message_id])
      render json: success_json
    end
  end
end

