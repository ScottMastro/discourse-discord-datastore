import { apiInitializer } from "discourse/lib/api";

export default apiInitializer((api) => {
  api.setAdminPluginIcon("discourse-discord-datastore", "fab-discord");
});
