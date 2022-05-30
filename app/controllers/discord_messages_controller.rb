module DiscordDatastore
  class DiscordMessagesController < ApplicationController

    requires_login
    PAGE_SIZE = 20

    def index
      page=1
      #page = params[:page].to_i || 1
      Rails.logger.info 'Called DiscordMessagesController#index'

      messages = DiscordDatastore::DiscordMessage.order(created_at: :desc)
      nMessages = messages.length
      messages = messages.offset(page * PAGE_SIZE).limit(PAGE_SIZE)
      render json: { discord_messages: messages, test: nMessages }
    end

    def total_messages
      totalMessages = DiscordDatastore::DiscordMessage.count
      render json: { total_messages: totalMessages }
    end

    def create
      Rails.logger.info 'Called DiscordMessagesController#create'

      message = {
        'id' => params[:message_id],
        'author_id' => 6969420,
        'channel_id' => 42069,
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

