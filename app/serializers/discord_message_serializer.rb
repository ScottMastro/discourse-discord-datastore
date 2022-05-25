# frozen_string_literal: true

module DiscordDatastore 
  class DiscordMessageSerializer < ApplicationSerializer
    attributes :id,
               :author_id,
               :channel_id,
               :content,
               :date
  end
end
