import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from "discourse/lib/ajax-error";
import { iconNode } from "discourse-common/lib/icon-library";

export default Ember.Controller.extend({

  init() {
    this._super();
    let discord_icon = iconNode('fab-discord');

    this.set('messages', []);
    this.set('channels', []);
    this.set('ranks', []);

    this.fetchMessages();
    this.fetchChannels();
    this.set('current_page', 1);
    this.set('filter_channel', "0");

    this.parseRankSettings();
  },

  fetchMessages() {
    ajax("/admin/discord_messages.json")
      .then((result) => {
        for (const message of result.discord_messages) {
          this.messages.pushObject(message);
        }
        this.set('stats', result.stats);
      }).catch(popupAjaxError);
  },

  fetchChannels() {
    ajax("/admin/discord_channels.json")
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
      var rank = {"id": ids[i], "img": imgs[i], "count": counts[i]}
      this.ranks.pushObject(rank)
    }
  },

  actions: {

    filterChannel(channel_id) {
      this.set('current_page', 1);
      this.set('messages', []);
      this.set('filter_channel', channel_id);
      ajax('/admin/discord_messages.json?channel='+channel_id)
      .then((result) => {
        for (const message of result.discord_messages) {
          this.messages.pushObject(message);
        }
      }).catch(popupAjaxError);
    },

    createDiscordMessage(content) {
      if (!content) {
        return;
      }

      const discordMessage = this.store.createRecord('discordMessage', {
        id: Date.now(),
        content: content
      });

      discordMessage.save()
        .then(console.log)
        .catch(console.error);
    },

    nextMessagePage(){
      this.set('current_page', this.current_page+1);

      this.set('messages', []);
      ajax('/admin/discord_messages.json?channel='+this.filter_channel + '&page=' + (this.current_page-1).toString())
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
      ajax('/admin/discord_messages.json?channel='+this.filter_channel + '&page=' + (this.current_page-1).toString())
      .then((result) => {
        for (const message of result.discord_messages) {
          this.messages.pushObject(message);
        }
      }).catch(popupAjaxError);

    },

    onChangeSearchTermForUsername(username){
      this.set("searched_username", username.length ? username : null);
    }

  }
});
