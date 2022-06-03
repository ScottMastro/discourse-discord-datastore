import DiscourseRoute from "discourse/routes/discourse";
import { ajax } from 'discourse/lib/ajax';

export default DiscourseRoute.extend({

  model() {
    return ajax('/discord_messages.json');
  },
  renderTemplate() {
    this.render('admin/discord');
  }
});
