# frozen_string_literal: true

class DiscordDatastore::DiscordController < ::ApplicationController
  requires_plugin "discourse-discord-datastore"

  def index
    render json: { name: "discord", description: "interface" }
  end
end
