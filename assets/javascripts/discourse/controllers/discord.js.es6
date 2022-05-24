export default Ember.Controller.extend({
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
