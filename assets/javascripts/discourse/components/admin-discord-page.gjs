import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { hash } from "@ember/helper";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import UserChooser from "discourse/select-kit/components/user-chooser";
import { i18n } from "discourse-i18n";
import DiscordChannels from "./discord-channels";
import DiscordHeader from "./discord-header";
import DiscordMessages from "./discord-messages";
import DiscordRanks from "./discord-ranks";
import DiscordStats from "./discord-stats";

export default class AdminDiscordPage extends Component {
  @tracked channelsLoaded = false;
  @tracked messagesLoaded = false;
  @tracked currentPage = 1;
  @tracked filterChannelId = "";
  @tracked searchedUserId = "";
  @tracked searchedUsername = "";
  @tracked searchedDiscordUsername = "";
  @tracked ranks = null;
  @tracked channels = null;
  @tracked messages = null;
  @tracked stats = null;

  filterChannel = (channelId) => {
    this.currentPage = 1;
    this.filterChannelId = channelId;
    this.fetchMessages();
  };

  nextMessagePage = () => {
    this.currentPage = this.currentPage + 1;
    this.fetchMessages();
  };

  prevMessagePage = () => {
    this.currentPage = Math.max(this.currentPage - 1, 1);
    this.fetchMessages();
  };

  onChangeSearchTermForUsername = async (username) => {
    this.searchedUsername = username.length ? username : null;

    try {
      const userResult = await ajax("/u/" + username + ".json");
      this.searchedUserId = userResult.user.id.toString();

      const result = await ajax(
        "/discord/users.json?user_id=" + this.searchedUserId
      );
      if (result.discord_users.length === 0) {
        this.searchedDiscordUsername = "";
      } else {
        this.searchedDiscordUsername = "@" + result.discord_users[0].tag;
      }
      this.fetchMessages();
      this.fetchChannels();
    } catch (e) {
      popupAjaxError(e);
    }
  };

  constructor() {
    super(...arguments);
    this.fetchRanks();
    this.fetchChannels();
    this.fetchMessages();
  }

  async fetchRanks() {
    try {
      const result = await ajax("/discord/ranks.json");
      for (let i = 0; i < result.discord_ranks.length; i++) {
        result.discord_ranks[i].have = true;
      }
      this.ranks = result.discord_ranks;
    } catch (e) {
      popupAjaxError(e);
    }
  }

  async fetchChannels() {
    let params = "";
    if (this.searchedUserId.length > 0) {
      params += "?user_id=" + this.searchedUserId;
    }

    this.channelsLoaded = false;
    try {
      const result = await ajax("/discord/channels.json" + params);
      this.channels = result.discord_channels;
      this.channelsLoaded = true;
    } catch (e) {
      popupAjaxError(e);
    }
  }

  async fetchMessages() {
    let params = "page=" + (this.currentPage - 1).toString();
    if (this.filterChannelId.length > 0) {
      params += "&channel=" + this.filterChannelId;
    }
    if (this.searchedUserId.length > 0) {
      params += "&user_id=" + this.searchedUserId;
    }

    this.messagesLoaded = false;
    try {
      const result = await ajax("/discord/messages.json?" + params);
      this.messages = result.discord_messages;
      this.stats = result.stats;
      this.messagesLoaded = true;
    } catch (e) {
      popupAjaxError(e);
    }
  }

  <template>
    <div class="discord-data">
      <DiscordHeader />
      <div class="discord-data-user">
        <UserChooser
          @id="search-posted-by"
          @value={{this.searchedUsername}}
          @onChange={{this.onChangeSearchTermForUsername}}
          @options={{hash maximum=1 excludeCurrentUser=false}}
        />
        <div class="discord-data-user-text">
          {{i18n "discord_datastore.selected_user"}}:
          {{#if this.searchedUsername}}
            {{this.searchedUsername}}
            <div>
              {{#if this.searchedDiscordUsername}}
                ✅
                {{this.searchedDiscordUsername}}
              {{else}}
                ❌
                {{i18n "discord_datastore.selected_user_not_found"}}
              {{/if}}
            </div>
          {{/if}}
        </div>
      </div>
      <hr />

      <DiscordStats
        @messagesLoaded={{this.messagesLoaded}}
        @stats={{this.stats}}
      />
      <hr />
      <DiscordRanks @ranks={{this.ranks}} />
      <hr />

      <div class="discord-data-columns">
        <div class="discord-data-channels">
          <DiscordChannels
            @channelsLoaded={{this.channelsLoaded}}
            @channels={{this.channels}}
            @filterChannel={{this.filterChannel}}
          />
        </div>
        <div class="discord-data-messages">
          <DiscordMessages
            @messagesLoaded={{this.messagesLoaded}}
            @messages={{this.messages}}
            @currentPage={{this.currentPage}}
            @prevMessagePage={{this.prevMessagePage}}
            @nextMessagePage={{this.nextMessagePage}}
          />
        </div>
      </div>
    </div>
  </template>
}
