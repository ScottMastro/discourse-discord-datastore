# frozen_string_literal: true

# name: discord-datastore
# about: Datastore for discord messages
# version: 0.0.1
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

register_asset 'stylesheets/common/discord.scss'

after_initialize do

  add_admin_route 'discord_datastore.title', 'discord-datastore'

  module ::DiscordDatastore
    PLUGIN_NAME = "discord-datastore"
  end
  
  class DiscordDatastore::Engine < Rails::Engine
      engine_name DiscordDatastore::PLUGIN_NAME
      isolate_namespace DiscordDatastore
  end

  require_relative 'app/discord_store.rb'
  require_relative 'app/controllers/discord_messages_controller.rb'
  require_relative 'app/controllers/discord_controller.rb'
  #require_relative 'app/models/discord_messages.rb'
  require_relative 'lib/bot.rb'
  
  DiscordDatastore::Engine.routes.draw do
    get "/discord" => "discord#index", constraints: StaffConstraint.new

  end
  
  Discourse::Application.routes.append do
    mount DiscordDatastore::Engine, at: "/"
    get '/admin/plugins/discord-datastore' => 'admin/plugins#index', constraints: StaffConstraint.new
    put '/discord_messages/:message_id' => 'discord_messages#update'
    get '/discord_messages' => 'discord_messages#index'
    delete '/discord_messages/:message_id' => 'discord_messages#destroy'
  end
  
  bot_thread = Thread.new do
    begin
      Bot.run_bot
    rescue Exception => ex
      Rails.logger.error("Discord Bot: There was a problem: #{ex}")
    end
  end

STDERR.puts '----------------------------------------------------'
STDERR.puts 'Datastore should be spawned, say "!ping" on Discord!'
STDERR.puts '----------------------------------------------------'
STDERR.puts '(--------       If not check logs         ---------)'
end

