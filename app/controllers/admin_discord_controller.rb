# frozen_string_literal: true

class DiscordDatastore::AdminDiscordController < ::ApplicationController
  requires_plugin "discourse-discord-datastore"
  requires_login
  before_action :ensure_staff

  def index
    render json: { name: "discord", description: "admin" }
  end
end
