export default Ember.Controller.extend({

  init() {
    this._super();
    this.set('messages', []);
    this.fetchMessages();
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
    }
  }
});
