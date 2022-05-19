import DiscourseRoute from "discourse/routes/discourse";

export default {
  resource: 'admin.adminPlugins',
  path: '/plugins',
  map() {
    this.route('discord-datastore');
  }
};
