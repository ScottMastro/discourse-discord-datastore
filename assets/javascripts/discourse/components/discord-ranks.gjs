import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import icon from "discourse/helpers/d-icon";
import number from "discourse/helpers/number";
import { i18n } from "discourse-i18n";

const DiscordRanks = <template>
  <div class="discord-data-rank-header">
    <h3>{{icon "fab-discord"}} {{i18n "discord_datastore.rank_title"}}</h3>
  </div>

  <div class="discord-data-rank">
    {{#each @ranks as |rank|}}
      <div class="discord-rank discord-rank-have-{{rank.have}}">
        <div class="discord-rank-img"><img src={{rank.image}} alt="" /></div>
        <div class="discord-rank-text">
          <div class="discord-rank-label">{{rank.name}}</div>
          <div class="discord-rank-count">
            {{number rank.requirement}} {{i18n "discord_datastore.messages"}}
          </div>
        </div>
        {{#if @collectible}}
          {{#if rank.badge}}
            {{#if rank.have}}
              <div class="discord-collected-button">
                {{i18n "discord_datastore.collected_rank"}}
              </div>
            {{else}}
              {{#if rank.can_collect}}
                <button
                  type="button"
                  class="discord-collect-button"
                  {{on "click" (fn @collectRank rank.badge)}}
                >
                  {{i18n "discord_datastore.collect_rank"}}
                </button>
              {{else}}
                <div class="discord-locked-button">
                  {{i18n "discord_datastore.locked_rank"}}
                </div>
              {{/if}}
            {{/if}}
          {{else}}
            <div class="discord-collect-empty"></div>
          {{/if}}
        {{/if}}
      </div>
    {{/each}}
  </div>
</template>;

export default DiscordRanks;
