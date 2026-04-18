# frozen_string_literal: true
module DiscordDatastore
  class DiscordMessagesController < ApplicationController
    requires_plugin "discourse-discord-datastore"
    requires_login
    PAGE_SIZE = 20
    SAFE_URL_SCHEMES = %w[http https].freeze

    def self.safe_http_url(url)
      return nil if url.blank?
      uri = URI.parse(url.to_s)
      SAFE_URL_SCHEMES.include?(uri.scheme) ? url.to_s : nil
    rescue URI::InvalidURIError
      nil
    end

    def get_discord_id(params)
      if params[:discord_id]
        return params[:discord_id].to_i if current_user.staff?

        discord_account =
          UserAssociatedAccount.find_by(provider_name: "discord", user_id: current_user.id)
        return -1 if discord_account.nil?
        return params[:discord_id].to_i if discord_account.provider_uid.to_s == params[:discord_id]

        return -1
      end

      if params[:user_id]
        if params[:user_id] == "me"
          params[:user_id] = current_user.id
        elsif !current_user.staff? && current_user.id != params[:user_id].to_i
          return -1
        end

        discord_account =
          UserAssociatedAccount.find_by(provider_name: "discord", user_id: params[:user_id].to_i)
        return -1 if discord_account.nil?
        discord_account.provider_uid.to_i
      end
    end

    def messages
      discord_id = get_discord_id params

      if discord_id.nil? && !current_user.staff?
        render json: { discord_messages: [] }
      else
        page = 0
        page = params[:page].to_i if params[:page]

        messages = DiscordDatastore::DiscordMessage.order(date: :desc)

        messages = messages.where(discord_channel_id: params[:channel].to_i) if params[:channel]
        messages = messages.where(discord_user_id: discord_id) if !discord_id.nil?

        total_messages = messages.size
        total_30_day = messages.where(date: (Date.today - 30.days)..Date.today).size
        total_7_day = messages.where(date: (Date.today - 7.days)..Date.today).size

        first = "-"
        if total_messages > 0
          first_message = messages.reorder(date: :asc).limit(1).first
          first = first_message.date.strftime("%d %b %Y") if first_message
        end

        messages = messages.offset(page * PAGE_SIZE).limit(PAGE_SIZE)
        messages = messages.includes(:discord_channel).includes(:discord_user)

        messages =
          messages.map do |msg|
            json = msg.as_json
            if msg.discord_user.nil? == false
              json =
                json.merge(
                  {
                    channel_name: msg.discord_channel.name,
                    user_nickname: msg.discord_user.nickname,
                    user_tag: msg.discord_user.tag,
                    user_avatar: self.class.safe_http_url(msg.discord_user.avatar),
                  },
                )
            else
              #missing user
              json =
                json.merge(
                  {
                    user_nickname: "???",
                    user_tag: "???#???",
                    user_avatar: "https://i.imgur.com/wpjpoOl.png",
                  },
                )
            end

            json["attachments"] = (json["attachments"] || []).filter_map do |a|
              self.class.safe_http_url(a)
            end

            #avoid javascript rounding
            json =
              json.merge(
                {
                  id: msg.id.to_s,
                  discord_user_id: msg.discord_user_id.to_s,
                  discord_channel_id: msg.discord_channel_id.to_s,
                },
              )

            json
          end

        stats = {
          total: total_messages,
          total_monthly: total_30_day,
          total_weekly: total_7_day,
          first_message: first,
        }

        render json: { discord_id: discord_id.to_s, discord_messages: messages, stats: stats }
      end
    end
  end
end
