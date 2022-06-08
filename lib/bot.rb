
#https://discord.com/api/oauth2/authorize?client_id=975850832195112991&permissions=17448381440&scope=bot

require 'discordrb'
MESSAGES_BEFORE_RESYNC = 200

module DiscordDatastore::BotInstance
  @@bot = nil
  @@message_count = 0

  def self.init
    @@message_count = 0
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

  def self.add_message
    STDERR.puts '------------------------------------------------------------'
    STDERR.puts '------------------------------------------------------------'
    @@message_count = @@message_count+1
    STDERR.puts @@message_count
    STDERR.puts '------------------------------------------------------------'
    STDERR.puts '------------------------------------------------------------'
    if @@message_count > MESSAGES_BEFORE_RESYNC
      @@message_count = 0
      return true
    end
    return false
  end

end

class DiscordDatastore::Bot

  def self.run_bot
    bot = DiscordDatastore::BotInstance::init
    bot.ready do |event|

      upsert_channels
      upsert_users
      browse_history

      bot.command(:ping, channels: [SiteSetting.discord_bot_channel]) do |event|
        event.respond 'pong!'
      end

      bot.command(:sync) do |event|
        upsert_channels
        upsert_users
        browse_history
      end

      bot.channel_create do
        upsert_channels
      end
      bot.channel_update do
        upsert_channels
      end

      bot.member_join do |event|
        upsert_user event.user
      end
      bot.member_update do |event|
        upsert_user event.user
      end

      bot.message do
        if DiscordDatastore::BotInstance::add_message
          browse_history

        end
      end


    end

    bot.run
  end
end