import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from "discourse/lib/ajax-error";
import { iconNode } from "discourse-common/lib/icon-library";

export default Ember.Controller.extend({

  init() {
    this._super();
    let discord_icon = iconNode('fab-discord');

    this.set('messages', []);
    this.set('channels', []);
    this.set('stats', []);
    this.set('ranks', []);

    this.fetchMessages();
    this.fetchChannels();
    this.set('current_page', 1);
    this.set('filter_channel', "0");

    this.parseRankSettings();
  },

  fetchMessages() {
    ajax("/discord_messages.json")
      .then((result) => {
        for (const message of result.discord_messages) {
          this.messages.pushObject(message);
        }
        this.stats = result.stats;
        for (let i = 0; i < this.ranks.length; i++) {
          var missing = this.stats["total"] < this.ranks[i]["count_values"] ? "missing-rank" : "";
          this.ranks[i]["missing"] = missing;
        }
      }).catch(popupAjaxError);
  },

  fetchChannels() {
    ajax("/discord_channels.json")
      .then((result) => {
        for (const channel of result.discord_channels) {
          this.channels.pushObject(channel);
        }
      }).catch(popupAjaxError);
  },

  parseRankSettings() {
    var ids = this.siteSettings.discord_rank_id.split("|");
    var imgs = this.siteSettings.discord_rank_image.split("|");
    var counts = this.siteSettings.discord_rank_count.split("|");
    var count_values = this.siteSettings.discord_rank_count.split("|");
    var badges = this.siteSettings.discord_rank_badge.split("|");

    for (let i = 0; i < counts.length; i++) {
      if(counts[i].endsWith("000")){
        counts[i] = counts[i].slice(0, -3);
        counts[i] = counts[i] + "k"
      }
      if(counts[i].endsWith("000k")){
        counts[i] = counts[i].slice(0, -4);
        counts[i] = counts[i] + "M"
      }
      if(counts[i].endsWith("000M")){
        counts[i] = counts[i].slice(0, -4);
        counts[i] = counts[i] + "B"
      }
    }

    var n = Math.min(ids.length, imgs.length, counts.length)

    for (let i = 0; i < n; i++) {
      var rank = {"id": ids[i], "img": imgs[i], "count": counts[i], "count_values":count_values[i]}
      this.ranks.pushObject(rank)
    }
  },

  actions: {

    filterChannel(channel_id) {
      this.set('current_page', 1);
      this.set('messages', []);
      this.set('filter_channel', channel_id);
      console.log('/discord_messages.json?channel='+channel_id)
      ajax('/discord_messages.json?channel='+channel_id)
      .then((result) => {
        for (const message of result.discord_messages) {
          this.messages.pushObject(message);
        }
      }).catch(popupAjaxError);
    },

    nextMessagePage(){
      this.set('current_page', this.current_page+1);

      this.set('messages', []);
      ajax('/discord_messages.json?channel='+this.filter_channel + '&page=' + (this.current_page-1).toString())
      .then((result) => {
        for (const message of result.discord_messages) {
          this.messages.pushObject(message);
        }
      }).catch(popupAjaxError);
    },

    prevMessagePage(){
      if (this.current_page == 1){
        return
      }
      this.set('current_page', this.current_page-1);
      this.set('messages', []);
      ajax('/discord_messages.json?channel='+this.filter_channel + '&page=' + (this.current_page-1).toString())
      .then((result) => {
        for (const message of result.discord_messages) {
          this.messages.pushObject(message);
        }
      }).catch(popupAjaxError);

    },
  }
});
