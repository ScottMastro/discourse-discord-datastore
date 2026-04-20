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
  @tracked channels_loaded = false;
  @tracked messages_loaded = false;
  @tracked current_page = 1;
  @tracked filter_channel = "";
  @tracked searched_user_id = "";
  @tracked searched_username = "";
  @tracked searched_discord_username = "";
  @tracked ranks = null;
  @tracked channels = null;
  @tracked messages = null;
  @tracked stats = null;

  filterChannel = (channel_id) => {
    this.current_page = 1;
    this.filter_channel = channel_id;
    this.fetchMessages();
  };

  nextMessagePage = () => {
    this.current_page = this.current_page + 1;
    this.fetchMessages();
  };

  prevMessagePage = () => {
    this.current_page = Math.max(this.current_page - 1, 1);
    this.fetchMessages();
  };

  onChangeSearchTermForUsername = (username) => {
    this.searched_username = username.length ? username : null;

    ajax("/u/" + username + ".json")
      .then((userResult) => {
        this.searched_user_id = userResult.user.id.toString();

        ajax("/discord/users.json?user_id=" + this.searched_user_id)
          .then((result) => {
            if (result.discord_users.length === 0) {
              this.searched_discord_username = "";
            } else {
              this.searched_discord_username =
                "@" + result.discord_users[0].tag;
            }
            this.fetchMessages();
            this.fetchChannels();
          })
          .catch(popupAjaxError);
      })
      .catch(popupAjaxError);
  };

  constructor() {
    super(...arguments);
    this.fetchRanks();
    this.fetchChannels();
    this.fetchMessages();
  }

  fetchRanks() {
    ajax("/discord/ranks.json")
      .then((result) => {
        for (let i = 0; i < result.discord_ranks.length; i++) {
          result.discord_ranks[i].have = true;
        }
        this.ranks = result.discord_ranks;
      })
      .catch(popupAjaxError);
  }

  fetchChannels() {
    let params = "";
    if (this.searched_user_id.length > 0) {
      params += "?user_id=" + this.searched_user_id;
    }

    this.channels_loaded = false;
    ajax("/discord/channels.json" + params)
      .then((result) => {
        this.channels = result.discord_channels;
        this.channels_loaded = true;
      })
      .catch(popupAjaxError);
  }

  fetchMessages() {
    let params = "page=" + (this.current_page - 1).toString();
    if (this.filter_channel.length > 0) {
      params += "&channel=" + this.filter_channel;
    }
    if (this.searched_user_id.length > 0) {
      params += "&user_id=" + this.searched_user_id;
    }

    this.messages_loaded = false;
    ajax("/discord/messages.json?" + params)
      .then((result) => {
        this.messages = result.discord_messages;
        this.stats = result.stats;
        this.messages_loaded = true;
      })
      .catch(popupAjaxError);
  }

  <template>
    <div class="discord-data">
      <DiscordHeader />
      <div class="discord-data-user">
        <UserChooser
          @id="search-posted-by"
          @value={{this.searched_username}}
          @onChange={{this.onChangeSearchTermForUsername}}
          @options={{hash maximum=1 excludeCurrentUser=false}}
        />
        <div class="discord-data-user-text">
          {{i18n "discord_datastore.selected_user"}}:
          {{#if this.searched_username}}
            {{this.searched_username}}
            <div>
              {{#if this.searched_discord_username}}
                ✅
                {{this.searched_discord_username}}
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
        @messages_loaded={{this.messages_loaded}}
        @stats={{this.stats}}
      />
      <hr />
      <DiscordRanks @ranks={{this.ranks}} />
      <hr />

      <div class="discord-data-columns">
        <div class="discord-data-channels">
          <DiscordChannels
            @channels_loaded={{this.channels_loaded}}
            @channels={{this.channels}}
            @filterChannel={{this.filterChannel}}
          />
        </div>
        <div class="discord-data-messages">
          <DiscordMessages
            @messages_loaded={{this.messages_loaded}}
            @messages={{this.messages}}
            @current_page={{this.current_page}}
            @prevMessagePage={{this.prevMessagePage}}
            @nextMessagePage={{this.nextMessagePage}}
          />
        </div>
      </div>
    </div>
  </template>
}
