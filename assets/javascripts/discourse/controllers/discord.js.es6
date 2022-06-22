import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from "discourse/lib/ajax-error";
import { iconNode } from "discourse-common/lib/icon-library";
import { withPluginApi } from 'discourse/lib/plugin-api';

export default Ember.Controller.extend({

  init() {
    this._super();
    let discord_icon = iconNode('fab-discord');

    


    this.set('is_staff', false);

    withPluginApi('0.8.13', api => {
      var user = api.getCurrentUser();
      for (var i = 0; i < user.groups.length; i++) {
        if (user.groups[i].name == "staff"){
          this.set('is_staff', true);
        }
      }
    });

    this.set('current_page', 1);
    this.set('filter_channel', "");

    this.fetchID();
    this.fetchRanks();
    this.fetchChannels();
    this.fetchMessages();
  },

  fetchID() {
    this.set('id_loaded', false);

    this.set('discord_id', "");
    ajax("/discord/users.json?user_id=me")
      .then((result) => {
        if (result.discord_users.length > 0){
          this.set('discord_id', result.discord_users[0].id);
        }
        this.set('id_loaded', true);
      }).catch(popupAjaxError);
  },
  
  fetchRanks() {
    ajax("/discord/ranks.json?user_id=me")
      .then((result) => {
        this.set('ranks', result.discord_ranks);
      }).catch(popupAjaxError);
  },

  fetchChannels() {
    this.set('channels_loaded', false);

    ajax("/discord/channels.json?user_id=me")
      .then((result) => {
        this.set('channels', result.discord_channels);
        this.set('channels_loaded', true);
      }).catch(popupAjaxError);
  },

  fetchMessages() {
    var params = "&page=" + (this.current_page-1).toString()
    if (this.filter_channel.length > 0){
      params = params + "&channel=" + this.filter_channel
    }
    
    this.set('messages_loaded', false);

    ajax("/discord/messages.json?user_id=me" + params)
      .then((result) => {        
        this.set('messages', result.discord_messages);
        this.set('stats', result.stats);
        this.set('messages_loaded', true);
      }).catch(popupAjaxError);
  },

  actions: {
    filterChannel(channel_id) {
      this.set('current_page', 1);
      this.set('filter_channel', channel_id);
      this.fetchMessages()
    },

    nextMessagePage() {
      this.set('current_page', this.current_page+1);
      this.fetchMessages()
    },

    prevMessagePage() {
      this.set('current_page', Math.max(this.current_page-1, 1));
      this.fetchMessages()
    },

    collectRank(badge_id){
      ajax('/discord/badge_collect.json?badge='+badge_id.toString())
      .then((result) => {
        if (result.result == "success"){
          for (let i = 0; i < this.ranks.length; i++) {  
            if (this.ranks[i]["badge"] == badge_id){
              Ember.set(this.get('ranks').objectAt(i), 'have', true);
            }
          }
        }
      }).catch(popupAjaxError);
    }
  }
});
