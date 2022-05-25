# frozen_string_literal: true

module DiscordDatastore 
  class DiscordMessageSerializer < ApplicationSerializer
    attributes :id,
               :content

  end
end
