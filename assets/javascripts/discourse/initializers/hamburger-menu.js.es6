import { withPluginApi } from 'discourse/lib/plugin-api';

export default {
  name: 'discord-inits',
  initialize(container) {
    const siteSettings = container.lookup("site-settings:main");
    if (!siteSettings.discord_datastore_enabled) return;

    withPluginApi('0.8.13', api => {
      api.decorateWidget("hamburger-menu:generalLinks", function(helper) {
        return {href: "/discord", rawLabel: I18n.t('discord_datastore.hamburger_menu_label')}
      });
    });
  }
};