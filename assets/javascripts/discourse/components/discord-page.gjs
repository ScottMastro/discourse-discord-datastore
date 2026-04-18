import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";
import DiscordChannels from "./discord-channels";
import DiscordHeader from "./discord-header";
import DiscordMessages from "./discord-messages";
import DiscordRanks from "./discord-ranks";
import DiscordStats from "./discord-stats";

export default class DiscordPage extends Component {
  @service currentUser;
  @service siteSettings;

  @tracked id_loaded = false;
  @tracked channels_loaded = false;
  @tracked messages_loaded = false;
  @tracked discord_id = "";
  @tracked discord_username = "";
  @tracked current_page = 1;
  @tracked filter_channel = "";
  @tracked ranks = null;
  @tracked channels = null;
  @tracked messages = null;
  @tracked stats = null;

  constructor() {
    super(...arguments);
    this.fetchID();
    this.fetchRanks();
    this.fetchChannels();
    this.fetchMessages();
  }

  get is_staff() {
    return !!this.currentUser?.staff;
  }

  fetchID() {
    this.id_loaded = false;
    this.discord_id = "";
    ajax("/discord/users.json?user_id=me")
      .then((result) => {
        if (result.discord_users.length > 0) {
          this.discord_id = result.discord_users[0].id;
          this.discord_username = "@" + result.discord_users[0].tag;
        }
        this.id_loaded = true;
      })
      .catch(popupAjaxError);
  }

  fetchRanks() {
    ajax("/discord/ranks.json?user_id=me")
      .then((result) => (this.ranks = result.discord_ranks))
      .catch(popupAjaxError);
  }

  fetchChannels() {
    this.channels_loaded = false;
    ajax("/discord/channels.json?user_id=me")
      .then((result) => {
        this.channels = result.discord_channels;
        this.channels_loaded = true;
      })
      .catch(popupAjaxError);
  }

  fetchMessages() {
    let params = "&page=" + (this.current_page - 1).toString();
    if (this.filter_channel.length > 0) {
      params += "&channel=" + this.filter_channel;
    }

    this.messages_loaded = false;
    ajax("/discord/messages.json?user_id=me" + params)
      .then((result) => {
        this.messages = result.discord_messages;
        this.stats = result.stats;
        this.messages_loaded = true;
      })
      .catch(popupAjaxError);
  }

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

  collectRank = (badge_id) => {
    ajax("/discord/badge_collect.json", {
      type: "POST",
      data: { badge: badge_id },
    })
      .then((result) => {
        if (result.result === "success") {
          for (let i = 0; i < this.ranks.length; i++) {
            if (this.ranks[i].badge === badge_id) {
              this.ranks[i].have = true;
            }
          }
        }
      })
      .catch(popupAjaxError);
  };

  <template>
    <DiscordHeader />

    {{#if this.is_staff}}
      <br />
      <a class="discord-admin-url" href="/admin/discord">
        {{i18n "discord_datastore.view_admin_url_text"}}
        ➚
      </a>
    {{/if}}

    <div class="discord-data">
      {{#if this.discord_id}}
        <h3>
          <div class="discord-username-header">
            {{i18n "discord_datastore.verified_username"}}: ✅
            {{this.discord_username}}
          </div>
        </h3>
        <hr />
        <DiscordStats
          @messages_loaded={{this.messages_loaded}}
          @stats={{this.stats}}
        />
        <hr />
        <DiscordRanks
          @ranks={{this.ranks}}
          @collectible={{1}}
          @collectRank={{this.collectRank}}
        />
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
      {{else}}
        {{#if this.id_loaded}}
          <div class="discord-join-info">
            <div class="discord-join-box">
              {{i18n "discord_datastore.warning_no_account_found"}}
            </div>
            <br />
            {{#if this.siteSettings.discord_invite_url}}
              <h2>
                1.
                <a href={{this.siteSettings.discord_invite_url}}>
                  {{i18n "discord_datastore.join_discord_message"}}
                </a>
              </h2>
            {{else}}
              <h2>1. {{i18n "discord_datastore.join_discord_message"}}</h2>
            {{/if}}
            <h2>
              2.
              <a href="/my/preferences/account">
                {{i18n "discord_datastore.connect_discord_message"}}
              </a>
            </h2>
          </div>
        {{/if}}
      {{/if}}
    </div>
  </template>
}
