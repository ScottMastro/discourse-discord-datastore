module DiscordDatastore
  class DiscordMessagesController < ApplicationController

    requires_login
    PAGE_SIZE = 15

    def index
      Rails.logger.info 'Called DiscordMessagesController#index'
      messages = DiscordStore.get_discord_messages()

      render json: { discord_messages: messages.values }
    end

    def create
      Rails.logger.info 'Called DiscordMessagesController#create'

      message = {
        'id' => params[:message_id],
        'content' => params[:discord_message][:content]
      }

      message = DiscordDatastore::DiscordMessage.create(message)
      #DiscordStore.add_discord_message(message_id, message)
      
      #render_serialized(message, DiscordMessageSerializer)
      render json: { message_id: message }
    end

    def destroy
      Rails.logger.info 'Called DiscordMessagesController#destroy'
      DiscordStore.remove_discord_message(params[:message_id])
      render json: success_json
    end
  end
end
