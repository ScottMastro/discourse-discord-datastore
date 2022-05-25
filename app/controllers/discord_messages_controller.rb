class DiscordMessagesController < ApplicationController
  def index
    Rails.logger.info 'Called DiscordMessagesController#index'
    messages = DiscordStore.get_discord_messages()

    render json: { discord_messages: messages.values }
  end


  def update
    Rails.logger.info 'Called DiscordMessagesController#update'

    message_id = params[:message_id]
    puts params
    message = {
      'id' => message_id,
      'content' => params[:discord_message][:content]
    }

    DiscordStore.add_discord_message(message_id, message)

    render json: { message_id: message }
  end
end
