# frozen_string_literal: true

class DiscordDatastore::DiscordMessagesController < ::ApplicationController

  def index
    render json: [{'hello': 'world'}]
  end    
end
