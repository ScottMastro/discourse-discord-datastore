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

  @tracked idLoaded = false;
  @tracked channelsLoaded = false;
  @tracked messagesLoaded = false;
  @tracked discordId = "";
  @tracked discordUsername = "";
  @tracked currentPage = 1;
  @tracked filterChannelId = "";
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

  collectRank = async (badgeId) => {
    try {
      const result = await ajax("/discord/badge_collect.json", {
        type: "POST",
        data: { badge: badgeId },
      });
      if (result.result === "success") {
        for (let i = 0; i < this.ranks.length; i++) {
          if (this.ranks[i].badge === badgeId) {
            this.ranks[i].have = true;
          }
        }
      }
    } catch (e) {
      popupAjaxError(e);
    }
  };

  constructor() {
    super(...arguments);
    if (!this.currentUser) {
      return;
    }
    this.fetchID();
    this.fetchRanks();
    this.fetchChannels();
    this.fetchMessages();
  }

  get isStaff() {
    return !!this.currentUser?.staff;
  }

  async fetchID() {
    this.idLoaded = false;
    this.discordId = "";
    try {
      const result = await ajax("/discord/users.json?user_id=me");
      if (result.discord_users.length > 0) {
        this.discordId = result.discord_users[0].id;
        this.discordUsername = "@" + result.discord_users[0].tag;
      }
      this.idLoaded = true;
    } catch (e) {
      popupAjaxError(e);
    }
  }

  async fetchRanks() {
    try {
      const result = await ajax("/discord/ranks.json?user_id=me");
      this.ranks = result.discord_ranks;
    } catch (e) {
      popupAjaxError(e);
    }
  }

  async fetchChannels() {
    this.channelsLoaded = false;
    try {
      const result = await ajax("/discord/channels.json?user_id=me");
      this.channels = result.discord_channels;
      this.channelsLoaded = true;
    } catch (e) {
      popupAjaxError(e);
    }
  }

  async fetchMessages() {
    let params = "&page=" + (this.currentPage - 1).toString();
    if (this.filterChannelId.length > 0) {
      params += "&channel=" + this.filterChannelId;
    }

    this.messagesLoaded = false;
    try {
      const result = await ajax("/discord/messages.json?user_id=me" + params);
      this.messages = result.discord_messages;
      this.stats = result.stats;
      this.messagesLoaded = true;
    } catch (e) {
      popupAjaxError(e);
    }
  }

  <template>
    {{#if this.currentUser}}
      {{#if this.isStaff}}
        <a class="discord-admin-url" href="/admin/discord">
          {{i18n "discord_datastore.view_admin_url_text"}}
          ➚
        </a>
      {{/if}}

      <div class="discord-data">
        <DiscordHeader />
        {{#if this.discordId}}
          <h3>
            <div class="discord-username-header">
              {{i18n "discord_datastore.verified_username"}}: ✅
              {{this.discordUsername}}
            </div>
          </h3>
          <hr />
          <DiscordStats
            @messagesLoaded={{this.messagesLoaded}}
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
        {{else}}
          {{#if this.idLoaded}}
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
    {{else}}
      <div class="discord-data discord-anon">
        <DiscordHeader />
        <p class="discord-anon-intro">
          {{i18n "discord_datastore.anon_intro"}}
        </p>
        <div class="discord-anon-actions">
          {{#if this.siteSettings.discord_invite_url}}
            <a
              class="discord-anon-btn discord-anon-btn--invite"
              href={{this.siteSettings.discord_invite_url}}
            >
              {{i18n "discord_datastore.join_discord_message"}}
            </a>
          {{/if}}
          <a class="discord-anon-btn discord-anon-btn--login" href="/login">
            {{i18n "discord_datastore.anon_login_message"}}
          </a>
        </div>
      </div>
    {{/if}}
  </template>
}
