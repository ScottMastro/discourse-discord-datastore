# frozen_string_literal: true

class DiscordDatastore::DiscordController < ::ApplicationController
  requires_plugin "discourse-discord-datastore"

  def index
    head :ok
  end
end
