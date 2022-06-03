
#https://discord.com/api/oauth2/authorize?client_id=975850832195112991&permissions=17448381440&scope=bot

require 'discordrb'

# Container for the initialized bot
module Instance
  @@bot = nil

  def self.init
    @@bot = Discordrb::Commands::CommandBot.new token: "OTc1ODUwODMyMTk1MTEyOTkx.Gnat6X.Mr53nWZeEPOtCTc5h0-YtJu197uY4N4UmZjcas", prefix: "!"
    @@bot
  end

  def self.bot
    @@bot
  end
end

HISTORY_CHUNK_LIMIT = 100
CHANNEL_HOME = "556166816909623311"

class Bot
  def self.run_bot
    bot = Instance::init

    unless bot.nil?

      bot.ready do |event|
        puts "Logged in as #{bot.profile.username} (ID:#{bot.profile.id}) | #{bot.servers.size} servers"
        Instance::bot.send_message(CHANNEL_HOME, "Datastore is alive!")
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
end

