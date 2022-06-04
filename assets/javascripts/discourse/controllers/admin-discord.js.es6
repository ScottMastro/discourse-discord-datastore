import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from "discourse/lib/ajax-error";

export default Ember.Controller.extend({

  init() {
    this._super();
    this.set('messages', []);
    this.set('message_total', 0);
    this.set('channels', []);
    this.set('rank_settings', []);

    this.fetchMessages();
    this.fetchChannels();
    this.set('currentPage', 1);
  
    this.parseRankSettings();
  },

  fetchMessages() {
    ajax("/admin/discord_messages.json")
      .then((result) => {
        for (const message of result.discord_messages) {
          this.messages.pushObject(message);
        }
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
      this.rank_settings.pushObject(rank)
    }
    console.log(this.rank_settings)
  },

  actions: {
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
      this.currentPage = this.currentPage+1;
      console.log(this.currentPage);
    },

    deleteDiscordMessage(message) {
      this.store.destroyRecord('discordMessage', message)
        .then(() => {
          this.messages.removeObject(message);
        })
        .catch(console.error);
    },

    onChangeSearchTermForUsername(username){
      this.set("searched_username", username.length ? username : null);
    }

    

  }
});
