# frozen_string_literal: true

RSpec.describe DiscordDatastore::DiscordMessagesController do
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

  describe "#messages" do
    it "requires login" do
      get "/discord/messages.json"
      expect(response.status).to eq(403)
    end

    it "returns empty when non-staff asks for another user's messages" do
      sign_in(user)
      link_discord(other_user, 99_999)
      get "/discord/messages.json", params: { user_id: other_user.id }
      expect(response.status).to eq(200)
      expect(response.parsed_body["discord_messages"]).to eq([])
    end

    it "returns own messages when user_id=me" do
      sign_in(user)
      link_discord(user, 42)
      DiscordDatastore::DiscordChannel.create!(id: 1, name: "general", position: 0)
      DiscordDatastore::DiscordUser.create!(id: 42, tag: "scott#0001", nickname: "scott")
      DiscordDatastore::DiscordMessage.create!(
        id: 1,
        discord_user_id: 42,
        discord_channel_id: 1,
        content: "hi",
        date: Time.current,
        attachments: [],
      )

      get "/discord/messages.json", params: { user_id: "me" }
      expect(response.status).to eq(200)
      expect(response.parsed_body["discord_messages"].length).to eq(1)
      expect(response.parsed_body["discord_messages"].first["content"]).to eq("hi")
    end

    it "filters attachment URLs to http(s) schemes" do
      sign_in(user)
      link_discord(user, 7)
      DiscordDatastore::DiscordChannel.create!(id: 2, name: "general", position: 0)
      DiscordDatastore::DiscordUser.create!(id: 7, tag: "a#1", nickname: "a")
      DiscordDatastore::DiscordMessage.create!(
        id: 2,
        discord_user_id: 7,
        discord_channel_id: 2,
        content: "",
        date: Time.current,
        attachments: %w[
          https://cdn.discordapp.com/attachments/ok.png
          javascript:alert(1)
          data:text/html,<script>alert(1)</script>
        ],
      )

      get "/discord/messages.json", params: { user_id: "me" }
      attachments = response.parsed_body["discord_messages"].first["attachments"]
      expect(attachments).to eq(["https://cdn.discordapp.com/attachments/ok.png"])
    end

    it "scopes first_message stat to the filtered user" do
      sign_in(user)
      link_discord(user, 8)
      DiscordDatastore::DiscordChannel.create!(id: 3, name: "g", position: 0)
      DiscordDatastore::DiscordUser.create!(id: 8, tag: "b#1", nickname: "b")
      DiscordDatastore::DiscordUser.create!(id: 9, tag: "c#1", nickname: "c")
      older_date = 10.days.ago
      recent_date = 1.day.ago
      # Another user's older message must NOT bleed into the caller's stats.
      DiscordDatastore::DiscordMessage.create!(
        id: 10,
        discord_user_id: 9,
        discord_channel_id: 3,
        content: "older",
        date: older_date,
        attachments: [],
      )
      DiscordDatastore::DiscordMessage.create!(
        id: 11,
        discord_user_id: 8,
        discord_channel_id: 3,
        content: "mine",
        date: recent_date,
        attachments: [],
      )

      get "/discord/messages.json", params: { user_id: "me" }
      expect(response.parsed_body["stats"]["first_message"]).to eq(recent_date.strftime("%d %b %Y"))
    end
  end
end
