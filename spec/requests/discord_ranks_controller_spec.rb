# frozen_string_literal: true

RSpec.describe DiscordDatastore::DiscordRanksController do
  fab!(:user)
  fab!(:other_user, :user)
  fab!(:staff, :admin)

  before { SiteSetting.discord_datastore_enabled = true }

  def link_discord(user, discord_id)
    UserAssociatedAccount.create!(
      provider_name: "discord",
      user_id: user.id,
      provider_uid: discord_id.to_s,
    )
  end

  describe "#ranks" do
    it "requires login" do
      get "/discord/ranks.json", params: { user_id: "me" }
      expect(response.status).to eq(403)
    end

    it "returns empty for non-staff asking about another user" do
      sign_in(user)
      get "/discord/ranks.json", params: { user_id: other_user.id }
      expect(response.status).to eq(200)
      expect(response.parsed_body["discord_ranks"]).to eq([])
    end

    it "allows non-staff to query their own ranks" do
      sign_in(user)
      link_discord(user, 12_345)
      get "/discord/ranks.json", params: { user_id: "me" }
      expect(response.status).to eq(200)
      expect(response.parsed_body).to have_key("discord_ranks")
    end

    it "allows staff to query any user" do
      sign_in(staff)
      get "/discord/ranks.json", params: { user_id: other_user.id }
      expect(response.status).to eq(200)
    end
  end

  describe "#collect" do
    it "rejects GET (badges must not be grantable via CSRF)" do
      sign_in(user)
      get "/discord/badge_collect.json", params: { badge: 1 }
      expect(response.status).to eq(404)
    end

    it "requires login for POST" do
      post "/discord/badge_collect.json", params: { badge: 1 }
      expect(response.status).to eq(403)
    end

    it "fails when no badge specified" do
      sign_in(user)
      post "/discord/badge_collect.json"
      expect(response.parsed_body["result"]).to start_with("failed")
    end

    it "fails when no discord account linked" do
      sign_in(user)
      post "/discord/badge_collect.json", params: { badge: 1 }
      expect(response.parsed_body["result"]).to include("no associated discord_id")
    end
  end
end
