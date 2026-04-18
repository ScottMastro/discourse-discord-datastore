# discourse-discord-datastore — Known Issues

Review snapshot: 2026-04-18. Organized by severity. File paths are relative to the plugin root unless noted.

**Resolved so far:** #1 CSRF/auth on badge_collect, #2 ranks IDOR, #3 template URL XSS, #4 admin controller guard, #5 `&` typo, #6 `send` shadowing, #7 `+ +` typo, #8 `find` raise in `member_join`, #9 boot-time SiteSetting capture, #10 bot thread in every process (gated to `Sidekiq.server?`), #11 first-message scope bug.

## Critical

### 1. CSRF + missing auth on badge-grant endpoint
- **Where:** `plugin.rb:66` routes `get "/discord/badge_collect"`; handler `app/controllers/discord_ranks_controller.rb:119` (`collect`).
- **Problem:** GET endpoint mutates state (grants a `UserBadge`) with no `requires_login` and no CSRF token. A third-party site can trigger `<img src="…/discord/badge_collect?badge=…">` against any logged-in Discourse user and auto-grant whichever badge their message count qualifies for.
- **Fix:** Switch route to `post`, add `requires_login`, verify CSRF, and enforce that `current_user` owns the linked `discord_id`.

### 2. IDOR / information disclosure on ranks endpoint
- **Where:** `app/controllers/discord_ranks_controller.rb:103` (`ranks`), helper `get_rank_info` at line 77.
- **Problem:** No `requires_login`. `user_id` is read straight from params; the handler returns that user's badge list and Discord message counts. `current_user` is also dereferenced inside `get_discord_id` without a login guard → `NoMethodError` on anonymous requests.
- **Fix:** Add `requires_login`; only allow the caller to query their own record unless staff; centralize the check in a Guardian.

### 3. XSS / unsafe URL handling in templates
- **Where:**
  - `assets/javascripts/discourse/templates/components/discord-messages.hbs:30` — `<a href={{attachment}}>` (unquoted, unvalidated, `javascript:` scheme possible).
  - `discord-messages.hbs:24` — `<img src="{{message.user_avatar}}">` from untrusted Discord avatar URLs.
- **Fix:** Quote attributes (`href="{{…}}"`), validate scheme (http/https only) server-side before persisting or when rendering.

### 4. Admin controller missing auth guard
- **Where:** `app/controllers/admin_discord_controller.rb` — no `requires_login` / staff guard in the controller itself.
- **Mitigation:** Route in `plugin.rb:61` uses `StaffConstraint.new`, so reachability is limited, but defense-in-depth is missing.

## High

### 5. `&` vs `&&` typo
- **Where:** `plugin.rb:73` — `if SiteSetting.discord_datastore_enabled & …`
- **Problem:** Bitwise `&` instead of logical `&&`. `false & nil` raises; `true & nil` returns false. Brittle boot-time check.

### 6. `send` shadowing breaks bot messaging
- **Where:** `lib/bot.rb:68` defines `self.send(content)`; `timer` (module method) calls `send "..."`.
- **Problem:** Inside a module method, bare `send` resolves to `Kernel#send`, not the module's `send`. The intended Discord message is never dispatched.
- **Fix:** Rename to `send_to_channel` (or similar) and update callers.

### 7. Guaranteed `NoMethodError` in history scan
- **Where:** `lib/bot_helper.rb:275` — `status_string + + " -- " …`
- **Problem:** Double `+` parses as unary `+@` on a String; raises `NoMethodError`.

### 8. `DiscordUser.find` raises on new joiner
- **Where:** `lib/bot_helper.rb:118` inside `member_join` callback.
- **Fix:** Use `find_by(id: user.id)` and handle nil.

### 9. SiteSetting captured at boot
- **Where:** `lib/bot.rb:4` — `MINUTES_BEFORE_RESYNC = SiteSetting.discord_minutes_before_resync`.
- **Problem:** Frozen at load; runtime setting changes have no effect.
- **Fix:** Read inside `should_sync`.

### 10. Bot thread starts in every Rails process
- **Where:** `plugin.rb:73` — `after_initialize` starts a websocket in web workers, sidekiq, rake, rails console.
- **Fix:** Gate to a single worker or run as a background job/service.

