# frozen_string_literal: true

# name: discord-datastore
# about: Datastore for discord messages
# version: 1.0.2
# authors: ScottMastro
# url: discord
# required_version: 2.7.0
# transpile_js: true

gem 'rbnacl', '3.4.0'
gem 'event_emitter', '0.2.6'
gem 'websocket', '1.2.8'
gem 'websocket-client-simple', '0.3.0'
gem 'opus-ruby', '1.0.1', { require: false }
gem 'netrc', '0.11.0'
gem 'mime-types-data', '3.2019.1009'
gem 'mime-types', '3.3.1'
gem 'domain_name', '0.5.20180417'
gem 'http-cookie','1.0.3'
gem 'http-accept', '1.7.0', { require: false }
gem 'rest-client', '2.1.0.rc1'

gem 'discordrb-webhooks', '3.3.0', {require: false}
gem 'discordrb', '3.3.0'

enabled_site_setting :discord_datastore_enabled

register_asset 'stylesheets/common/common.scss'
register_asset 'stylesheets/mobile/mobile.scss', :mobile

register_svg_icon "fab-discord" if respond_to?(:register_svg_icon)

after_initialize do

  module ::DiscordDatastore
    PLUGIN_NAME = "discord-datastore"
  end
  
  class DiscordDatastore::Engine < Rails::Engine
      engine_name DiscordDatastore::PLUGIN_NAME
      isolate_namespace DiscordDatastore
  end

  require_relative 'app/controllers/discord_messages_controller.rb'
  require_relative 'app/controllers/discord_channels_controller.rb'
  require_relative 'app/controllers/discord_users_controller.rb'
  require_relative 'app/controllers/discord_ranks_controller.rb'

  require_relative 'app/controllers/admin_discord_controller.rb'
  require_relative 'app/controllers/discord_controller.rb'
  
  require_relative 'app/models/discord_message.rb'
  require_relative 'app/models/discord_channel.rb'
  require_relative 'app/models/discord_user.rb'

  require_relative 'lib/bot_helper.rb'
  require_relative 'lib/bot.rb'
  require_relative 'lib/verifier.rb'

  DiscordDatastore::Engine.routes.draw do
    get "/discord" => "discord#index"
    get '/admin/discord' => 'admin_discord#index', constraints: StaffConstraint.new

    get '/discord/messages' => 'discord_messages#messages'
    get '/discord/channels' => 'discord_channels#channels'
    get '/discord/users' => 'discord_users#users'
    get '/discord/ranks' => 'discord_ranks#ranks'
    get '/discord/badge_collect' => 'discord_ranks#collect'
  end
  
  Discourse::Application.routes.append do
    mount DiscordDatastore::Engine, at: "/"
  end
  
  bot_thread = Thread.new do
    begin
      DiscordDatastore::Bot.run_bot
    rescue Exception => ex
      Rails.logger.error("DiscordDatastore Bot: There was a problem: #{ex}")
    end
  end

  DiscourseEvent.on(:after_auth) do |authenticator, auth_result|
    if authenticator.name == "discord" && auth_result.user.id > 0 then DiscordDatastore::Verifier.verify_user(auth_result.user) end
  end
end