# frozen_string_literal: true

# name: discourse-discord-datastore
# about: Datastore for discord messages
# version: 1.3
# authors: ScottMastro
# url: https://github.com/ScottMastro/discourse-discord-datastore
# required_version: 2.7.0
# transpile_js: true

gem "mutex_m", "0.3.0"
gem "websocket", "1.2.11"
gem "event_emitter", "0.2.6"
gem "websocket-client-simple", "0.9.0"
gem "opus-ruby", "1.0.1", { require: false }
gem "netrc", "0.11.0"
gem "domain_name", "0.6.20240107"
gem "http-cookie", "1.1.4"
gem "http-accept", "1.7.0", { require: false }
gem "mime-types-data", "3.2026.0407"
gem "mime-types", "3.7.0"
gem "rest-client", "2.1.0"

gem "discordrb-webhooks", "3.7.2", { require: false }
gem "discordrb", "3.7.2"

enabled_site_setting :discord_datastore_enabled

register_asset "stylesheets/common/common.scss"
register_asset "stylesheets/mobile/mobile.scss", :mobile

register_svg_icon "fab-discord" if respond_to?(:register_svg_icon)

after_initialize do
  module ::DiscordDatastore
    PLUGIN_NAME = "discord-datastore"
  end

  class DiscordDatastore::Engine < Rails::Engine
    engine_name DiscordDatastore::PLUGIN_NAME
    isolate_namespace DiscordDatastore
  end

  require_relative "app/controllers/concerns/discord_id_resolvable.rb"
  require_relative "app/controllers/discord_messages_controller.rb"
  require_relative "app/controllers/discord_channels_controller.rb"
  require_relative "app/controllers/discord_users_controller.rb"
  require_relative "app/controllers/discord_ranks_controller.rb"

  require_relative "app/controllers/admin_discord_controller.rb"
  require_relative "app/controllers/discord_controller.rb"

  require_relative "app/models/discord_message.rb"
  require_relative "app/models/discord_channel.rb"
  require_relative "app/models/discord_user.rb"

  require_relative "app/serializers/discord_message_serializer.rb"
  require_relative "app/serializers/discord_channel_serializer.rb"
  require_relative "app/serializers/discord_user_serializer.rb"

  require_relative "lib/bot_helper.rb"
  require_relative "lib/bot.rb"
  require_relative "lib/verifier.rb"

  DiscordDatastore::Engine.routes.draw do
    get "/discord" => "discord#index"
    get "/admin/discord" => "admin_discord#index", :constraints => StaffConstraint.new
    get "/discord/messages" => "discord_messages#messages"
    get "/discord/channels" => "discord_channels#channels"
    get "/discord/users" => "discord_users#users"
    get "/discord/ranks" => "discord_ranks#ranks"
    post "/discord/badge_collect" => "discord_ranks#collect"
  end

  Discourse::Application.routes.append { mount DiscordDatastore::Engine, at: "/" }

  # Boot the long-lived Discord websocket only in the forked sidekiq child.
  # after_initialize runs once in the preloaded unicorn parent, so we can't
  # gate there; sidekiq_fork_started fires in each sidekiq process right
  # after fork, which is exactly where we want a single long-lived bot.
  on(:sidekiq_fork_started) do
    if SiteSetting.discord_datastore_enabled && DiscordDatastore::BotInstance.bot.nil?
      DiscordDatastore::Bot.run_bot
    end
  end

  on(:after_auth) do |authenticator, auth_result|
    if authenticator.name == "discord" && auth_result.user.id > 0
      DiscordDatastore::Verifier.verify_user(auth_result.user)
    end
  end
end
