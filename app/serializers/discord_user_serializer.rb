# frozen_string_literal: true

module DiscordDatastore 
  class DiscordUserSerializer < ApplicationSerializer
    attributes :id,
               :tag,
               :nickname,
               :avatar,
               :verified,
               :discourse_account_id
  end
end
