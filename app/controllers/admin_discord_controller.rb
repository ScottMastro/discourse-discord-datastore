# frozen_string_literal: true

class DiscordDatastore::AdminDiscordController < ::ApplicationController

  def index
    render json: { name: "discord", description: "admin" }
  end    
end
