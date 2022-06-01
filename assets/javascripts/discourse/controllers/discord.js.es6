export default Ember.Controller.extend({

  init() {
    this._super();
    this.set('messages', []);
    this.set('channels', []);
    this.set('channel_lengths', []);

    this.fetchMessages();
    this.fetchChannels();
    console.log(this.channel_lengths)
    this.set('currentPage', 1);
  },

  fetchMessages() {
    this.store.findAll('discordMessage')
      .then(result => {
        for (const message of result.content) {
          this.messages.pushObject(message);
        }
      })
      .catch(console.error);
  },
  fetchChannels() {
    this.store.findAll('discordChannel')
      .then(result => {
        for (const channel of result.content) {
          this.channels.pushObject(channel);
        }
        console.log(result)

      this.channel_lengths = result.discord_channel_lengths;
      })
      .catch(console.error);
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

    getChannelNameByID(id){
      console.log(id);
      for (channel in this.channels) {
        console.log(channel);
        if (channel.id == id){
          return(channel.name);
        }
      }
      return("unknown");
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
