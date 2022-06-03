export default Ember.Controller.extend({

  init() {
    
    this._super();
    this.set('messages', []);
    this.set('channels', []);

    this.fetchMessages();
    this.fetchChannels();
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
