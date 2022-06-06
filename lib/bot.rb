
#https://discord.com/api/oauth2/authorize?client_id=975850832195112991&permissions=17448381440&scope=bot

require 'discordrb'

HISTORY_CHUNK_LIMIT = 100
HISTORY_WAIT_SECONDS = 2

module DiscordDatastore::BotInstance
  @@bot = nil

  def self.init
    @@bot = Discordrb::Commands::CommandBot.new token: SiteSetting.discord_bot_token, prefix: SiteSetting.discord_bot_command_prefix
    STDERR.puts '------------------------------------------------------------'
    STDERR.puts 'Discord Datastore should be spawned, say ' + SiteSetting.discord_bot_command_prefix + 'ping" on Discord!'
    STDERR.puts '------------------------------------------------------------'
    STDERR.puts '(------------       If not check logs         -------------)'

    @@bot.ready do |event|
      puts "Logged in as #{@@bot.profile.username} (ID:#{@@bot.profile.id}) | #{@@bot.servers.size} servers"
      @@bot.send_message(SiteSetting.discord_bot_channel, "Datastore is alive!")

    end
    @@bot
  end

  def self.bot
    @@bot
  end
end


class DiscordDatastore::MessageHistory

  def self.collect
    bot = DiscordDatastore::BotInstance::bot
    bot.game=("Scanning message history...")


    sleep HISTORY_WAIT_SECONDS

  end
end 


class DiscordDatastore::Bot

  def self.run_bot
    bot = DiscordDatastore::BotInstance::init
    bot.ready do |event|

      upsert_channels
      upsert_users

      history_thread = Thread.new do
        begin
          DiscordDatastore::MessageHistory.collect
        rescue Exception => ex
          Rails.logger.error("DiscordDatastore HistoryBot: There was a problem: #{ex}")
        end
      end

      bot.command(:ping, channels: [SiteSetting.discord_bot_channel]) do |event|
        event.respond 'pong!'
      end

      bot.channel_update do
        upsert_channels
      end
      bot.channel_create do
        upsert_channels
      end
  end

    bot.command(:fetch) do |event|
      event.channel.history(HISTORY_CHUNK_LIMIT).each do |message|

        newMessage = {
          'id' => message.id,
          'discord_user_id' => message.author.id,
          'discord_channel_id' => message.channel.id,
          'date' => message.timestamp,
          'content' => message.content
        }
        DiscordDatastore::DiscordMessage.create(newMessage)
      end
    end

    bot.command(:channels) do |event|
      event.server.channels.each do |channel|
        newChannel = {
          'id' => channel.id,
          'name' => channel.name,
          'voice' => (! channel.text?) ,
          'permissions' => []
        }
        DiscordDatastore::DiscordChannel.create(newChannel)
      end
    end
    

    bot.run
  end
end