import Controller from "@ember/controller";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class DiscordController extends Controller {
  @service currentUser;

  is_staff = false;
  id_loaded = false;
  channels_loaded = false;
  messages_loaded = false;
  discord_id = "";
  discord_username = "";
  current_page = 1;
  filter_channel = "";
  ranks = null;
  channels = null;
  messages = null;
  stats = null;

  init() {
    super.init(...arguments);

    this.set("is_staff", !!this.currentUser?.staff);

    this.fetchID();
    this.fetchRanks();
    this.fetchChannels();
    this.fetchMessages();
  }

  fetchID() {
    this.set("id_loaded", false);
    this.set("discord_id", "");
    ajax("/discord/users.json?user_id=me")
      .then((result) => {
        if (result.discord_users.length > 0) {
          this.set("discord_id", result.discord_users[0].id);
          this.set("discord_username", "@" + result.discord_users[0].tag);
        }
        this.set("id_loaded", true);
      })
      .catch(popupAjaxError);
  }

  fetchRanks() {
    ajax("/discord/ranks.json?user_id=me")
      .then((result) => this.set("ranks", result.discord_ranks))
      .catch(popupAjaxError);
  }

  fetchChannels() {
    this.set("channels_loaded", false);
    ajax("/discord/channels.json?user_id=me")
      .then((result) => {
        this.set("channels", result.discord_channels);
        this.set("channels_loaded", true);
      })
      .catch(popupAjaxError);
  }

  fetchMessages() {
    let params = "&page=" + (this.current_page - 1).toString();
    if (this.filter_channel.length > 0) {
      params += "&channel=" + this.filter_channel;
    }

    this.set("messages_loaded", false);
    ajax("/discord/messages.json?user_id=me" + params)
      .then((result) => {
        this.set("messages", result.discord_messages);
        this.set("stats", result.stats);
        this.set("messages_loaded", true);
      })
      .catch(popupAjaxError);
  }

  @action
  filterChannel(channel_id) {
    this.set("current_page", 1);
    this.set("filter_channel", channel_id);
    this.fetchMessages();
  }

  @action
  nextMessagePage() {
    this.set("current_page", this.current_page + 1);
    this.fetchMessages();
  }

  @action
  prevMessagePage() {
    this.set("current_page", Math.max(this.current_page - 1, 1));
    this.fetchMessages();
  }

  @action
  collectRank(badge_id) {
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
  }
}
