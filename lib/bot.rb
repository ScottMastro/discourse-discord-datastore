
#https://discord.com/api/oauth2/authorize?client_id=975850832195112991&permissions=17448381440&scope=bot

require 'discordrb'

# Container for the initialized bot
module Instance
  @@bot = nil

  def self.init
    @@bot = Discordrb::Commands::CommandBot.new token: "OTc1ODUwODMyMTk1MTEyOTkx.G7TNrM.UeKMu11BGGD2EJ2mOXCeNONLv2xbm_X5xQV_iY", prefix: "!"
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
            'author_id' => message.author.id,
            'channel_id' => message.channel.id,
            'date' => message.timestamp,
            'content' => message.content
          }
          DiscordDatastore::DiscordMessage.create(newMessage)
        end
      end
      
      bot.message() do |event|
        event.server.channels.each do |channel|
          if channel.text?

            messages = DiscordDatastore::DiscordMessage.order(date: :desc)
            messages = messages.where(channel_id: channel.id)
            messages = messages.limit(1)
            message = messages[0]

            if (message)
              loop do
                puts "channel name:", channel.name
                puts "last message id:", message.id
                newMessages = channel.history(HISTORY_CHUNK_LIMIT, after=message.id)

                if !newMessages
                  break
                end

                newRecords = newMessages.map do |message|
	          {
                    'id' => message.id,
                    'author_id' => message.author.id,
                    'channel_id' => message.channel.id,
                    'date' => message.timestamp,
                    'content' => message.content,
                    'created_at' => Time.now,
                    'updated_at' => Time.now
                  }
	        end

                #puts newRecords
                DiscordDatastore::DiscordMessage.insert_all(newRecords)
                message = newMessages[-1]
                sleep 5
                
              end
            end
          end
        end
      end

      bot.run
    end
  end
end

