import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from "discourse/lib/ajax-error";
import { iconNode } from "discourse-common/lib/icon-library";

export default Ember.Controller.extend({

  init() {
    this._super();
    let discord_icon = iconNode('fab-discord');

    this.set('current_page', 1);
    this.set('filter_channel', "");
    this.set('searched_user_id', "");
    this.set('searched_username', "");
    
    this.fetchRanks();
    this.fetchChannels();
    this.fetchMessages();
  },

  fetchRanks() {
    ajax("/discord/ranks.json")
      .then((result) => {
        for (let i = 0; i < result.discord_ranks.length; i++) {
          result.discord_ranks[i]["requirement_string"] = this.format_number(result.discord_ranks[i]["requirement"]);
        }
        this.set('ranks', result.discord_ranks);
      }).catch(popupAjaxError);
  },

  fetchChannels() {
    var params = ""
    if (this.searched_user_id.length > 0){
      params = params + "?user_id=" + this.searched_user_id
    }

    ajax("/discord/channels.json" + params)
      .then((result) => {
        this.set('channels', result.discord_channels);
      }).catch(popupAjaxError);
  },

  fetchMessages() {
    var params = "page=" + (this.current_page-1).toString()
    if (this.filter_channel.length > 0){
      params = params + "&channel=" + this.filter_channel
    }
    if (this.searched_user_id.length > 0){
      params = params + "&user_id=" + this.searched_user_id
    }

    ajax("/discord/messages.json?" + params)
      .then((result) => {
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

    onChangeSearchTermForUsername(username){
      this.set("searched_username", username.length ? username : null);

      ajax("/u/"+username+".json")
      .then((result) => {

        this.set('searched_user_id', result.user.id.toString());

        ajax("/discord/users.json?user_id="+this.searched_user_id)
        .then((result) => {
          
          if(result.discord_users.length ==0){
            this.set("searched_discord_username", "");
          }
          else{
            this.set("searched_discord_username", "@"+result.discord_users[0].tag);      
          }

          this.fetchMessages()
          this.fetchChannels()

        }).catch(popupAjaxError);
      }).catch(popupAjaxError);

    }
  }
});
