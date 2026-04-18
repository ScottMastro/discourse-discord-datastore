# frozen_string_literal: true
module DiscordDatastore
  class DiscordMessagesController < ApplicationController
    include DiscordIdResolvable

    requires_plugin "discourse-discord-datastore"
    requires_login
    PAGE_SIZE = 20

    def messages
      discord_id = resolve_discord_id

      return render json: { discord_messages: [] } if discord_id.nil? && !current_user.staff?

      page = params[:page].to_i

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

      page_messages =
        messages.offset(page * PAGE_SIZE).limit(PAGE_SIZE).includes(:discord_channel, :discord_user)

      render json: {
               discord_id: discord_id.to_s,
               discord_messages:
                 ActiveModel::ArraySerializer.new(
                   page_messages,
                   each_serializer: DiscordMessageSerializer,
                 ).as_json,
               stats: {
                 total: total_messages,
                 total_monthly: total_30_day,
                 total_weekly: total_7_day,
                 first_message: first,
               },
             }
    end
  end
end
