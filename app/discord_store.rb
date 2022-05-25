class DiscordStore
  class << self

    def get_discord_messages
      PluginStore.get('discord', 'discordMessages') || {}
    end

    def add_discord_message(message_id, message)
      messages = PluginStore.get('discord', 'discordMessages') || {}
      messages[message_id] = message
      PluginStore.set('discord', 'discordMessages', messages)

      message
    end
  end
end
