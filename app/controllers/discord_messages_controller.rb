module DiscordDatastore
  class DiscordMessagesController < ApplicationController

    requires_login
    PAGE_SIZE = 15

    def index
      page=1
      #page = params[:page].to_i || 1
      Rails.logger.info 'Called DiscordMessagesController#index'

      messages = DiscordDatastore::DiscordMessage.order(created_at: :desc)
      messages = messages.offset(page * PAGE_SIZE).limit(PAGE_SIZE)
      render json: { discord_messages: messages }
    end

    def create
      Rails.logger.info 'Called DiscordMessagesController#create'

      message = {
        'id' => params[:message_id],
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

