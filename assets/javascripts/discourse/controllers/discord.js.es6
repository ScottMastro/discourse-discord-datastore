import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from "discourse/lib/ajax-error";
import { iconNode } from "discourse-common/lib/icon-library";

export default Ember.Controller.extend({

  init() {
    this._super();
    let discord_icon = iconNode('fab-discord');

    this.set('current_page', 1);
    this.set('filter_channel', "");

    this.fetchRanks();
    this.fetchChannels();
    this.fetchMessages();
  },
  
  fetchRanks() {
    ajax("/discord/ranks.json?user_id=me")
      .then((result) => {
        for (let i = 0; i < result.discord_ranks.length; i++) {
          result.discord_ranks[i]["requirement_string"] = this.format_number(result.discord_ranks[i]["requirement"]);
        }
        this.set('ranks', result.discord_ranks);
      }).catch(popupAjaxError);
  },

  fetchChannels() {
    ajax("/discord/channels.json?user_id=me")
      .then((result) => {
        this.set('channels', result.discord_channels);
      }).catch(popupAjaxError);
  },

  fetchMessages() {
    var params = "&page=" + (this.current_page-1).toString()
    if (this.filter_channel.length > 0){
      params = params + "&channel=" + this.filter_channel
    }
    
    ajax("/discord/messages.json?user_id=me" + params)
      .then((result) => {
        var discord_id = result.discord_id
        if (discord_id == -1) {discord_id = null}
        this.set('discord_id', discord_id);
        
        this.set('messages', result.discord_messages);
        this.set('stats', result.stats);
      }).catch(popupAjaxError);
  },

  format_number(number){
    number = number.toString()
    if(number.endsWith("000")){
      number = number.slice(0, -3);
      number = number + "k"
    }
    if(number.endsWith("000k")){
      number = number.slice(0, -4);
      number = number + "M"
    }
    if(number.endsWith("000M")){
      number = number.slice(0, -4);
      number = number + "B"
    }
    return number
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
