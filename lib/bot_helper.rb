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

def upsert_channels
    existingchannels = DiscordDatastore::DiscordChannel.all
    #DiscordDatastore::DiscordChannel.delete_all
  
    get_channels.each do |channel|
        #text channel
        if channel.type == 0 
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
            'roles' => [],
            'verified' => is_verified,
            'discourse_account_id' => discourse_id,
            'created_at' => create_time,
            'updated_at'=> Time.now
        }
        DiscordDatastore::DiscordUser.upsert(discorduser)
    end
end
