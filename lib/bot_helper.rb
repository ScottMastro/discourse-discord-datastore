HISTORY_CHUNK_LIMIT = 100
HISTORY_WAIT_SECONDS = 3
#todo: get message attachments??

def get_server
    DiscordDatastore::BotInstance.bot.servers.each do |s|
      server_id = s[0]
      if server_id.to_s == SiteSetting.discord_server_id
        return DiscordDatastore::BotInstance.bot.servers[server_id]     
      end
    end
    return nil
end

def get_channels
    server = get_server
    if server
        return server.channels
    end
    return []
end

def get_users
    server = get_server
    if server
      return server.members
    end
    return []
end

def get_ranks
    server = get_server
    if server
      return server.roles
    end
    return []
end

def upsert_channels
    existingchannels = DiscordDatastore::DiscordChannel.all
    #DiscordDatastore::DiscordChannel.delete_all
  
    get_channels.each do |channel|
        next if channel.type != 0 #text channel

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
            'position' => channel.position,
            'created_at' => create_time,
            'updated_at'=> Time.now  
        }
        DiscordDatastore::DiscordChannel.upsert(discordchannel)
    end
end

def upsert_users
    existingusers = DiscordDatastore::DiscordUser.all
    #DiscordDatastore::DiscordUser.delete_all

    get_users.each do |user|
        create_time = Time.now
        is_verified = false
        discourse_id = -1
        existingusers.each do |u|
            if u.id == user.id
                create_time = u.created_at
                is_verified = u.verified
                discourse_id = u.discourse_account_id
            end
        end
        
        discorduser = {
            'id' => user.id,
            'tag' => user.username + "#" + user.discriminator,
            'nickname' => user.display_name,
            'avatar' => user.avatar_url,
            'verified' => is_verified,
            'discourse_account_id' => discourse_id,
            'created_at' => create_time,
            'updated_at'=> Time.now
        }
        DiscordDatastore::DiscordUser.upsert(discorduser)
    end
end

def upsert_user(user)

    create_time = Time.now
    is_verified = false
    discourse_id = -1

    u = DiscordDatastore::DiscordUser.find(user.id)

    if u
        create_time = u.created_at
        is_verified = u.verified
        discourse_id = u.discourse_account_id
    end

    discorduser = {
        'id' => user.id,
        'tag' => user.username + "#" + user.discriminator,
        'nickname' => user.display_name,
        'avatar' => user.avatar_url,
        'verified' => is_verified,
        'discourse_account_id' => discourse_id,
        'created_at' => create_time,
        'updated_at'=> Time.now
    }

    DiscordDatastore::DiscordUser.upsert(discorduser)
end

def get_oldest_message_id(channel)

    messages = DiscordDatastore::DiscordMessage.where(discord_channel_id: channel.id).order(:date).limit(1)

    if messages.length() > 0
        return messages[0].id
    end

    recent = channel.history(1)
    if recent.length() > 0
        return recent[0].id
    end

    return -1

end

def get_newest_message_id(channel)

    messages = DiscordDatastore::DiscordMessage.where(discord_channel_id: channel.id).order(date: :desc).limit(1)

    if messages.length() > 0
        return messages[0].id
    end

    recent = channel.history(1)
    if recent.length() > 0
        return recent[0].id
    end

    return -1

end

def parse_discord_messages(messages)
    parsed = messages.map do |message|
        
        attachments = []

        message.attachments.each do |attachment|
            attachments.push(attachment.url)
        end

        {
            'id' => message.id,
            'discord_user_id' => message.author.id,
            'discord_channel_id' => message.channel.id,
            'date' => message.timestamp,
            'content' => message.content,
            'attachments' => attachments,
            'created_at' => Time.now,
            'updated_at' => Time.now
        }
    end
    return parsed
end

def browse_history
    bot = DiscordDatastore::BotInstance.bot
    bot.game=("Scanning history...")

    #DiscordDatastore::DiscordMessage.delete_all

    get_channels.each do |channel|
        next if channel.type != 0

        begin
            last_id = get_oldest_message_id channel
        rescue
            next # cannot access channel
        end

        next if last_id == -1
        
        loop do
            messages = channel.history(HISTORY_CHUNK_LIMIT, before_id=last_id)
            if messages.length() == 0
                break
            end

            discordmessages = parse_discord_messages messages
            DiscordDatastore::DiscordMessage.upsert_all(discordmessages)
            
            STDERR.puts "Grabbed " + discordmessages.length().to_s + " Discord messages from #" + channel.name
            STDERR.puts '------------------------------------------------------------'
            last_id = messages[-1].id

            sleep HISTORY_WAIT_SECONDS
        end
        
        last_id = get_newest_message_id channel
        next if last_id == -1
        
        loop do
            messages = channel.history(HISTORY_CHUNK_LIMIT, before_id=nil, after_id=last_id)
            messages.each do |message|
                STDERR.puts message.timestamp
            end
            if messages.length() == 0
                break
            end

            discordmessages = parse_discord_messages messages
            DiscordDatastore::DiscordMessage.upsert_all(discordmessages)
            
            STDERR.puts "Grabbed " + discordmessages.length().to_s + " Discord messages from #" + channel.name
            STDERR.puts '------------------------------------------------------------'
            last_id = messages[0].id

            sleep HISTORY_WAIT_SECONDS
        end
    end

    bot.game=(SiteSetting.discord_bot_status)
end

def update_ranks
    bot = DiscordDatastore::BotInstance.bot
    bot.game=("Updating ranks...")

    rank_names = SiteSetting.discord_rank_name.split("|")
    requirements = SiteSetting.discord_rank_count.split("|")

    ranks = []
    all_ranks = get_ranks

    rank_names.each do |rank_name|
        all_ranks.each do |rank|
            if rank_name == rank.name 
                ranks.push(rank)
            end
        end
    end

    counts = DiscordDatastore::DiscordMessage.group(:discord_user_id).count
    users = get_users

    users.each do |user|
        next if user.bot_account

        count = counts[user.id]
        target_rank_id = -1
        i=0
        requirements.each do |requirement|
            if count >= requirement.to_i
                target_rank_id = ranks[i].id
            end
            i+=1
        end

        user_ranks = user.roles

        ranks.each do |rank|

            if user.role? rank
                if rank.id != target_rank_id
                    user_ranks.delete(rank)
                end
            else
                if rank.id == target_rank_id
                    user_ranks.push(rank)
                end
            end
        end

        user.set_roles user_ranks
    end

    bot.game=(SiteSetting.discord_bot_status)
end