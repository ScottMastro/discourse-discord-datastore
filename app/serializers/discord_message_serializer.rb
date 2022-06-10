# frozen_string_literal: true

module DiscordDatastore 
  class DiscordMessageSerializer < ApplicationSerializer
    attributes :id,
               :discord_user_id,
               :discord_channel_id,
               :content,
               :date,
               :attachments
  end
end
