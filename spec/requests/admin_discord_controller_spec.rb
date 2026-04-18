# frozen_string_literal: true

RSpec.describe DiscordDatastore::AdminDiscordController do
  fab!(:user)
  fab!(:staff) { Fabricate(:admin) }

  before { SiteSetting.discord_datastore_enabled = true }

  describe "#index" do
    it "blocks anonymous" do
      get "/admin/discord.json"
      expect(response.status).to eq(404)
    end

    it "blocks non-staff" do
      sign_in(user)
      get "/admin/discord.json"
      expect(response.status).to eq(404)
    end

    it "allows staff" do
      sign_in(staff)
      get "/admin/discord.json"
      expect(response.status).to eq(200)
    end
  end
end
