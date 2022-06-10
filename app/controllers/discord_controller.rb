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
      badges = SiteSetting.discord_rank_badge.split("|")
      requirements = SiteSetting.discord_rank_count.split("|")
    rescue 
      result="site_setting_error"
    end  

    begin
      badge_id = params[:badge]
      i = badges.index(badge_id)
      requirement = requirements[i].to_i

      discord_id = nil
      discord_account = UserAssociatedAccount.find_by(provider_name: "discord", user_id: current_user.id)
      unless discord_account.nil? then
        discord_id = discord_account.user_id
      end

    rescue 
      result="param_error"
    end

    begin
      total_messages = DiscordDatastore::DiscordMessage.where(discord_user_id: discord_id).length
    rescue 
      result="query_error"
    end

    begin
      if result == "success"
        if requirement <= total_messages
          BadgeGranter.grant(Badge.find(badge_id.to_i), current_user)
        else
          result="insufficient_message_total"
        end
      end
    rescue 
      result="site_setting_error"
    end  

    render json: { result: result }
  end
end
