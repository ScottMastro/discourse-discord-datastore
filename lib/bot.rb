
#https://discord.com/api/oauth2/authorize?client_id=______&permissions=17448381440&scope=bot

require 'discordrb'
MINUTES_BEFORE_RESYNC = SiteSetting.discord_minutes_before_resync

module DiscordDatastore::BotInstance
  @@bot = nil
  @@sync_thread = nil
  @@last_sync_time = Time.now

  def self.init
    
    if ! @@bot.nil?
      return @@bot
    end

    @@message_count = 0
    @@bot = Discordrb::Commands::CommandBot.new token: SiteSetting.discord_bot_token, prefix: SiteSetting.discord_bot_command_prefix, name: "bot"+rand(1..9999).to_s

    @@bot.ready do |event|

      STDERR.puts '------------------------------------------------------------'
      STDERR.puts 'Discord Datastore should be spawned, say ' + SiteSetting.discord_bot_command_prefix + 'ping" on Discord!'
      STDERR.puts '------------------------------------------------------------'
      STDERR.puts '(------------       If not check logs         -------------)'  

      puts "Logged in as #{@@bot.profile.username} (ID:#{@@bot.profile.id}) | #{@@bot.servers.size} servers"
      @@bot.send_message(SiteSetting.discord_bot_channel_id, "Datastore is alive!")
      @@bot.game=(SiteSetting.discord_bot_status)
      @@last_sync_time = Time.now

    end
    @@bot
  end

  def self.bot
    @@bot
  end
  def self.counter
    @@message_count
  end
  def self.timer

    sec = Time.now - @@last_sync_time
    timestr = "%02d:%02d:%02d" % [sec / 3600, sec / 60 % 60, sec % 60]    
    send "Time since last sync: " + timestr

  end

  def self.server
    @@bot.servers.each do |s|
      server_id = s[0]
      if server_id.to_s == SiteSetting.discord_server_id
        return @@bot.servers[server_id]     
      end
    end
    return nil
  end

  def self.should_sync
    if (Time.now - @@last_sync_time)/60 > MINUTES_BEFORE_RESYNC
      @@last_sync_time = Time.now
      return true
    end
    return false
  end

  def self.send(content)
    @@bot.send_message(SiteSetting.discord_bot_channel_id, bot.name + ": " + content)
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
          update_ranks
          status_message = DiscordDatastore::BotInstance.send("Syncing complete.")

        rescue Exception => ex
          Rails.logger.error("DiscordDatastore Bot: Syncing thread failed: #{ex}")
        end
      end
      return send("Syncing data...")
      @@last_sync_time = Time.now
    end
    return send("Currenly syncing, try again later.")
  end
end

class DiscordDatastore::Bot

  def self.run_bot

    if DiscordDatastore::BotInstance::bot.nil?

      bot = DiscordDatastore::BotInstance::init
      bot.ready do |event|

        DiscordDatastore::BotInstance.sync
        
        bot.command(:admin, channels: [SiteSetting.discord_bot_channel_id], help_available: false) do |event|
          commands = "**List of admin commands**\n"
          commands = commands + "**`ping`**: Pings the bot.\n"
          commands = commands + "**`sync`**: Triggers a sync job.\n"
          commands = commands + "**`time`**: Displays time since last sync."
    
          bot.send_message(SiteSetting.discord_bot_channel_id, commands)
        end

        bot.command(:ping, channels: [SiteSetting.discord_bot_channel_id], help_available: false) do |event|
          event.respond 'pong!'
        end

        bot.command(:time, channels: [SiteSetting.discord_bot_channel_id], help_available: false) do |event|
          event.respond DiscordDatastore::BotInstance.timer
        end

        bot.command(:count, description: "Get total Discord post count.") do |event|
          total = DiscordDatastore::DiscordMessage.where(discord_user_id: event.user.id).count
          event.respond event.user.username + ": " + total.to_s + " messages!"
        end

        bot.command(:sync, help_available: false) do |event|
          DiscordDatastore::BotInstance.sync
        end

        bot.channel_create do
          upsert_channels
        end
        bot.channel_update do
          upsert_channels
        end

        bot.member_join do |event|

          server = DiscordDatastore::BotInstance::server
          banned_ids = SiteSetting.discord_ban_id.split("|")

          if banned_ids.include? event.user.id.to_s
            begin
              server.ban(event.user.id)
            rescue
                STDERR.puts "DISCORD ERROR -----> Failed to ban user with id="+event.user.id.to_s+". Check permissions?"
            end
          end

          upsert_user event.user
          DiscordDatastore::Verifier.verify_from_discord(event.user.id)

        end
        bot.member_update do |event|
          upsert_user event.user
        end

        bot.message do |event|
          if ! event.author.bot_account
            if DiscordDatastore::BotInstance::should_sync
              DiscordDatastore::BotInstance.sync true
            end
          end
        end
      end

      bot.run true
    end
  end
end
