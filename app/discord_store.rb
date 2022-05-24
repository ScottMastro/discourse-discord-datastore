class DiscordStore
  class << self
    def add_discord_message(message_id, message)
      messages = PluginStore.get('discordMessage', 'messages') || {}
      messages[message_id] = message
      PluginStore.set('discordMessage', 'messages', messages)

      message
    end
  end
end
