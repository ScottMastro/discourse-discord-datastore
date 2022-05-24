class DiscordDatastore::DiscordMessagesController < ApplicationController
  def update
    Rails.logger.info 'Called DiscordMessagesController#update'

    note_id = params[:message_id]
    message = {
      'id' => discordmessage_id,
      'content' => params[:discordmessage][:content]
    }

    DiscordStore.add_discordmessage(message_id, message)

    render json: { message_id: message }
  end
end
