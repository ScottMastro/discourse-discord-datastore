# frozen_string_literal: true

class DiscordDatastore::DiscordController < ::ApplicationController

  def index
    render json: { name: "discord", description: "user" }
  end

  def check
    badges = SiteSetting.discord_rank_badge.split("|")

    have = []
    badges.each do |badge|
      b=Badge.find(badge.to_i)
      have.append( !current_user.user_badges.where(badge_id: badge).blank? )
    end

    render json: { have: have, badges: badges }
    
  end

  def badge
    Rails.logger.info 'Called DiscordController#badge'

    result="success"
    
    begin
      badge_id = params[:badge]
  
      #current_user.associated_accounts
      #todo
      user_id=366068461027459073
    rescue 
      result="param_error"
    end

    begin
      total_messages = DiscordDatastore::DiscordMessage.where(discord_user_id: user_id).length
    rescue 
      result="query_error"
    end

    begin
      badges = SiteSetting.discord_rank_badge.split("|")
      i = badges.index(badge_id)
      requirement = SiteSetting.discord_rank_count.split("|")[i].to_i
    rescue 
      result="site_setting_error"
    end  

    begin
      if requirement <= total_messages
        BadgeGranter.grant(Badge.find(badge_id.to_i), current_user)
      else
        result="insufficient_message_total"
      end
    rescue 
      result="site_setting_error"
    end  

    render json: { result: result }
  end
end
