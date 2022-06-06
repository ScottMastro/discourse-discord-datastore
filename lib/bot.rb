
#https://discord.com/api/oauth2/authorize?client_id=975850832195112991&permissions=17448381440&scope=bot

require 'discordrb'
HISTORY_CHUNK_LIMIT = 100
CHANNEL_HOME = SiteSetting.discord_bot_channel

module DiscordDatastore::BotInstance
  @@bot = nil

  def self.init
    @@bot = Discordrb::Commands::CommandBot.new token: SiteSetting.discord_bot_token, prefix: "!"
    
    @@bot.ready do |event|
      puts "Logged in as #{@@bot.profile.username} (ID:#{@@bot.profile.id}) | #{@@bot.servers.size} servers"
      @@bot.send_message(CHANNEL_HOME, "Datastore is alive!")

      STDERR.puts '------------------------------------------------------------'
      STDERR.puts 'Discord Datastore should be spawned, say "!ping" on Discord!'
      STDERR.puts '------------------------------------------------------------'
      STDERR.puts '(------------       If not check logs         -------------)'
    end
    @@bot
  end

  def self.bot
    @@bot
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

  def self.channels
    if self.server
      return self.server.channels
    end
    return []
  end
end



def upsert_channels
  existingchannels = DiscordDatastore::DiscordChannel.all

  DiscordDatastore::DiscordChannel.delete_all

  DiscordDatastore::BotInstance.channels.each do |channel|

    if channel.type == 0 #text channel

      create_time = Time.now
      existingchannels.each do |c|
        if c.id == channel.id
          create_time = c.created_at
        end
      end
      
      discordchannel = {
        'id' => channel.id,
        'name' => channel.name,
        'voice' => (! channel.text?) ,
        'permissions' => [],
        'position' => channel.position,
        'created_at' => create_time,
        'updated_at'=> Time.now
      }
      DiscordDatastore::DiscordChannel.upsert(discordchannel)
    end
  end
end


class DiscordDatastore::HistoryBot

  def self.run_bot
    bot = DiscordDatastore::BotInstance::bot
    
    bot.ready do |event|
      bot.game=("Scanning history...")

      STDERR.puts '------------------------------------------------------------'
      STDERR.puts '------------------------------------------------------------'
      STDERR.puts '------------------------------------------------------------'
      STDERR.puts '------------------------------------------------------------'
      STDERR.puts '------------------------------------------------------------'
      STDERR.puts '------------------------------------------------------------'
      STDERR.puts '------------------------------------------------------------'
      STDERR.puts '------------------------------------------------------------'
      STDERR.puts '------------------------------------------------------------'
      STDERR.puts '------------------------------------------------------------'
      STDERR.puts '------------------------------------------------------------'
      STDERR.puts '------------------------------------------------------------'
      STDERR.puts '------------------------------------------------------------'

      upsert_channels

      STDERR.puts '^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^'

    end



  end
end 


class DiscordDatastore::Bot

  def self.run_bot
    bot = DiscordDatastore::BotInstance::init

    history_thread = Thread.new do
      begin
        DiscordDatastore::HistoryBot.run_bot
      rescue Exception => ex
        Rails.logger.error("DiscordDatastore HistoryBot: There was a problem: #{ex}")
      end
    end  


    bot.command(:ping) do |event|
      event.respond 'pong!'
    end

    bot.command(:check) do |event|
      event.server.channels.each do |channel|
        event.respond channel.to_s
        if channel.text?
          begin  # "try" block
            channel.send_message "hi"
    rescue # optionally: `rescue Exception => ex`
            event.respond 'I am rescued.'
    end 
        end
        sleep 2
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

    bot.command(:users) do |event|
      event.server.members.each do |member|
        newMember = {
          'id' => member.id,
          'tag' => member.username + "#" + member.discriminator,
          'nickname' => member.display_name,
          'avatar' => member.avatar_url,
          'roles' => [],
          'verified' => false,
          'discourse_account_id' => -1
        }
        DiscordDatastore::DiscordUser.create(newMember)
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

