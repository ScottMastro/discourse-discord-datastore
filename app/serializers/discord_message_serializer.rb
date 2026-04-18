# frozen_string_literal: true

module DiscordDatastore
  class DiscordMessageSerializer < ApplicationSerializer
    SAFE_URL_SCHEMES = %w[http https].freeze
    MISSING_AVATAR = "https://i.imgur.com/wpjpoOl.png"

    attributes :id,
               :discord_user_id,
               :discord_channel_id,
               :content,
               :date,
               :attachments,
               :channel_name,
               :user_nickname,
               :user_tag,
               :user_avatar

    def id
      object.id.to_s
    end

    def discord_user_id
      object.discord_user_id.to_s
    end

    def discord_channel_id
      object.discord_channel_id.to_s
    end

    def attachments
      (object.attachments || []).filter_map { |url| self.class.safe_http_url(url) }
    end

    def channel_name
      object.discord_channel&.name
    end

    def user_nickname
      object.discord_user&.nickname || "???"
    end

    def user_tag
      object.discord_user&.tag || "???#???"
    end

    def user_avatar
      if object.discord_user.nil?
        MISSING_AVATAR
      else
        self.class.safe_http_url(object.discord_user.avatar)
      end
    end

    def self.safe_http_url(url)
      return nil if url.blank?
      uri = URI.parse(url.to_s)
      SAFE_URL_SCHEMES.include?(uri.scheme) ? url.to_s : nil
    rescue URI::InvalidURIError
      nil
    end
  end
end
