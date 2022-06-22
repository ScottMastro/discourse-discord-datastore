
#https://discord.com/api/oauth2/authorize?client_id=______&permissions=17448381440&scope=bot

require 'discordrb'
MESSAGES_BEFORE_RESYNC = SiteSetting.discord_messages_before_resync

module DiscordDatastore::BotInstance
  @@bot = nil
  @@sync_thread = nil
  @@message_count = 0

  def self.init
    @@message_count = 0
    @@bot = Discordrb::Commands::CommandBot.new token: SiteSetting.discord_bot_token, prefix: SiteSetting.discord_bot_command_prefix

    @@bot.ready do |event|

      STDERR.puts '------------------------------------------------------------'
      STDERR.puts 'Discord Datastore should be spawned, say ' + SiteSetting.discord_bot_command_prefix + 'ping" on Discord!'
      STDERR.puts '------------------------------------------------------------'
      STDERR.puts '(------------       If not check logs         -------------)'  

      puts "Logged in as #{@@bot.profile.username} (ID:#{@@bot.profile.id}) | #{@@bot.servers.size} servers"
      @@bot.send_message(SiteSetting.discord_bot_channel_id, "Datastore is alive!")
      bot.game=(SiteSetting.discord_bot_status)

    end
    @@bot
  end

  def self.bot
    @@bot
  end
  def self.counter
    @@message_count
  end

  def self.add_message
    @@message_count = @@message_count+1
    if @@message_count > MESSAGES_BEFORE_RESYNC
      @@message_count = 0
      return true
    end
    return false
  end

  def self.send(content)
    @@bot.send_message(SiteSetting.discord_bot_channel_id, content)
  end

  def self.sync(history_only=false)

    if @@sync_thread.nil? || ! @@sync_thread.alive?

      @@sync_thread = Thread.new do
        begin

          if !history_only
            upsert_channels
            upsert_users
          end

          browse_history
          #update_ranks

        rescue Exception => ex
          Rails.logger.error("DiscordDatastore Bot: Syncing thread failed: #{ex}")
        end
      end
      return true
    end
    return false
  end
end

class DiscordDatastore::Bot

  def self.run_bot
    bot = DiscordDatastore::BotInstance::init
    bot.ready do |event|

      DiscordDatastore::BotInstance.sync
      
      bot.command(:ping, channels: [SiteSetting.discord_bot_channel_id]) do |event|
        event.respond 'pong!'
      end

      bot.command(:counter, channels: [SiteSetting.discord_bot_channel_id]) do |event|
        event.respond DiscordDatastore::BotInstance.counter.to_s
      end

      bot.command(:count) do |event|
        total = DiscordDatastore::DiscordMessage.where(discord_user_id: event.user.id).count
        event.respond event.user.username + ": " + total.to_s + " messages!"
      end

      bot.command(:sync) do |event|
        DiscordDatastore::BotInstance.sync
      end

      bot.channel_create do
        upsert_channels
      end
      bot.channel_update do
        upsert_channels
      end

      bot.member_join do |event|
        upsert_user event.user
        DiscordDatastore::Verifier.verify_from_discord(event.user.id)
      end
      bot.member_update do |event|
        upsert_user event.user
      end

      bot.message do |event|
        if ! event.author.bot_account

          #event.respond event.content

          if DiscordDatastore::BotInstance::add_message
            DiscordDatastore::BotInstance.sync true
          end
        end
      end
    end

    bot.run
  end
end
