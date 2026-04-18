import Component from "@glimmer/component";
import { service } from "@ember/service";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";

export default class DiscordHeader extends Component {
  @service siteSettings;

  <template>
    {{#if this.siteSettings.discord_header_image}}
      <img
        src={{this.siteSettings.discord_header_image}}
        alt="header_image"
      />
    {{else}}
      <h1>{{icon "fab-discord"}} {{i18n "discord_datastore.user_title"}}</h1>
    {{/if}}
  </template>
}
