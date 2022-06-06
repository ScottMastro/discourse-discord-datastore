# frozen_string_literal: true

module DiscordDatastore 
  class DiscordChannelSerializer < ApplicationSerializer
    attributes :id,
               :name,
               :voice,
               :permissions,
               :position
  end
end
