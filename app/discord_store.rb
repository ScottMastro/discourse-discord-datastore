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

    def remove_discord_message(message_id)
      messages = get_discord_messages()
      messages.delete(message_id)
      PluginStore.set('discord', 'discordMessages', messages)
    end

  end
end
