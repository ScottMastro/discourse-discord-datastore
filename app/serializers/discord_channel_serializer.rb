# frozen_string_literal: true

module DiscordDatastore 
  class DiscordChannelSerializer < ApplicationSerializer
    attributes :id,
               :name,
               :voice,
               :position
  end
end