### 11. "First message" date ignores filter
- **Where:** `app/controllers/discord_messages_controller.rb:69` — `DiscordMessage.order(:date).limit(1)` not scoped to the filtered user/channel.
- **Problem:** Always returns the global first-message date.

### 12. Unbounded queries / missing pagination
- **Where:** `app/controllers/discord_users_controller.rb:44` returns all `DiscordUser` rows with no filter; `discord_messages_controller.rb:63` runs 3 unbounded COUNT queries per request; `discord_channels_controller.rb:48` counts messages per channel as N+1.
- **Fix:** Paginate, require filters, or use a single `group(:discord_channel_id).count`.

## Medium

### 13. Duplicated `get_discord_id` across controllers
- **Where:** `discord_messages_controller.rb`, `discord_channels_controller.rb`, `discord_users_controller.rb`, `discord_ranks_controller.rb` — identical ~30-line method, containing authorization logic.
- **Fix:** Extract to a Guardian (`DiscordDatastoreGuardian`) or a `Service::Base` per CLAUDE.md conventions.

### 14. Strong params not used
- Every controller reads `params[:discord_id]`, `params[:user_id]`, `params[:badge]`, `params[:channel]`, `params[:page]` without `permit`.

### 15. Split translatable strings
- **Where:** `assets/javascripts/discourse/templates/components/discord-messages.hbs:26` — literal `" in "`, `" on "`, `":"` concatenated in template. Violates CLAUDE.md "use placeholders, not split strings".
- **Fix:** One i18n key with `{{nickname}} in #{{channel}} on {{date}}:`.

### 16. Deprecated frontend patterns
- `.js.es6` files, classic `Controller.extend({})`, `{{action foo arg}}` helpers, hbs templates under `templates/`, `withPluginApi('0.8.13', …)` inside `init()`. No JSDoc per CLAUDE.md.
- Files: `controllers/discord.js.es6`, `controllers/admin-discord.js.es6`, all `templates/components/*.hbs`.

### 17. Unquoted template attributes
- `discord.hbs:30,34`, `discord-messages.hbs:30` — `href={{...}}` without quotes.

### 18. Dead / unused code
- Serializers in `app/serializers/` are unused; controllers render via `as_json.merge(...)`.
- `discord_message.rb:8` declares `has_many :discord_reactions` — no model, no migration.

### 19. Route mount at `/`
- **Where:** `plugin.rb:70` — `mount DiscordDatastore::Engine, at: "/"`.
- **Risk:** Shadows/conflicts with core Discourse paths; hard to audit.

### 20. `upsert_all` with manually-assigned IDs on `bigserial` PK
- **Where:** `lib/bot_helper.rb:237,261`; migrations `db/migrate/20220516214447_create_discord_message.rb` (and peers) create default `bigserial id`.
- **Risk:** Mixing autogenerated sequence values with explicit Discord snowflake IDs can cause sequence-collision errors on any row inserted without an explicit id.

### 21. N+1 in sync loops
- **Where:** `bot_helper.rb:50-53, 88-94` — `existingchannels.each` inside the outer loop (O(n·m)). Build a hash lookup keyed by id.

## Low

### 22. No specs
- `spec/` contains only `.gitkeep`. No Ruby tests, no JS tests.

### 23. External image fallback
- `discord_messages_controller.rb:90` hard-codes `https://i.imgur.com/wpjpoOl.png` as avatar fallback.

### 24. Pinned release-candidate gem
- `plugin.rb` pins `rest-client 2.1.0.rc1`. `rest-client` is a transitive dep of `discordrb`; forced pin fights bundler.

### 25. Explicit `class_name` missing on namespaced associations
- `app/models/discord_message.rb:6-8` — `belongs_to :discord_channel` inside `DiscordDatastore::` module. Safer to set `class_name: "DiscordDatastore::DiscordChannel"`.

### 26. Cosmetic
- `lib/bot.rb:18` — `rand(1..9999)` bot name suffix.

## Priority fix order
1. #1, #2, #3 — security.
2. #6, #7, #8 — outright runtime bugs (bot broken).
3. #5, #9, #10, #11 — correctness / operational.
4. #12, #13, #14 — API hygiene.
5. Remainder as cleanup.
