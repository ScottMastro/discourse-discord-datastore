# Discord Datastore Plugin for Discourse

Mirrors a Discord server's message history into your Discourse database and
surfaces it to users on a `/discord` page.

## What it does

- **Bot sync** — a [discordrb](https://github.com/shardlab/discordrb) bot
  runs inside the Discourse sidekiq process, scans channel history on start
  and on a configurable resync interval, and upserts messages, users, and
  channels into local tables.
- **`/discord` page** — logged-in users see their own Discord stats (total /
  30-day / 7-day message counts, first-message date), channel activity, and
  a paginated message history once they've connected their Discord account
  in Discourse preferences.
- **`/admin/discord`** — staff can search any user by username and inspect
  their Discord stats and messages.
- **Ranks + badges** — site settings map Discord message-count thresholds to
  Discourse badges; users can claim a badge once they cross its threshold.
- **Auto-verify** — connecting Discord on Discourse grants a configurable
  Discord role via the bot.
- **Ban list** — configured Discord IDs are auto-banned from the server on
  join.
- **`?quote` command** — returns a random past message from the caller's
  Discord history.

## Site settings

Configure under Admin → Plugins → Discord Datastore:

- `discord_bot_token`, `discord_server_id`, `discord_bot_channel_id`
- `discord_bot_command_prefix`, `discord_bot_status`
- `discord_minutes_before_resync`
- `discord_verified_rank`
- `discord_rank_name` / `discord_rank_count` / `discord_rank_image` /
  `discord_rank_badge_id` (pipe-delimited lists, one rank per index)
- `discord_ban_id` (pipe-delimited)
- `discord_header_image`, `discord_invite_url`
