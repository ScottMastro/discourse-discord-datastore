import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import icon from "discourse/helpers/d-icon";
import number from "discourse/helpers/number";
import { i18n } from "discourse-i18n";

const DiscordChannels = <template>
  <div class="discord-data-channels-header">
    <h3>{{icon "fab-discord"}} {{i18n "discord_datastore.channel_title"}}</h3>
  </div>

  {{#if @channels_loaded}}
    {{#if @channels}}
      <div class="discord-channel-list">
        {{#each @channels as |channel|}}
          <div>
            <button
              type="button"
              class="discord-channel-list-element"
              {{on "click" (fn @filterChannel channel.id)}}
            >
              <h3>#{{channel.name}}</h3>
              <div class="discord-channel-total">
                {{number channel.total}}
                <div class="discord-channel-total-text">
                  {{i18n "discord_datastore.channel_message_total"}}
                </div>
              </div>
            </button>
          </div>
        {{/each}}
      </div>
    {{else}}
      {{i18n "discord_datastore.no_channels"}}
    {{/if}}
  {{else}}
    <div class="spinner"></div>
  {{/if}}
</template>;

export default DiscordChannels;
