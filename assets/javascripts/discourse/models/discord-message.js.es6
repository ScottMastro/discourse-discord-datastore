import RestModel from 'discourse/models/rest';

export default RestModel.extend({
  /**
   * Required when sending PUT requests via Discourse’s store
   */
  updateProperties() {
    return this.getProperties('content');
  }
});

