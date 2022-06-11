class DiscordDatastore::Verifier

    def self.get_server
        DiscordDatastore::BotInstance.bot.servers.each do |s|
          server_id = s[0]
          if server_id.to_s == SiteSetting.discord_server_id
            return DiscordDatastore::BotInstance.bot.servers[server_id]     
          end
        end
        return nil
    end

    def self.verify_from_discord(discord_id)
        builder = DB.build("select u.* from user_associated_accounts uaa, users u /*where*/ limit 1")
        builder.where("provider_name = :provider_name", provider_name: "discord")
        builder.where("uaa.user_id = u.id")
        builder.where("uaa.provider_uid = :discord_id", discord_id: discord_id)
    
        result = builder.query
    
        if result.size == 0 then
            
            # No profile on Discourse
            server = get_server()
            member = server.member(discord_id)
            member.roles.each do |role|
                if role.name == SiteSetting.discord_verified_rank
                    member.remove_role(role)
                end
            end
    
        else
            result.each do |t|
                self.verify_user(t)
            end
        end
    end
  
    def self.find_role(role_name)
        discord_role = nil
        server = get_server()
        server.roles.each do |role|
            if role.name == role_name then
                discord_role = role
            end
        end

        discord_role
    end
  
    def self.verify_user(user)
        discord_id = nil
    
        builder = DB.build("select uaa.provider_uid from user_associated_accounts uaa /*where*/ limit 1")
        builder.where("provider_name = :provider_name", provider_name: "discord")
        builder.where("uaa.user_id = :user_id", user_id: user.id)
        builder.query.each do |t|
            discord_id = t.provider_uid
        end
  
        unless discord_id.nil? then
            server = get_server()
            member = server.member(discord_id)
                
            if SiteSetting.discord_verified_rank != "" then
                role = self.find_role(SiteSetting.discord_verified_rank)
                unless role.nil? || (member.role? role) then
                    member.add_role(role)
                    DiscordDatastore::BotInstance.bot.send_message(SiteSetting.discord_bot_channel_id, "Verified Discourse:#{user.username}, id=#{user.id} | Discord: #{member.username}, id=#{member.id}")
                end
            end 
        end
    end
end