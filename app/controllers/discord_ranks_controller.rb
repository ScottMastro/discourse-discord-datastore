# frozen_string_literal: true

class DiscordDatastore::DiscordRanksController < ::ApplicationController

  def get_discord_id(params)
      
    if params[:discord_id]
      if current_user.staff?
        return params[:discord_id].to_i
      end

      discord_account = UserAssociatedAccount.find_by(provider_name: "discord", user_id: current_user.id)
      if discord_account.nil?
        return -1
      end
      if discord_account.provider_uid.to_s == params[:discord_id]
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
        return discord_account.provider_uid.to_i
    end
  end
  
  def get_rank_info(user_id, discord_id)

    requirements = SiteSetting.discord_rank_count.split("|")
    names = SiteSetting.discord_rank_name.split("|")
    images = SiteSetting.discord_rank_image.split("|")
    badges = SiteSetting.discord_rank_badge_id.split("|")

    maxlen = [requirements.length, names.length, images.length, badges.length].max
    i = 0

    ranks = []
    while i < maxlen do

      requirement = 999999999
      if i < requirements.length
        requirement = requirements[i].to_i
      end

      name = "???"
      if i < names.length
        name = names[i]
      end

      image = ""
      if i < images.length
        image = images[i]
      end

      badge = nil
      if i < badges.length
        badge = badges[i].to_i
      end

      have=false
      can_collect=false
      if ! badge.nil?
        b=Badge.find(badge)
        if b && ! user_id.nil?
          have = ( ! User.find(user_id).user_badges.where(badge_id: badge).blank? )
        end

        if !have
          total_messages = DiscordDatastore::DiscordMessage.where(discord_user_id: discord_id).length
          if total_messages >requirement
            can_collect=true
          end
        end
      end

      ranks.push({
        :requirement => requirement,
        :name => name,
        :image => image,
        :badge => badge,
        :have => have,
        :can_collect => can_collect
      })

      i +=1
    end

    return ranks
  end

  def ranks

    discord_id = get_discord_id params
    
    user_id = nil
    if params[:user_id] == "me"
      user_id = current_user.id
    elsif params[:user_id]
      user_id = params[:user_id].to_i
    end

    ranks = get_rank_info(user_id, discord_id)

    render json: { discord_ranks: ranks }
  end

  def collect

    badge = nil
    if params[:badge] 
      badge = params[:badge].to_i 
    end

    if badge.nil?
      render json: { result: "failed: no badge specified" }
    else

      user_id = current_user.id
      discord_id = nil

      discord_account = UserAssociatedAccount.find_by(provider_name: "discord", user_id: user_id)
      unless discord_account.nil? then
        discord_id = discord_account.provider_uid
      end
  
      if discord_id.nil?
        render json: { result: "failed: no associated discord_id found" }
      else
        ranks = get_rank_info(user_id, discord_id)

        target_rank = nil
        ranks.each do |rank|
          if rank[:badge] == badge
            target_rank = rank
          end
        end

        if target_rank.nil?
          render json: { result: "failed: is badge id correct?" }
        else

          if target_rank[:can_collect]
            BadgeGranter.grant(Badge.find(badge), current_user)
            render json: { result: "success" }
          else
            render json: { result: "failed: insufficient message total or already collected" }
          end
        end
      end
    end
  end
end
