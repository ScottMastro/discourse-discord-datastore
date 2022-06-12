module DiscordDatastore
  class DiscordMessagesController < ApplicationController

    requires_login
    PAGE_SIZE = 20

    def get_discord_id(params)
      
      if params[:discord_id]
        if current_user.staff?
          return params[:discord_id].to_i
        end

        discord_account = UserAssociatedAccount.find_by(provider_name: "discord", user_id: current_user.id)
        if discord_account.nil?
          return -1
        end
        if discord_account.id.to_s == params[:discord_id]
          return params[:discord_id].to_i
        end

        return -1
      end

      if params[:user_id]
        if params[:user_id] == "me"
          params[:user_id] = current_user.id

        elsif ! current_user.staff? && current_user.id != params[:user_id].to_i
          return -1
        end

        discord_account = UserAssociatedAccount.find_by(provider_name: "discord", user_id: params[:user_id].to_i)
        if discord_account.nil?
          return -1
        end
          return discord_account.id.to_i
      end
    end
      
    def messages   

      discord_id = get_discord_id params

      if discord_id.nil? && ! current_user.staff?
        render json: { discord_messages: [] }
      else

        page = 0
        if params[:page]
          page = params[:page].to_i
        end

        messages = DiscordDatastore::DiscordMessage.all

        if ! discord_id.nil?
          messages = DiscordDatastore::DiscordMessage.where(discord_user_id: discord_id)
        end
        if params[:channel]
          messages = messages.where(discord_channel_id: params[:channel].to_i)
        end
          
        total_messages = messages.length
        total_30_day = messages.where(date: (Date.today - 30.days)..Date.today).length
        total_7_day = messages.where(date: (Date.today - 7.days)..Date.today).length

        first = "-"
        if total_messages > 0
          first = messages.order(:date).limit(1)
          first = first[0].date.strftime('%d %b %Y')
        end

        messages = messages.order(date: :desc).offset(page * PAGE_SIZE).limit(PAGE_SIZE)
        messages = messages.includes(:discord_user).includes(:discord_channel)
  
        messages = messages.map { |msg| 
          json=msg.as_json
          if msg.discord_user.nil? == false
            json=json.merge({
              :channel_name => msg.discord_channel.name,
              :user_nickname => msg.discord_user.nickname,
              :user_tag => msg.discord_user.tag,
              :user_avatar => msg.discord_user.avatar
              })
          else
            #missing user
            json=json.merge({
              :user_nickname => "???",
              :user_tag => "???#???",
              :user_avatar => "https://i.imgur.com/wpjpoOl.png"
              })
          end

          #avoid javascript rounding
          json = json.merge({
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

        render json: {discord_id: discord_id.to_s, discord_messages: messages, stats: stats }
      end
    end
  end
end