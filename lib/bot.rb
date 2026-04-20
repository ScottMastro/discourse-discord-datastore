# frozen_string_literal: true

#https://discord.com/api/oauth2/authorize?client_id=______&permissions=17448381440&scope=bot

module DiscordDatastore::BotInstance
  @bot = nil
  @sync_thread = nil
  @last_sync_time = Time.now

  def self.init
    return @bot if !@bot.nil?

    @message_count = 0
    @bot =
      Discordrb::Commands::CommandBot.new token: SiteSetting.discord_bot_token,
                                          prefix: SiteSetting.discord_bot_command_prefix,
                                          name: "bot" + rand(1..9999).to_s

    @bot.ready do |event|
      Rails.logger.info(
        "DiscordDatastore Bot: spawned, say #{SiteSetting.discord_bot_command_prefix}ping on Discord",
      )
      Rails.logger.info(
        "DiscordDatastore Bot: logged in as #{@bot.profile.username} (ID:#{@bot.profile.id}) | #{@bot.servers.size} servers",
      )
      @bot.send_message(SiteSetting.discord_bot_channel_id, "Datastore is alive!")
      @bot.game = (SiteSetting.discord_bot_status)
      @last_sync_time = Time.now
    end
    @bot
  end

  def self.bot
    @bot
  end

  def self.counter
    @message_count
  end

  def self.timer
    sec = Time.now - @last_sync_time
    timestr = "%02d:%02d:%02d" % [sec / 3600, sec / 60 % 60, sec % 60]
    send_to_channel "Time since last sync: " + timestr
  end

  def self.server
    @bot.servers.each do |s|
      server_id = s[0]
      return @bot.servers[server_id] if server_id.to_s == SiteSetting.discord_server_id
    end
    nil
  end

  def self.should_sync
    if (Time.now - @last_sync_time) / 60 > SiteSetting.discord_minutes_before_resync
      @last_sync_time = Time.now
      return true
    end
    false
  end

  def self.send_to_channel(content)
    @bot.send_message(SiteSetting.discord_bot_channel_id, content)
  end

  def self.sync(history_only = false)
    if @sync_thread.nil? || !@sync_thread.alive?
      @sync_thread =
        Thread.new do
          begin
            if !history_only
              DiscordDatastore::BotHelper.upsert_channels
              DiscordDatastore::BotHelper.upsert_users
            end

            DiscordDatastore::BotHelper.browse_history
            DiscordDatastore::BotHelper.update_ranks
            status_message = DiscordDatastore::BotInstance.send_to_channel("Syncing complete.")
          rescue StandardError => e
            Rails.logger.error("DiscordDatastore Bot: Syncing thread failed: #{e}")
          end
        end
      @last_sync_time = Time.now
      return send_to_channel("Syncing data...")
    end
    send_to_channel("Currently syncing, try again later.")
  end

  def self.info()
    return send_to_channel("sync_thread is nil") if @sync_thread.nil?
    send_to_channel(@sync_thread.to_s)
    send_to_channel("nil? " + @sync_thread.nil?.to_s)
    send_to_channel("alive? " + @sync_thread.alive?.to_s)
  end
end

class DiscordDatastore::Bot
  def self.run_bot
    if DiscordDatastore::BotInstance.bot.nil?
      bot = DiscordDatastore::BotInstance.init
      bot.ready do |_ready_event|
        DiscordDatastore::BotInstance.sync

        bot.command(
          :admin,
          channels: [SiteSetting.discord_bot_channel_id],
          help_available: false,
        ) do |event|
          commands = "**List of admin commands**\n"
          commands = commands + "**`ping`**: Pings the bot.\n"
          commands = commands + "**`sync`**: Triggers a sync job.\n"
          commands = commands + "**`time`**: Displays time since last sync."

          bot.send_message(SiteSetting.discord_bot_channel_id, commands)
        end

        bot.command(
          :ping,
          channels: [SiteSetting.discord_bot_channel_id],
          help_available: false,
        ) { |event| event.respond "pong!" }

        bot.command(
          :time,
          channels: [SiteSetting.discord_bot_channel_id],
          help_available: false,
        ) { |event| event.respond DiscordDatastore::BotInstance.timer }

        bot.command(:count, description: "Get total Discord post count.") do |event|
          total = DiscordDatastore::DiscordMessage.where(discord_user_id: event.user.id).count
          event.respond event.user.username + ": " + total.to_s + " messages!"
        end

        bot.command(:quote, description: "Get a random quote from your Discord history.") do |event|
          scope = DiscordDatastore::DiscordMessage.where(discord_user_id: event.user.id)
          scope = scope.where.not(content: [nil, ""])
          total = scope.count

          if total.zero?
            event.respond "#{event.user.username}: no messages on file yet."
          else
            message = scope.offset(rand(total)).first
            date = message.date.strftime("%d %b %Y")
            event.respond "> #{message.content}\n— #{event.user.username}, #{date}"
          end
        end

        bot.command(:sync, help_available: false) { |event| DiscordDatastore::BotInstance.sync }

        bot.command(:info, help_available: false) { |event| DiscordDatastore::BotInstance.info }

        bot.channel_create { DiscordDatastore::BotHelper.upsert_channels }
        bot.channel_update { DiscordDatastore::BotHelper.upsert_channels }

        bot.member_join do |event|
          server = DiscordDatastore::BotInstance.server
          banned_ids = SiteSetting.discord_ban_id.split("|")

          if banned_ids.include? event.user.id.to_s
            begin
              server.ban(event.user.id)
            rescue StandardError
              Rails.logger.error(
                "DiscordDatastore Bot: failed to ban user id=#{event.user.id} — check permissions",
              )
            end
          end

          DiscordDatastore::BotHelper.upsert_user(event.user)
          DiscordDatastore::Verifier.verify_from_discord(event.user.id)
        end
        bot.member_update { |event| DiscordDatastore::BotHelper.upsert_user(event.user) }

        bot.message do |event|
          if !event.author.bot_account
            DiscordDatastore::BotInstance.sync true if DiscordDatastore::BotInstance.should_sync
          end
        end
      end

      bot.run true
    end
  end
end
