# frozen_string_literal: true

class DiscordDatastore::DiscordController < ::ApplicationController

  def index
    render json: { name: "donut", description: "delicious!" }
  end    
end
