# DREADHUNTER (Trickster Arts, Steam 1553710): Level Design, Mission Structure and Encounter Design

Research date: 2026-11-25. Most primary material comes from the developer's own Steam announcements and patch notes, Oct 2022 to Sep 2026. I pulled all 64 posts through the Steam News API (`api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=1553710`); individual posts are cited below by their steamcommunity announcement URL. Secondary sources are developer replies in Steam discussion threads, Steam user reviews, the press kit and the store page. I found no professional outlet review with level-design detail. The Windows Central preview only returned its headline.

**Status as of late Nov 2026:** All four story acts are out (Act IV shipped 2026-09-21), but the game is still in Early Access. Asked on 2026-11-18 when 1.0 would arrive, the developer answered "most probably early 2027" ([Steam thread "when is 1.0 expected?"](https://steamcommunity.com/app/1553710/discussions/0/565925680440678990/)). The store lists "all four story acts, over 140 items, and replayable procedurally generated dungeons", with 77% of 148 reviews positive ("Mostly Positive") ([Steam store](https://store.steampowered.com/app/1553710/DREADHUNTER/)). The team is 2 developers ([press kit](https://tricksterarts.com/dreadhunter/press_kit.html); [v0.210 "Impactful Combat"](https://steamcommunity.com/games/1553710/announcements/detail/1803527891935346)).

---

## 1. Are levels hand-made, procedural or hybrid? Size, duration, linear vs branching, structure of a "run", connections

### Takeaway
The game is a hybrid. Every mission is one procedurally generated map ("dungeon"), assembled at load time from handcrafted rooms and arenas, with wall and bridge variants and a separate generator for caves. Each mission ends in a boss or bounty fight, then the player leaves through an exit portal back to the ship hub. There are no multi-floor runs: one mission is one generated map. The developer is explicit that it is "an RPG, no roguelite": the campaign is a list of missions per act on a starmap, which can be replayed, and each retry generates a new map.

### Cited Findings
- **Hybrid generator (developer, Dec 2022):** "The levels you see are procedurally generated, you will never play the same map twice. We have a special system that allows as having both variety and handcrafted arenas suitable for combat. We carefully defined combinations of monsters to make each encounter fun to play." — Matouš Ježek, [Steam "Gameplay Preview" (2022-12-08)](https://steamcommunity.com/games/1553710/announcements/detail/4980448574107998350)
- **Store and site wording:** "All environments in the story campaign are uniquely generated every time you enter them"; "levels are ever-changing". — [tricksterarts.com/dreadhunter](https://tricksterarts.com/dreadhunter/); [Steam store](https://store.steampowered.com/app/1553710/DREADHUNTER/)
- **Every level ends in a boss:** "Each procedurally generated level culminates in a boss fight." — [Press kit](https://tricksterarts.com/dreadhunter/press_kit.html)
- **Content at EA launch (2023-10-18):** "the first story act and around 40 items… 12 replayable, procedurally generated dungeons with bossfights and various difficulty levels including Hardcore (permadeath) mode". — [Steam "Early Access Released!"](https://steamcommunity.com/games/1553710/announcements/detail/5218041989038767556)
- **Act I scope (developer, 2023-09-26):** "Right now there are 10 unique environments, 12 missions, single planetary system for the first act." Four acts were planned. — [Steam thread "Game systems" (dev reply)](https://steamcommunity.com/app/1553710/discussions/0/3878218962826693242/)
- **Death and retry rules (developer, 2023-09-26):** "You have 3 revives, another death means mission restart and new map generated." "You can replay already finished missions." "It is an RPG, no roguelite." Items, money and XP are kept when a mission fails. — [Steam thread "Game systems"](https://steamcommunity.com/app/1553710/discussions/0/3878218962826693242/)
- **Missions select from a starmap grouped into planetary "systems" per act.** Evidence: "Starmap sound effects" ([v0.103](https://steamcommunity.com/games/1553710/announcements/detail/5742731639334722893)) and "Fix - Starmap always displaying System for Act 3 with an unlocked visual" ([v0.206](https://steamcommunity.com/games/1553710/announcements/detail/1797820624535321)). A player names Act IV's planet "Xerxes" ([Steam thread "Act 4 difficulty"](https://steamcommunity.com/app/1553710/discussions/0/565920396927424047/)).
- **Patch-note evidence of a room-based generator with a main path and side paths:**
  - "Smaller rooms in first three missions for higher enemy density" — [v0.011 (2023-10-23)](https://steamcommunity.com/games/1553710/announcements/detail/5218041989058738966)
  - "Bug fixed - rare dungeon generation fail with side paths leading to nowhere"; "occasional incorrect player spawn point placement after entering a mission" — [v0.015 (2023-11-15)](https://steamcommunity.com/games/1553710/announcements/detail/5322753221338878434)
  - "Cargo Ship mission layout improved" — [v0.014](https://steamcommunity.com/games/1553710/announcements/detail/5302486388006302571)
  - "Room sizes and objects positions revised"; "continuously improving map layouts for a smoother flow, adjusting enemy density" — [v0.017 (2023-11-29)](https://steamcommunity.com/games/1553710/announcements/detail/5395937983658337684)
  - "New rooms" — [v0.109 (2024-10-25)](https://steamcommunity.com/games/1553710/announcements/detail/6212245217911859726)
  - "we've added new systems to our procedural generator to enhance environmental variety and enemy density. With more rooms in the mix, navigating the terrain and engaging in combat are even more fun!"; "Many new rooms added"; "New wall variations added" — [v0.202 "Environments - Round 4" (2025-03-12)](https://steamcommunity.com/games/1553710/announcements/detail/1794014851393099)
  - "Plenty of new rooms have been added, along with a new system for smarter procedural generation"; "New procedural systems for generating cave-like environments"; "New bridge variations" — [v0.203 "Caves" (2025-03-20)](https://steamcommunity.com/games/1553710/announcements/detail/1794102528310606)
  - "Additional room variability" — [v0.213 (2025-08-21)](https://steamcommunity.com/games/1553710/announcements/detail/1808601382438594)
  - "Improved loading progress during dungeon generation" — [v0.222 (2026-06-07)](https://steamcommunity.com/games/1553710/announcements/detail/1834602721195892)
  - Act IV recap: "Many new rooms added"; "Improved old environments" — [Steam "ACT IV – FULL STORY!" (2026-09-21)](https://steamcommunity.com/games/1553710/announcements/detail/1844115010501968)
- **Entry and exit:** the player arrives by drop pod ("Fix - Drop pod reappearing during respawn", [v0.222](https://steamcommunity.com/games/1553710/announcements/detail/1834602721195892)) and leaves through an exit portal ("black screen after player's death while entering the exit portal", [v0.013](https://steamcommunity.com/games/1553710/announcements/detail/5288974951215029513); "Improved exit mission and enter ship portal sounds", [v0.213](https://steamcommunity.com/games/1553710/announcements/detail/1808601382438594)).
- **Map size and exploration (players):** "Huge, totally vacant rooms with a couple of indestructible barrels in the corner" (FasterRiver, Oct 2023, launch build). A spawn bug "teleports you to the furthest central south part of a levels map… back tracking to clear rooms or unexplored areas" (Khorne on the Cob, Mar 2025). — [Steam reviews (top rated)](https://steamcommunity.com/app/1553710/reviews/?browsefilter=toprated). One player mentions choosing to "fully explore the map every mission" (Salix, Oct 2023) — [Steam "Feedback" thread](https://steamcommunity.com/app/1553710/discussions/0/3879346999818270475/)
- **Session length:** "you could play 10 minutes or 3 hours, up to you" ([RM] Thunderhunt, Oct 2023) — [Steam reviews](https://steamcommunity.com/app/1553710/reviews/?browsefilter=toprated)
- **Campaign length growth:** Act II brought "+100% more story content and doubled the game time" ([Act II is live! 2024-05-06](https://steamcommunity.com/games/1553710/announcements/detail/5766372999957679372)). Act III added "+50% game time" ([Act III is live! 2025-02-19](https://steamcommunity.com/games/1553710/announcements/detail/1792116353155890)).
- **Minimap and stills (my own observation):** I viewed screenshots saved by another researcher in `stills/dreadhunter/` (provenance not recorded; they look like Steam store screenshots). In station interiors the minimap shows blocky polygonal rooms with 45° corners, joined by short connectors. Forest and cave maps show winding, branching organic lines. This matches the patch note "Minimap has different lines for cave-like environemnts" ([v0.202](https://steamcommunity.com/games/1553710/announcements/detail/1794014851393099)).

### Inferences
- Inferred: the generator is a room/tile assembler. It places handcrafted rooms and arenas, joins them with corridors or bridges, and builds a critical path to the boss with optional side branches ("side paths leading to nowhere" was a failure case). Cave biomes use a different, more organic generator since Mar 2025.
- Inferred: the "run" unit is a single mission map of roughly one session-chunk. The roguelike element is limited to map regeneration on retry, 3 revives per mission, and an optional Hardcore permadeath mode. Gear, XP and money persist (ARPG-style meta-progression).
- Inferred from the scope numbers (10 environments for 12 missions in Act I): most missions get their own environment theme, so environment is tied to mission, not randomized per run.

### Gaps
- I found no stated map dimensions, room counts per mission or typical mission duration in minutes. No source gives a clear number.
- Mission counts for Acts II to IV are not stated. Only the relative game-time growth (+100%, +50%) is published.
- I found no developer write-up of the generator's algorithm (graph-based or not, room-template count, how arenas are tagged).

---

## 2. Level geometry: chokepoints, corridors vs arenas, verticality, destructibles, hazards, secrets, side rooms, chests and how loot is found

### Takeaway
Layouts are rooms and arenas joined by corridors, with room size used as a deliberate lever on enemy density (rooms were shrunk in the first three missions). There is modest verticality: stairs, bridges and elevation changes inside missions, plus a separate boss arena you dash into. Destructibles (barrels, explosive tanks, boxes, vending machines that drop money and health) and biome hazards (burning pools, explosive barrels, fires and meteors in Act IV, floating mines) were added over time. There are no secret rooms. The developer deliberately avoided hidden passages. Loot comes from chests placed in rooms, enemy and boss drops and mission bounties, and chests are marked on the map and minimap.

### Cited Findings
- **Room size tunes density:** "Mission one rooms sizes were reduced, I just shrinked the ones in mission 2 and 3." — Trickster Arts dev reply, 2023-10-24, [Steam "Feedback" thread](https://steamcommunity.com/app/1553710/discussions/0/3879346999818270475/). Also "Smaller rooms in first three missions for higher enemy density" — [v0.011](https://steamcommunity.com/games/1553710/announcements/detail/5218041989058738966)
- **Handcrafted arenas inside generated maps:** "handcrafted arenas suitable for combat" — [Gameplay Preview (2022-12-08)](https://steamcommunity.com/games/1553710/announcements/detail/4980448574107998350)
- **Scale aimed at a 3 m mech:** players pilot "3m/10ft mechs" ([press kit](https://tricksterarts.com/dreadhunter/press_kit.html)). Patch notes: "New stairs in environments with more realistic scale for better perception of Dreadhunter's size" ([v0.013](https://steamcommunity.com/games/1553710/announcements/detail/5288974951215029513)); "Smaller barrels and boxes with more realistic scale"; "scaling various environmental objects for a better perception of Dreadhunter's size" ([v0.017](https://steamcommunity.com/games/1553710/announcements/detail/5395937983658337684)).
- **Elevation and verticality (indirect evidence):**
  - "Fixed walls in some environments flickering when changing elevation" — [v0.202](https://steamcommunity.com/games/1553710/announcements/detail/1794014851393099)
  - "New bridge variations added to environments" — [v0.203](https://steamcommunity.com/games/1553710/announcements/detail/1794102528310606)
  - "Fix - Walkability for some walls in the Temple environment" — [v0.221 (2026-05-10)](https://steamcommunity.com/games/1553710/announcements/detail/1832065502819768)
  - "Bug fixed - broken player movement after dashing into final boss arena" — [v0.012](https://steamcommunity.com/games/1553710/announcements/detail/5229301621575588711)
  - In a station still (`shot_15`) I saw raised platforms and ledges with railings above the main floor (my observation).
- **Destructibles:**
  - "new vending machines have been added to some environments that drop money and health pickups upon destruction" — [v0.017](https://steamcommunity.com/games/1553710/announcements/detail/5395937983658337684)
  - "Fix - Electro guns not destroying explosive tanks" — [v0.111](https://steamcommunity.com/games/1553710/announcements/detail/1784506358975923)
  - "Tightened constraints for targeting destructible objects with Melee attacks" — [v0.203](https://steamcommunity.com/games/1553710/announcements/detail/1794102528310606)
  - "Random repositioning of the player after destroying barrels with Melee weapons" — [v0.208](https://steamcommunity.com/games/1553710/announcements/detail/1800991756344143)
  - Launch-build criticism of "a couple of indestructible barrels in the corner" (FasterRiver, Oct 2023) — [Steam reviews](https://steamcommunity.com/app/1553710/reviews/?browsefilter=toprated)
- **Environmental hazards:**
  - In Sep 2023 the developer said hazards had been tested in their previous game MONOLISK but were not a current focus; "floating mines" were used in combat instead — [Steam "Game systems" thread](https://steamcommunity.com/app/1553710/discussions/0/3878218962826693242/)
  - Jan 2024: "Environmental hazards - Burning pools added in Gate mission - Explosive barrels added in Factory mission" — [v0.020](https://steamcommunity.com/games/1553710/announcements/detail/5519792046252688415)
  - Act IV (Sep 2026, player): "The Burnt Forest level has way too many hazards with both fires and meteors." — [Steam "Act 4 difficulty" thread](https://steamcommunity.com/app/1553710/discussions/0/565920396927424047/)
  - Design intent: "while you're zooming around, the environment itself is part of the combat too" — [Steam "ARPG Combat Innovation" (2024-12-16)](https://steamcommunity.com/games/1553710/announcements/detail/1785774543666984)
  - Cosmetic or ambient touches: ember sparks in Gate ([v0.018](https://steamcommunity.com/games/1553710/announcements/detail/5395938616809852384)); electric effects in the first mission ([v0.104](https://steamcommunity.com/games/1553710/announcements/detail/5969041959964310981)); liquid steel in Foundry ([v0.106](https://steamcommunity.com/games/1553710/announcements/detail/6250522009512659101)); dynamic grass and trees with wind ([v0.216](https://steamcommunity.com/games/1553710/announcements/detail/1816849002016511)). 80.lv covered grass that reacts to player and enemy movement ([80.lv, search-result summary only](https://80.lv/articles/check-out-this-smooth-unity-made-grass-animation-in-indie-rpg/)).
- **Secrets and keys:** asked about secret rooms and locked gates needing backtracking (Oct 2023), the developer said there were no secret rooms yet, that hidden passages had slowed the experience in testing, that keys were used in their previous game, and that they would see how the map generator handles locked-gate backtracking — [Steam "Feedback" thread](https://steamcommunity.com/app/1553710/discussions/0/3879346999818270475/)
- **Chests and loot visibility:**
  - "game got chests, game got bosses and sorta mini bosses" (rasabt, Feb 2024) — [Steam reviews](https://steamcommunity.com/app/1553710/reviews/?browsefilter=toprated)
  - "Chest and item drop icons on the overlay map (not yet on minimap…)" — [v0.011](https://steamcommunity.com/games/1553710/announcements/detail/5218041989058738966)
  - "Highlight effect on chests" — [v0.012](https://steamcommunity.com/games/1553710/announcements/detail/5229301621575588711)
  - "the minimap… finally shows chests, item drops, bosses, and more" — [v0.206 (2025-04-26)](https://steamcommunity.com/games/1553710/announcements/detail/1797820624535321)
  - Players asked to see unopened chests after the miniboss, cleared areas and missed rooms. The developer said map panning was not possible on controller — [Steam "Feedback" thread](https://steamcommunity.com/app/1553710/discussions/0/3879346999818270475/)
- **Map reveal:** "Another mod has been added that allows your helmets to increase your Map Reveal radius" — [v0.017](https://steamcommunity.com/games/1553710/announcements/detail/5395937983658337684)
- **Other loot sources:**
  - Mods "you collect in missions" — [v0.011](https://steamcommunity.com/games/1553710/announcements/detail/5218041989058738966)
  - "First boss also drops Level 2 gun" — [v0.011](https://steamcommunity.com/games/1553710/announcements/detail/5218041989058738966)
  - "Mission bounties are now affected by currently selected difficulty" — [v0.012](https://steamcommunity.com/games/1553710/announcements/detail/5229301621575588711)
  - "Default items don't drop in first few levels, to make initial drops more interesting" — [v0.205](https://steamcommunity.com/games/1553710/announcements/detail/1795917897358239)
  - "Adjusted drops from bosses on Melee hits" — [v0.218](https://steamcommunity.com/games/1553710/announcements/detail/1819386365102123)
  - Ammo and health drops scale with difficulty — [v0.101](https://steamcommunity.com/games/1553710/announcements/detail/5768625435390872259)

### Inferences
- Inferred: the generator gives no lock-and-key or secret layer. Exploration value comes from side rooms holding chests, mods and fights, which are shown on the map, so "full clear vs beeline to boss" is the main exploration choice.
- Inferred: elevation is used as traversal texture (stairs, bridges, ledges) and possibly as arena framing, not as a combat-height system. No source mentions height advantage, jumping between levels or falling.
- Inferred: chokepoints are an emergent product of room-plus-corridor assembly, not a documented design pillar. One Act IV complaint ("heavy tier enemies in thight corners") shows tight spaces combined with heavy enemies are a known difficulty driver.

### Gaps
- The phrase the user quoted from a review ("dashing through different ground levels") was not found in any source I could reach. Steam reviews showed only 10 per page, and an exact-phrase web search returned nothing. Elevation evidence above is indirect.
- I found no source describing corridor widths, door types, whether doors lock or how arena boundaries are signalled outside boss arenas.
- No source counts chests per map or says what they contain (items vs mods vs credits).

---

## 3. Environments, biomes and campaign structure (acts, hub, missions)

### Takeaway
The campaign has four story acts, each a planetary "system" on the ship's starmap, with a list of procedurally generated missions that each end in a boss. Act I had 12 missions in 10 environments. Settings mix sci-fi interiors (ships, factories, labs, datacenter, powerplant) with organic or alien places (caves, hive, nest, temple, forest). The hub is the player's ship, which holds the market, modding table, stash, trophy room and NPC dialogue. Difficulty tiers mean replaying the same campaign with stronger enemies.

### Cited Findings
- **Named environments, from the "Environments" overhaul rounds (Oct 2024):** Gate, Antenna, Factory, Laboratory, Cave, Temple, Hive, Foundry, Military ship, Barracks, Powerplant, Tech Factory, Fortress, Ship (tutorial), Cargo Ship, Pirate Ship, Tunnels, Datacenter, Nest — [v0.107](https://steamcommunity.com/games/1553710/announcements/detail/6350729003504572715); [v0.108](https://steamcommunity.com/games/1553710/announcements/detail/6931694080295810923); [v0.109](https://steamcommunity.com/games/1553710/announcements/detail/6212245217911859726). "New Cargo Ship mission environment" was added in Mar 2024 ([v0.023](https://steamcommunity.com/games/1553710/announcements/detail/5749481331440643886)).
- **Act IV settings (player, Sep 2026):** "The missions on the planet Xerxes with the tree guradians levels…"; "The Burnt Forest level…" — [Steam "Act 4 difficulty" thread](https://steamcommunity.com/app/1553710/discussions/0/565920396927424047/)
- **Art direction:** "gradually shifting from simple colors and surfaces to richer materials and objects" — [v0.107](https://steamcommunity.com/games/1553710/announcements/detail/6350729003504572715). Also: "we felt that non-sci-fi maps needed significant improvement… all cave-like environments finally look more natural!" — [v0.203](https://steamcommunity.com/games/1553710/announcements/detail/1794102528310606). Gamepressure describes the style as "somewhat cartoonish, but at the same time rather gloomy" — [gamepressure](https://gamepressure.com/games/dreadhunter/z36490)
- **Hub ship:**
  - Modding and stash are "accessible from the modding table on Dreadhunter's ship" — [v0.014](https://steamcommunity.com/games/1553710/announcements/detail/5302486388006302571)
  - Market for selling and buying "on your ship" — [v0.013](https://steamcommunity.com/games/1553710/announcements/detail/5288974951215029513)
  - Trophy room: "Collection of killed Dreads on Dreadhunter's ship" — [v0.208](https://steamcommunity.com/games/1553710/announcements/detail/1800991756344143)
  - "npc conversations happen on bridge, kinda you mini-hub (the only hub)" (rasabt) — [Steam reviews](https://steamcommunity.com/app/1553710/reviews/?browsefilter=toprated)
- **Release timeline:**
  - Announced 2022-10-05 — [Gematsu](https://gematsu.com/2022/10/twin-stick-shooter-action-rpg-dreadhunter-announced-for-pc)
  - Early Access and Act I, 2023-10-18, "After 3.5 years in development" — [EA Released](https://steamcommunity.com/games/1553710/announcements/detail/5218041989038767556)
  - Act II, 2024-05-06 — [Act II is live!](https://steamcommunity.com/games/1553710/announcements/detail/5766372999957679372)
  - Act III, 2025-02-19 — [Act III is live!](https://steamcommunity.com/games/1553710/announcements/detail/1792116353155890)
  - Act IV "FULL STORY", 2026-09-21, with a price cut — [Act IV](https://steamcommunity.com/games/1553710/announcements/detail/1844115010501968)
  - 1.0 "most probably early 2027" — [1.0 thread](https://steamcommunity.com/app/1553710/discussions/0/565925680440678990/)
  - Endgame is "still to be decided based on success of this round of early access" (Sep 2026) — [Endgame thread](https://steamcommunity.com/app/1553710/discussions/0/565920396927426714/)
- **Original plan vs reality:** the store promised about 12 months of Early Access ([store](https://store.steampowered.com/app/1553710/DREADHUNTER/)); in 2023 the developer said "1-2 years" ([Game systems](https://steamcommunity.com/app/1553710/discussions/0/3878218962826693242/)). At Act IV: "It took us 3 years to get here, even though the original plan was to finish in just one year." — [Act IV](https://steamcommunity.com/games/1553710/announcements/detail/1844115010501968)
- **Difficulty as campaign replay:**
  - Modes include Hardcore permadeath ([EA Released](https://steamcommunity.com/games/1553710/announcements/detail/5218041989038767556)) and Normal, Hard and Nightmare (reviews and threads)
  - "Hard difficulty is now unlocked from the start" (Mar 2025) — [v0.202](https://steamcommunity.com/games/1553710/announcements/detail/1794014851393099)
  - A critical review says moving up a difficulty resets story progress and "it's still the same level as before and drops the same level stuff… just enemy stats are boosted" — [Tyrian Mollusk review (Jun 2025, updated 2026)](https://steamcommunity.com/id/tyrianmollusk/recommended/1553710)
- **Named missions and set pieces in patch notes:**
  - "Mission 4 boss (Hongsoo extraction)", with "Hongsoo's jail destruction" — [v0.012](https://steamcommunity.com/games/1553710/announcements/detail/5229301621575588711); [v0.018](https://steamcommunity.com/games/1553710/announcements/detail/5395938616809852384)
  - "Save Scientist mission fight", with a "Minimap target indicator" — [v0.205](https://steamcommunity.com/games/1553710/announcements/detail/1795917897358239); [v0.206](https://steamcommunity.com/games/1553710/announcements/detail/1797820624535321)
  - "Cassandra arena" — [v0.215](https://steamcommunity.com/games/1553710/announcements/detail/1813041031178575)

### Inferences
- Inferred: most missions use the bounty-hunt template (find and kill a boss), with a few scripted variants such as extraction and rescue ("Hongsoo extraction", "Save Scientist"), which seem to use special objective arenas.
- Inferred: biome identity carries the variety (19+ named environments). Enemy and encounter variety lagged behind, which is the main recurring criticism (see section 4).

### Gaps
- I found no full mission list per act or per-act environment mapping, and no description of how Act II to IV systems differ structurally.
- I could not confirm whether any non-story or endgame mode (e.g. infinite dungeons) exists as of Nov 2026. The developer says endgame is undecided.

---

## 4. Encounter design: hordes, how fights start, enemy roster and roles, elites, bosses, difficulty curve

### Takeaway
Encounters are built from authored monster combinations placed in generated rooms. Enemies are fast melee-rushers and specialists (leapers, chargers, teleporters, long-range specials), with deliberately no machine-gun soldiers. Density was the most-patched variable after launch. Each mission ends with a miniboss or bounty boss. Bosses lean heavily on summoning adds ("Dreads" teleport in), which supply ammo and health but are also the main complaint ("neverending swarm of adds"). Elites were only discussed as a possible endgame feature. The difficulty curve was too flat early at launch and had a sharp spike in Act IV (Sep 2026), which was hotfixed.

### Cited Findings
- **Enemy design rules (developer, Dec 2022):** "Enemies are not only fast and deadly, some of them can reposition themselves during combat and some have special attacks. Monsters wielding a gun can also hit you hard if you'll get too close to them. Each enemy attack can be avoided by dash or simply by proper possitioning… there are no soldiers with machineguns who would simply spray bullets on you." — [Gameplay Preview](https://steamcommunity.com/games/1553710/announcements/detail/4980448574107998350)
- **Enemy design (developer, Dec 2024):** "enemies are faster and equipped with special abilities like special long-range attacks, leaps, teleports etc."; "The enemy attacks are set up so that if you stop, they will quickly hunt you down." — [ARPG Combat Innovation](https://steamcommunity.com/games/1553710/announcements/detail/1785774543666984)
- **Authored encounter composition:** "We carefully defined combinations of monsters to make each encounter fun to play." — [Gameplay Preview](https://steamcommunity.com/games/1553710/announcements/detail/4980448574107998350)
- **Density as the main tuning lever (chronological):**
  - Early-game density raised ("Smaller rooms…", [v0.011](https://steamcommunity.com/games/1553710/announcements/detail/5218041989058738966)); "Enemy density in first 3 missions significantly improved" ([v0.015](https://steamcommunity.com/games/1553710/announcements/detail/5322753221338878434))
  - "2 new enemy types + 1 larger variant… significantly enhance enemy density in the first two acts… can be especially unforgiving if you pause" ([v0.111, 2024-11-27](https://steamcommunity.com/games/1553710/announcements/detail/1784506358975923))
  - Generator changes "to enhance… enemy density" ([v0.202](https://steamcommunity.com/games/1553710/announcements/detail/1794014851393099))
  - Player at launch: "stages 1 and 2 on Normal could use a bit more mob spawns" ([Feedback thread](https://steamcommunity.com/app/1553710/discussions/0/3879346999818270475/))
- **Horde framing:** "Plough through hordes of deadly monsters" ([dev site](https://tricksterarts.com/dreadhunter/)); "swarms of screeching monsters" ([store](https://store.steampowered.com/app/1553710/DREADHUNTER/)); "cannon fodder appearing in wholesale quantities" ([gamepressure](https://gamepressure.com/games/dreadhunter/z36490)). A critic says the opposite: "Much of the time is spent fighting very few enemies in very few ways" ([Tyrian Mollusk](https://steamcommunity.com/id/tyrianmollusk/recommended/1553710)). The developer distances the game from hundreds-of-kills-per-minute ARPG design while keeping it fast ([ARPG Combat Innovation](https://steamcommunity.com/games/1553710/announcements/detail/1785774543666984)).
- **How fights start:** enemies are placed in the map and engage on sight. "Charging horned enemies can no longer charge right when they see you" ([v0.221](https://steamcommunity.com/games/1553710/announcements/detail/1832065502819768)). A spawn bug put the player "outside the play area, with enemies on the same spot" ([Feedback thread, Nov 2023](https://steamcommunity.com/app/1553710/discussions/0/3879346999818270475/)). Pacing per one reviewer: "you load in, you dunk some small mobs, you then dunk some medium mobs, you then dunk their dad aka the boss, get the goodies and extract" ([Steam reviews](https://steamcommunity.com/app/1553710/reviews/?browsefilter=toprated)).
- **Named enemies and roles (partial):**
  - "Dreads" is the in-game name for the monsters (passim)
  - Fiend, a melee attacker: "Fiend melee attack 33% slower" ([v0.213](https://steamcommunity.com/games/1553710/announcements/detail/1808601382438594))
  - Meteorbug ([v0.110](https://steamcommunity.com/games/1553710/announcements/detail/1783872411988187))
  - "Charging horned enemies" ([v0.221](https://steamcommunity.com/games/1553710/announcements/detail/1832065502819768))
  - Launch-review description: "Generally bug zombie" ([reviews](https://steamcommunity.com/app/1553710/reviews/?browsefilter=toprated))
  - New enemy batches: Act II ([Act II](https://steamcommunity.com/games/1553710/announcements/detail/5766372999957679372)), Nov 2024 (2 types + larger variant), Act III, Jan 2026 ("2 new enemy types", [v0.219](https://steamcommunity.com/games/1553710/announcements/detail/1822556746163833)), Act IV ([Act IV](https://steamcommunity.com/games/1553710/announcements/detail/1844115010501968))
- **Crowd and physics rules:**
  - "Larger and heavier enemies are now not being blocked by the smaller ones" ([v0.020](https://steamcommunity.com/games/1553710/announcements/detail/5519792046252688415))
  - "Enemies are not staggered during special actions like jumps"; Stagger Strength and Duration mods ([v0.017](https://steamcommunity.com/games/1553710/announcements/detail/5395937983658337684))
  - "Complex rework of enemy behavior - making melee combat viable" ([v0.215](https://steamcommunity.com/games/1553710/announcements/detail/1813041031178575))
  - New hit, stagger and death animations ([v0.210](https://steamcommunity.com/games/1553710/announcements/detail/1803527891935346))
- **Minibosses, bosses and elites (developer, Sep 2023):** "Each mission results in a bossfight"; "There are minibosses at the end of each mission"; elites were being considered for endgame systems — [Game systems thread](https://steamcommunity.com/app/1553710/discussions/0/3878218962826693242/). Store: "Hunt down bosses for bounties in each level and face massive final bosses at the end of all story acts" ([store](https://store.steampowered.com/app/1553710/DREADHUNTER/)). Dec 2022: "The main objective of most missions is to find and hunt down a boss" ([Gameplay Preview](https://steamcommunity.com/games/1553710/announcements/detail/4980448574107998350)).
- **Boss mechanics in patch notes:**
  - "Teleport effect added when bosses spawn Dreads" ([v0.012](https://steamcommunity.com/games/1553710/announcements/detail/5229301621575588711))
  - "First boss also spawns larger enemies, to make the fight experience more interesting" ([v0.011](https://steamcommunity.com/games/1553710/announcements/detail/5218041989058738966))
  - "Banshee spawns little bit more minions to spawn more ammo drops for player"; destructible "Banshee's statue" and "Hongsoo's jail" ([v0.018](https://steamcommunity.com/games/1553710/announcements/detail/5395938616809852384))
  - Banshee gains acid grenades in phase 2 ([Feedback thread](https://steamcommunity.com/app/1553710/discussions/0/3879346999818270475/))
  - "Bosses can now be Staggered, while having 50% Debuff Duration resistance" ([v0.019](https://steamcommunity.com/games/1553710/announcements/detail/5410576585129765910))
  - "Act II bossfight - boss's rotation during attacks reduced" ([v0.102](https://steamcommunity.com/games/1553710/announcements/detail/5747233970423204598))
  - Durcaan boss flamethrower ([v0.213](https://steamcommunity.com/games/1553710/announcements/detail/1808601382438594))
  - "Collected ammo boxes in boss arenas now reappear after some delay" ([v0.222](https://steamcommunity.com/games/1553710/announcements/detail/1834602721195892))
  - "Boss fights have been spiced up as well" ([v0.215](https://steamcommunity.com/games/1553710/announcements/detail/1813041031178575))
  - Named Act I bosses and minibosses from a player: Crash 1 and 2, Kangaroo 2, Banshee statue fight, "double Daddy fight… the pressure is insane" ([Feedback thread](https://steamcommunity.com/app/1553710/discussions/0/3879346999818270475/)). A still shows a boss bar labelled "PHOBOS" (my observation, `stills/dreadhunter/shot_00.jpg`).
- **Boss criticism and praise:**
  - "up until the end battle which is always a neverending swarm of adds… blur the big fights together" ([Tyrian Mollusk](https://steamcommunity.com/id/tyrianmollusk/recommended/1553710))
  - "they were different every time in both appearance and mechanics" (Thunderhunt, [reviews](https://steamcommunity.com/app/1553710/reviews/?browsefilter=toprated))
  - Act III bosses could be knocked "around the room"; a player suggests more knockback resistance (Oct 2026, [Current state thread](https://steamcommunity.com/app/1553710/discussions/0/588439869536242794/))
  - Camera framed the boss rather than the player in an early boss fight ([Feedback thread](https://steamcommunity.com/app/1553710/discussions/0/3879346999818270475/))
- **Difficulty curve:**
  - Launch: "Nightmare feeling like Hard for a good third of the run" ([Feedback thread](https://steamcommunity.com/app/1553710/discussions/0/3879346999818270475/))
  - Act IV (Sep 2026): "way too many heavy tier enemies in thight corners"; "Bosses also spawn way too many heavy tier enemies and the fight becomes tedious"
  - The developer responded that "some fast spells can be in some cases instakill" and that they would "reduce spongy minions", then shipped update 0.953 within 3 days ([Act 4 difficulty thread](https://steamcommunity.com/app/1553710/discussions/0/565920396927424047/))
- **Encounter variety criticism:**
  - "Enemy variety is abysmal. Same mechanics required to defeat all enemies" (Oct 2023)
  - "All the maps are very similar" (May 2024)
  - "by Act 3 the same enemy encounters were starting to get stale", with the suggestion to "reuse the current enemies but give them new variations or add modifiers" (Oct 2026), alongside "The level designs are good"
  - Sources: [reviews](https://steamcommunity.com/app/1553710/reviews/?browsefilter=toprated); [Current state thread](https://steamcommunity.com/app/1553710/discussions/0/588439869536242794/)
- **Resource economy shaping encounters:**
  - "Health regenerates only when you're actively engaged in combat… The primary source of healing comes from melee kills… all require you to at least go and pick up health drops" ([ARPG Combat Innovation](https://steamcommunity.com/games/1553710/announcements/detail/1785774543666984))
  - "Full heal on Level-up"; on running out of ammo the Light gun switches to Medium ([v0.113](https://steamcommunity.com/games/1553710/announcements/detail/1787858252851924))
  - "feels almost like a top down Doom, including the finishers to get ammo, health" (rasabt, [reviews](https://steamcommunity.com/app/1553710/reviews/?browsefilter=toprated))

### Inferences
- Inferred: adds in boss fights double as the ammo and health supply, the same logic as Doom's resource-from-kills loop. That makes the add count a balance knob that easily tips into tedium (the Act IV complaints).
- Inferred: since normal-room fights are triggered by line-of-sight aggro, not arena lockdowns, the player controls engagement order and can pull enemies into corridors. Boss arenas are distinct spaces entered with a dash.
- Inferred: a lack of elite or affix enemies is a likely cause of the "samey encounters" complaints. Players explicitly ask for enemy modifiers or variants.

### Gaps
- I found no numbers for enemies on screen or per room.
- I found no confirmation of wave spawns, ambush triggers or door lockdowns in regular rooms. Boss adds teleport in, but how normal rooms populate (pre-placed vs triggered) is only indirectly evidenced.
- I could not compile a full enemy roster with roles. Patch notes name only a few enemies.
- Elites or champions are not confirmed as implemented as of Nov 2026.

---

## 5. Pacing: exploration vs combat rhythm, rest points, how a mission ends

### Takeaway
A mission runs: drop-pod arrival, push through generated rooms of small then medium enemies (with optional side-room exploration for chests), find the bounty or miniboss, fight the boss in its arena, then take the exit portal to the ship. No passive regeneration keeps players moving forward. Lulls happen between rooms, where ambient music takes over. The ship hub is the only true rest point. Death uses up one of 3 revives, and after that the mission restarts on a freshly generated map.

### Cited Findings
- **Loop:** "you load in, you dunk some small mobs, you then dunk some medium mobs, you then dunk their dad aka the boss, get the goodies and extract" (Thunderhunt, Oct 2023) — [Steam reviews](https://steamcommunity.com/app/1553710/reviews/?browsefilter=toprated)
- **Mission objective:** "The main objective of most missions is to find and hunt down a boss." — [Gameplay Preview](https://steamcommunity.com/games/1553710/announcements/detail/4980448574107998350)
- **Lulls:** "We've added an ambient soundtrack for each environment, creating a fitting atmosphere when the action settles down." — [v0.205](https://steamcommunity.com/games/1553710/announcements/detail/1795917897358239). One player says the soundtrack gets repetitive "if you choose to… fully explore the map every mission" ([Feedback thread](https://steamcommunity.com/app/1553710/discussions/0/3879346999818270475/)).
- **No camping:** "You can't simply run and wait for your health to restore… if you stop, they will quickly hunt you down." The design aims at "a state of flow" — [ARPG Combat Innovation](https://steamcommunity.com/games/1553710/announcements/detail/1785774543666984)
- **Failure and end states:** 3 revives, then restart with a new map, keeping items, money and XP ([Game systems thread](https://steamcommunity.com/app/1553710/discussions/0/3878218962826693242/)). Exit portal back to the ship ([v0.013](https://steamcommunity.com/games/1553710/announcements/detail/5288974951215029513); [v0.213](https://steamcommunity.com/games/1553710/announcements/detail/1808601382438594)).
- **Pacing criticism:**
  - "missions feel plodding and samey"; "a list of procedural missions you run down until it stops" ([Tyrian Mollusk](https://steamcommunity.com/id/tyrianmollusk/recommended/1553710))
  - The early game was sluggish until stage 3 (Salix, [Feedback thread](https://steamcommunity.com/app/1553710/discussions/0/3879346999818270475/))
  - Pacing praise: "almost perfect" (Thunderhunt)

### Inferences
- Inferred: the rhythm is "room fight → short traverse → room fight", building to a boss arena, with optional detours for loot. The game has no in-mission shops, shrines or checkpoints that I could find.

### Gaps
- I found no evidence of in-mission checkpoints, rest rooms or mid-mission events. I could not confirm whether the boss arena is gated by clearing anything (e.g. killing the miniboss first).

---

## 6. Developer statements on design philosophy, Doom influence and procedural generation; Indie Cup Europe 2024

### Takeaway
The lead designer's published philosophy centres on combat flow: fast WASD or twin-stick movement with a dash, no passive regeneration (heal by melee kills and pickups), fast enemies with leaps, teleports and ranged specials, and the environment as part of combat. Levels are framed as "procedural variety + handcrafted arenas + authored monster combinations". Doom comparisons come mostly from press, store copy and players. I found no developer text crediting Doom's level design specifically. Indie Cup Europe'24 nominated the game in three categories, and it did not appear among the winners.

### Cited Findings
- **Combat philosophy (designer Matouš Ježek, 2024-12-16):** the post explains why the team rejected point-and-click movement and automatic regeneration. The pillars are "Health Recovery Through Action", "High Mobility" ("relatively long dash with a short cooldown, enabling constant motion") and "Dynamic Enemies". The intended result: "keeps players in a state of flow". He argues that soulslike slowdowns hurt the power fantasy: "You Don't Need to Slow the Game Down". — [ARPG Combat Innovation](https://steamcommunity.com/games/1553710/announcements/detail/1785774543666984)
- **Level and encounter philosophy (Dec 2022):** procedural maps, "handcrafted arenas suitable for combat", "carefully defined combinations of monsters" — [Gameplay Preview](https://steamcommunity.com/games/1553710/announcements/detail/4980448574107998350)
- **On hidden content:** hidden passages slowed play, and keys or backtracking were under consideration (Oct 2023) — [Feedback thread](https://steamcommunity.com/app/1553710/discussions/0/3879346999818270475/)
- **Charged melee (2025-10-08):** "Soulslike melee combat, no speed and flow compromises?" — [v0.215](https://steamcommunity.com/games/1553710/announcements/detail/1813041031178575)
- **Doom and other comparisons:**
  - Windows Central headline: "'Dreadhunter' for PC looks like an unholy fusion between DOOM and Hades" ([Windows Central](https://www.windowscentral.com/gaming/pc-gaming/dreadhunter-looks-like-an-unholy-fusion-between-doom-and-hades); article body not retrievable)
  - Promotional blurb quoted on a let's-play site: "Descend into ever-evolving dungeons, where a fusion of DOOM's merciless pace meets the rogue-like allure of Hades" ([overage-gaming](https://overage-gaming.com/2023/10/27/dreadhunter-lets-play/))
  - 80.lv: combat "reminiscent of Helldivers, Doom, Path of Exile" ([80.lv, search snippet](https://80.lv/articles/check-out-this-smooth-unity-made-grass-animation-in-indie-rpg/))
  - Player: "almost like a top down Doom, including the finishers to get ammo, health" ([reviews](https://steamcommunity.com/app/1553710/reviews/?browsefilter=toprated))
- **Indie Cup Europe'24:** "Dreadhunter received nominations in 3 categories… selected from among 450 participants" — [Steam announcement 2024-07-08](https://steamcommunity.com/games/1553710/announcements/detail/5842939267350716854). Search-result summaries name the categories as Gameplay Excellence, Rising Star and Critics' Choice ([mezha.ua nominees](https://mezha.ua/en/2024/07/05/49-nominees-of-indie-cup-europe-24-festival-announced-including-two-ukrainian-games/)), and say it is not among the winners ([mezha.ua winners](https://mezha.ua/en/2024/08/16/the-winners-of-indie-cup-europe-24-have-been-announced-among-them-is-one-ukrainian-game/)). I did not open these pages directly. 80.lv covered the nominations on 2024-07-12 ([80.lv](https://80.lv/articles/check-out-this-award-winning-fast-paced-shooter-rpg/)).
- **Team and history:** "2 developers - 15+ years of experience each"; "in development since early 2020"; Unity engine (per 80.lv). Previous games have 15M+ downloads, including MONOLISK, which the developer references. — [press kit](https://tricksterarts.com/dreadhunter/press_kit.html); [Game systems thread](https://steamcommunity.com/app/1553710/discussions/0/3878218962826693242/)
- **AI disclosure:** AI tools were used for some 2D dialogue portraits and minor environment textures — [store](https://store.steampowered.com/app/1553710/DREADHUNTER/)

### Inferences
- Inferred: the "Doom" in Dreadhunter is in the combat loop (aggressive movement, resources from kills, close-range finishers), not in Doom-style hand-authored levels with keys and secrets. The developer explicitly avoided secrets and keys at launch.
- Inferred: the most transferable lessons for a similar game are:
  - Use room size as a density knob.
  - Mark chests and drops on the minimap, or players complain.
  - Generic generated maps plus a small roster read as "samey", so variety must come from enemy modifiers, set-piece arenas and biome hazards.
  - Boss add-spam used for resource supply needs careful capping.

### Gaps
- No interview or devlog that discusses level generation in depth was found. The 80.lv, Windows Central and Gematsu pieces are short news posts. I found no Indie Cup jury commentary.
- No direct developer quote about Doom, Halo, Destiny or Warframe as level-design references was found. The user's comparison to those games is not echoed in developer materials.
