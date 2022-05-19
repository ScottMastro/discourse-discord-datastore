
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

class Bot
  def self.run_bot
    bot = Instance::init

    unless bot.nil?

      bot.ready do |event|
        puts "Logged in as #{bot.profile.username} (ID:#{bot.profile.id}) | #{bot.servers.size} servers"
        Instance::bot.send_message("556166816909623311", "Datastore is alive!")
      end

      # Add a simple command to confirm everything works properly
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
              event.respond  'I am rescued.'
	    end 
          end
          sleep 2
        end
      end

      bot.command(:fetch) do |event|
        event.channel.history(50).each do |message|
          puts message.author
        end

      end


      bot.run
    end
  end
end

