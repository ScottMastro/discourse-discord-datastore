class DiscordDatastore::Crossposter

    def self.crosspost(topic, user)

        if SiteSetting.discord_crosspost_channel_id.nil? || topic[:category_id].nil?
            return
        end        
        if ! SiteSetting.discourse_crosspost_category.include? topic[:category_id].to_s
            return
        end

        DiscordDatastore::BotInstance.bot.send_message(SiteSetting.discord_crosspost_channel_id,
             "Thread created by **" + user[:username] + "**:\n" + topic.url)

    end
end