import Controller from "@ember/controller";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class AdminDiscordController extends Controller {
  channels_loaded = false;
  messages_loaded = false;
  current_page = 1;
  filter_channel = "";
  searched_user_id = "";
  searched_username = "";
  searched_discord_username = "";
  ranks = null;
  channels = null;
  messages = null;
  stats = null;

  init() {
    super.init(...arguments);
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
        this.set("ranks", result.discord_ranks);
      })
      .catch(popupAjaxError);
  }

  fetchChannels() {
    let params = "";
    if (this.searched_user_id.length > 0) {
      params += "?user_id=" + this.searched_user_id;
    }

    this.set("channels_loaded", false);
    ajax("/discord/channels.json" + params)
      .then((result) => {
        this.set("channels", result.discord_channels);
        this.set("channels_loaded", true);
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

    this.set("messages_loaded", false);
    ajax("/discord/messages.json?" + params)
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
  onChangeSearchTermForUsername(username) {
    this.set("searched_username", username.length ? username : null);

    ajax("/u/" + username + ".json")
      .then((userResult) => {
        this.set("searched_user_id", userResult.user.id.toString());

        ajax("/discord/users.json?user_id=" + this.searched_user_id)
          .then((result) => {
            if (result.discord_users.length === 0) {
              this.set("searched_discord_username", "");
            } else {
              this.set(
                "searched_discord_username",
                "@" + result.discord_users[0].tag,
              );
            }
            this.fetchMessages();
            this.fetchChannels();
          })
          .catch(popupAjaxError);
      })
      .catch(popupAjaxError);
  }
}
