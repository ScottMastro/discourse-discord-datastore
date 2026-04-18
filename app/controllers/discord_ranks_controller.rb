# frozen_string_literal: true

class DiscordDatastore::DiscordRanksController < ::ApplicationController
  include DiscordDatastore::DiscordIdResolvable

  requires_plugin "discourse-discord-datastore"
  requires_login

  def get_rank_info(user_id, discord_id)
    requirements = SiteSetting.discord_rank_count.split("|")
    names = SiteSetting.discord_rank_name.split("|")
    images = SiteSetting.discord_rank_image.split("|")
    badges = SiteSetting.discord_rank_badge_id.split("|")

    maxlen = [requirements.length, names.length, images.length, badges.length].max
    i = 0

    ranks = []
    while i < maxlen
      requirement = 999_999_999
      requirement = requirements[i].to_i if i < requirements.length

      name = "???"
      name = names[i] if i < names.length

      image = ""
      image = images[i] if i < images.length

      badge = nil
      badge = badges[i].to_i if i < badges.length

      have = false
      can_collect = false
      if !badge.nil?
        b = Badge.find(badge)
        have = (!User.find(user_id).user_badges.where(badge_id: badge).blank?) if b && !user_id.nil?

        if !have
          total_messages = DiscordDatastore::DiscordMessage.where(discord_user_id: discord_id).size
          can_collect = true if total_messages > requirement
        end
      end

      ranks.push(
        {
          requirement: requirement,
          name: name,
          image: image,
          badge: badge,
          have: have,
          can_collect: can_collect,
        },
      )

      i += 1
    end

    ranks
  end

  def ranks
    discord_id = resolve_discord_id

    user_id = nil
    if params[:user_id] == "me"
      user_id = current_user.id
    elsif params[:user_id]
      requested_id = params[:user_id].to_i
      if current_user.staff? || requested_id == current_user.id
        user_id = requested_id
      else
        return render json: { discord_ranks: [] }
      end
    end

    ranks = get_rank_info(user_id, discord_id)

    render json: { discord_ranks: ranks }
  end

  def collect
    badge = nil
    badge = params[:badge].to_i if params[:badge]

    if badge.nil?
      render json: { result: "failed: no badge specified" }
    else
      user_id = current_user.id
      discord_id = nil

      discord_account = UserAssociatedAccount.find_by(provider_name: "discord", user_id: user_id)
      discord_id = discord_account.provider_uid unless discord_account.nil?

      if discord_id.nil?
        render json: { result: "failed: no associated discord_id found" }
      else
        ranks = get_rank_info(user_id, discord_id)

        target_rank = nil
        ranks.each { |rank| target_rank = rank if rank[:badge] == badge }

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
