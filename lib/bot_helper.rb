HISTORY_CHUNK_LIMIT = 100
HISTORY_WAIT_SECONDS = 3
USER_SCAN_UPDATE = 200
MESSAGE_SCAN_UPDATE = 300

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
    bot = DiscordDatastore::BotInstance.bot

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
    bot = DiscordDatastore::BotInstance.bot
    #DiscordDatastore::DiscordUser.delete_all

    status_string = "Scanning users"
    status_message = DiscordDatastore::BotInstance.send(status_string)

    existingusers = DiscordDatastore::DiscordUser.all

    i=0
    get_users.each do |user|

        i+=1
        if i % USER_SCAN_UPDATE == 0
            status_message.edit(status_string + " -- " + i.to_s + " users")
        end

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
    status_message.edit(status_string + " -- " + i.to_s + " users (done)")
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
        'tag' => user.username + "#" + user.discriminator.to_s,
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
    #DiscordDatastore::DiscordMessage.delete_all

    status_message = DiscordDatastore::BotInstance.send("Scanning started.")
    total_messages = 0

    get_channels.each do |channel|
        next if channel.type != 0

        status_string = "Scanning #"+channel.name
        status_message.edit(status_string)

        if channel.id == SiteSetting.discord_bot_channel_id.to_i && SiteSetting.discord_ignore_bot_channel
            status_message.edit(status_string + " -- skipped")
            next # ignore bot channel
        end

        begin
            channel.history(1)
        rescue Discordrb::Errors::NoPermission
            status_message.edit(status_string + " -- skipped")
            next # cannot access channel
        end

        last_id = get_oldest_message_id channel

        if last_id == -1
            status_message.edit(status_string + " -- skipped")
            next # no messages in channel
        end

        i=0 ; temp=0    
        loop do
            messages = channel.history(HISTORY_CHUNK_LIMIT, before_id=last_id)
            if messages.length() == 0
                break
            end

            discordmessages = parse_discord_messages messages
            DiscordDatastore::DiscordMessage.upsert_all(discordmessages)
            
            i+=discordmessages.length
            temp+=discordmessages.length
            total_messages+=discordmessages.length
            if temp > MESSAGE_SCAN_UPDATE
                status_message.edit(status_string + " -- " + i.to_s + " messages")
                temp=0
            end
            last_id = messages[-1].id

            sleep HISTORY_WAIT_SECONDS
        end
        
        last_id = get_newest_message_id channel
        next if last_id == -1
        
        loop do
            messages = channel.history(HISTORY_CHUNK_LIMIT, before_id=nil, after_id=last_id)
            if messages.length() == 0
                break
            end

            discordmessages = parse_discord_messages messages
            DiscordDatastore::DiscordMessage.upsert_all(discordmessages)    
            
            i+=discordmessages.length
            temp+=discordmessages.length
            if temp > MESSAGE_SCAN_UPDATE
                status_message.edit(status_string + " -- " + i.to_s + " messages")
                temp=0
            end 
            last_id = messages[0].id

            sleep HISTORY_WAIT_SECONDS
        end

        status_message.edit(status_string + + " -- " + i.to_s + " messages (done)")
    end
    status_message.edit("Message history -- " + total_messages.to_s + " new messages (done)")

end

def update_ranks
    status_message = DiscordDatastore::BotInstance.send("Updating ranks...")

    bot = DiscordDatastore::BotInstance.bot

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
    server = get_server

    banned_ids = SiteSetting.discord_ban_id.split("|")

    users.each do |user|
        next if user.bot_account

        if banned_ids.include? user.id.to_s
            begin
                server.ban(user)
                next
            rescue
                STDERR.puts "DISCORD ERROR -----> Failed to ban user with id="+user.id.to_s+". Check permissions?"
            end
        end

        count = counts[user.id] || 0

        target_rank_id = -1
        target_rank = nil
        i=0
        requirements.each do |requirement|
            if count >= requirement.to_i
                target_rank_id = ranks[i].id
                target_rank = ranks[i]
            end
            i+=1
        end

        user_ranks = user.roles
        rank_changed = false

        ranks.each do |rank|

            if user.role? rank
                if rank.id != target_rank_id
                    user_ranks.delete(rank)
                    rank_changed = true
                end
            else
                if rank.id == target_rank_id
                    user_ranks.push(rank)
                    rank_changed = true
                end
            end
        end

        if rank_changed
            if target_rank.nil?
                DiscordDatastore::BotInstance.send("USER: " + user.name + " | UPDATED RANK: (none)" )
            else
                DiscordDatastore::BotInstance.send("USER: " + user.name + " | UPDATED RANK: " + target_rank.name)
            end
            user.set_roles user_ranks
        end

        DiscordDatastore::Verifier.verify_from_discord(user.id)
    end

    status_message.edit("Updating ranks -- (done)")
end
