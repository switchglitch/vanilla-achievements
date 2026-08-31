# Vanilla Achievements

A standalone personal achievement addon for the World of Warcraft 1.12.1 client.
It does not inspect or store the player's guild and does not require other players
to run the addon.

## Repository

The source code and release history are maintained in this GitHub repository.
For installation, use the instructions below; no development tools or private
maintenance files are required to run the addon.

## Install

1. Copy the `VanillaAchievements` folder into `Interface/AddOns`.
2. Confirm the final path is `Interface/AddOns/VanillaAchievements/VanillaAchievements.toc`.
3. Enable **Vanilla Achievements** at the character-selection AddOns screen.
4. Use `/va`, `/vach`, or `/achievements` in game.

Progress is stored per `character@realm` in `VA_DB`.

Version 0.8.5 includes the current achievement catalog, private-server-friendly
event fallbacks, and the free-position minimap launcher.

Achievements update during play. Normal Vanilla events trigger immediate checks,
and a lightweight one-second/three-second fallback scanner covers private
servers that omit those events. State-based level, money, zone, equipment, bag,
skill, reputation, and play-time milestones therefore do not wait for relogging.

## Included

- Level milestones at 5, 10, 20, 30, 40, 50, 59, and 60.
- 26 dungeon or dungeon-wing clears triggered by the final boss.
- Seven Vanilla raid clears triggered by the final encounter.
- Six outdoor world bosses.
- Class-at-60, weapon skill, secondary profession, and reputation milestones.
- Exploration, profession, reputation, wealth, loot, equipment, play-time,
  death, secret, and total-achievement milestones.
- A category browser, completion dates, filtering, progress, chat notices,
  and sequential achievement popups.
- A compact round `VA` launcher that can be Shift-dragged anywhere on screen.
  Its free-form screen position is saved between sessions.
- An original 64x64 badge for every achievement, including stylized level-number
  badges and a cracked level 59 badge.
- A user-provided `anime-wow.mp3` sound for every achievement toast.

The catalog contains 222 achievements.

Exploration milestones count distinct zones visited, with additional travel
and zone-change achievements. Historical map-fog discovery is intentionally not
used because the 1.12.1 API does not expose it reliably across private servers.

Left-click the minimap button to open the browser, right-click it to rescan the
character, and Shift-drag it to move it. Use `/vach minimap` to hide or restore
the button.

Use `/vach sound` to enable or disable achievement sounds. Use `/vach soundtest`
to play the configured cue. Sounds play when each queued toast appears,
including update and manual replays.

Genuinely new unlocks send a nearby custom emote in the form `Character has
unlocked achievement "Achievement Name"`. Login catch-ups and popup replays
never announce. Use `/vach announce` to toggle these messages. `/vach cheer`
optionally adds the character's physical cheer animation and its normal second
emote line; this is disabled by default.

New unlocks also announce the same message to the current party or raid and
guild by default. These social announcements never run for login catch-ups,
version replays, or `/vach replay`. Use `/vach social` or the visible
Party/Guild setting to toggle them.

The left side of the achievement window includes visible settings for popups,
sounds, nearby `/me` announcements, party/guild announcements, the physical
cheer, and local chat notices. The achievement list shows seven rows at a time
in one column; mouse-wheel scrolling reveals rows 8-14 within that page. Use
Previous and Next to switch between 14-item pages; a basic scrollbar controls
the seven visible rows within the current page for maximum Vanilla 1.12
compatibility. Browser buttons glow gold while hovered.

Existing characters receive achievements supported by current character state
on their first login. Each completed achievement is shown in sequence rather
than being overwritten by the next popup. This catch-up sequence runs once per
character after each addon version update. Use `/vach replay` to queue it again
manually. Historical dungeon kills, raid kills, loot, deaths, and zone visits
cannot be reconstructed by the 1.12.1 API.

## Boss aliases and private-server changes

Final-boss aliases are defined in `Catalog.lua`. If the server renames a boss,
add the exact displayed name to that achievement's alias table. Custom dungeons
and raids can be added with `RegisterBossAchievement` or by copying an existing
catalog row and assigning a new, permanent ID.

The combat-log trigger is intentionally local and guild-independent. A clear is
recorded when the client receives the final boss's hostile-death message. It
does not require a particular group size, guild, class, faction, or addon user.

## Recommended live checks

- Level-up event arguments on the private server.
- Edwin VanCleef, Ragnaros, and Kel'Thuzad death-message spelling.
- Localized clients, because fallback boss parsing includes English text.
- Item-quality caching when looting an item for the first time.
- Profession skill-line names used by the server.
- Whether the server reports all outdoor boss deaths through
  `CHAT_MSG_COMBAT_HOSTILE_DEATH`.

Use `/vach debug` before a final boss to print the exact hostile-death name seen
by the tracker. Turn it off afterward because ordinary hostile deaths are also
shown. This command is optional and does not affect normal achievement tracking.

For guild distribution, copy the complete `VanillaAchievements` folder into
`Interface/AddOns`. The `Tools` directory is only for development validation;
it is not required by the game.
