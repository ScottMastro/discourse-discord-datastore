module DiscordDatastore
  class DiscordMessagesController < ApplicationController

    requires_login
    PAGE_SIZE = 20

    def index   
      Rails.logger.info 'Called DiscordMessagesController#index'

      user_id = current_user.id

      discord_id = nil
      discord_account = UserAssociatedAccount.find_by(provider_name: "discord", user_id: user_id)
      unless discord_account.nil? then
        discord_id = discord_account.user_id
      end

      unless discord_id.nil? then
    
        page = params[:page].to_i || 0
        channel = 0
        if params[:channel]
          channel = params[:channel].to_i
        end

        messages = DiscordDatastore::DiscordMessage.where(discord_user_id: discord_id)

        if channel != 0
          messages = messages.where(discord_channel_id: channel)
        end
        
        total_messages = messages.length
        total_30_day = messages.where(date: (Date.today - 30.days)..Date.today).length
        total_7_day = messages.where(date: (Date.today - 7.days)..Date.today).length

        first = "-"
        if total_messages > 0
          first = DiscordDatastore::DiscordMessage.order(:date).where(discord_user_id: discord_id).limit(1)
          first = first[0].date.strftime('%d %b %Y')
        end

        messages = messages.order(date: :desc).offset(page * PAGE_SIZE).limit(PAGE_SIZE)
        messages = messages.includes(:discord_user).includes(:discord_channel)

        messages = messages.map { |msg| msg.as_json.merge({
          :channel_name => msg.discord_channel.name,
          :user_nickname => msg.discord_user.nickname,
          :user_tag => msg.discord_user.tag,
          :user_avatar => msg.discord_user.avatar,
          #avoid javascript rounding issues
          :id => msg.id.to_s,
          :discord_user_id => msg.discord_user_id.to_s,
          :discord_channel_id => msg.discord_channel_id.to_s
        }) }

        stats ={
          :total => total_messages,
          :total_monthly => total_30_day,
          :total_weekly => total_7_day,
          :first_message => first
        }

        render json: {discord_id: discord_id, discord_messages: messages, stats: stats }
      else
        render json: {discord_id: 0 }
      end
    end

    def admin
      Rails.logger.info 'Called DiscordMessagesController#index2'

      if ! current_user.staff?
        render json: { "error": "permission_denied" }
      else

        page = params[:page].to_i || 0
        channel = nil
        if params[:channel]
          channel = params[:channel].to_i
        end

        discord_id = nil
        if params[:discord_id]
          discord_id = params[:discord_id].to_i
        end

        messages = DiscordDatastore::DiscordMessage.order(date: :desc)
        unless discord_id.nil? then
          messages = messages.where(discord_user_id: discord_id)
        end
        unless channel.nil? then
          messages = messages.where(discord_channel_id: channel)
        end
        
        total_messages = messages.length
        total_30_day = messages.where(date: (Date.today - 30.days)..Date.today).length
        total_7_day = messages.where(date: (Date.today - 7.days)..Date.today).length

        first = "-"
        if total_messages > 0
          first = DiscordDatastore::DiscordMessage.order(:date).limit(1)
          first = first[0].date.strftime('%d %b %Y')        
        end

        messages = messages.offset(page * PAGE_SIZE).limit(PAGE_SIZE)
        messages = messages.includes(:discord_user).includes(:discord_channel)

        messages = messages.map { |msg| 
          json=msg.as_json
          if msg.discord_user.nil? == false
            json=json.merge({
              :user_nickname => msg.discord_user.nickname,
              :user_tag => msg.discord_user.tag,
              :user_avatar => msg.discord_user.avatar
              })
          else
            json=json.merge({
              #missing user or discord welcome message?
              :user_nickname => "???",
              :user_avatar => "https://i.imgur.com/wpjpoOl.png"
              })
          end

          json = json.merge({
            :channel_name => msg.discord_channel.name,
            #avoid javascript rounding issues
            :id => msg.id.to_s,
            :discord_user_id => msg.discord_user_id.to_s,
            :discord_channel_id => msg.discord_channel_id.to_s
            }) 
          
          json
        }

        stats ={
          :total => total_messages,
          :total_monthly => total_30_day,
          :total_weekly => total_7_day,
          :first_message => first
        }

        render json: { discord_messages: messages, stats: stats }
      end
    end

  end
end

