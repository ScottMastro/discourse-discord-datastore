# frozen_string_literal: true

class DiscordDatastore::DiscordController < ::ApplicationController

  def index
    render json: { name: "discord", description: "user" }
  end    
end
