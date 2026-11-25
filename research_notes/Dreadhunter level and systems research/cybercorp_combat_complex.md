# CyberCorp (Steam 1116170) vs Combat Complex (Steam 1899300): level design, missions, encounters, loot/upgrades, reception

Research date: 2026-11-25. Main sources: Steam store pages, the full Steam news/patch-note feed for both games (pulled from the public Steam News API; 100 CyberCorp posts from 2022-01 to 2026-11, 23 Combat Complex posts from 2024-06 to 2026-06), Steam user reviews (top-rated page, English), the Combat Complex pinned roadmap thread, and critic reviews (Games Asylum, NoobFeed, Rectify Gaming, TechGoggles, Entertainment Geekly, OpenCritic).

Status snapshot:
- **CyberCorp**:
  - Developer and publisher: Megame LLC.
  - Early Access: released Aug 19, 2024 on the Steam store (the dev FAQ says the "technical release" was Aug 19 at 5 PM PST and the public release Aug 20).
  - Full 1.0 release: Apr 22, 2025.
  - Steam rating: "Mostly Positive", 75% of 360 reviews.
  - Price: $14.99.
  - Last content update: Update 35 (Oct 2025). Last patch: 35.5 (Dec 2025). The studio shipped a new game, *Lord of Undead*, in Nov 2026.
  - Sources: [Steam store](https://store.steampowered.com/app/1116170/), [FAQ 2024-08-19](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6909171012610572433), [Game Price 2024-08-17](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6909171012603278983), [Bundle post 2026-11-18](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1849827110425457).
- **Combat Complex**:
  - Developer and publisher: Spherical Horse Studios.
  - Early Access since Oct 4, 2024. Price $7.99. A free demo shares save files with the full game.
  - Steam rating: "Very Positive", 81% of 66 reviews.
  - Single-player only.
  - Still in Early Access. The latest update found is 2026-06-27. The 1.0 release was planned for "Fall 2025" and has slipped: the pinned roadmap (header "Updated April 19, 2026") still says 1.0 is due "next year".
  - Sources: [Steam store](https://store.steampowered.com/app/1899300/), [Roadmap 2024-09-16](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6250522009527845924), [Pinned roadmap thread](https://steamcommunity.com/app/1899300/discussions/0/4756452548787980214/), [Achievements update 2026-04-19](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1830163047264795).

---

## 1. Level generation: how levels are built, size, linearity, objectives, chokepoints, verticality, secrets, chests

### Takeaway
- **CyberCorp** builds missions from hand-made "blocks": the developer says "one mission consists of 3-6 blocks", from a pool of roughly 20 or more.
  - The 15 story missions are largely authored and scripted, with fixed doors, elevators, traps and dialogue triggers.
  - Side missions are re-rolled from a pool.
  - Players report that most missions have fixed enemy spawns and that side-mission maps repeat.
- **Combat Complex** generates mission layouts procedurally.
  - Layouts are split into "segments" behind doors, with an Objective Terminal, Story Terminals, Power-Up Terminals, secret areas, and an exit door gated by a final loot chest.
  - Each mission's layout is fixed once generated, and replays re-randomize only enemies and loot.
  - Corridors were widened after launch.

### Cited Findings

**CyberCorp: construction and size**
- The store page claims: "Each run randomizes the map, enemies, loot, encounters, weather, boss, and rewards." Locations listed are slums, factories, laboratories, and an elite residential complex. — [Steam store](https://store.steampowered.com/app/1116170/)
- Developer patch note: "Improved visuals of about 20 blocks (one mission consists of 3-6 blocks)". — [Update 17, 2024-10-25](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6212245217911851443)
- Other patch notes mention "some blocks inside the mission wouldn't load on later missions", "many blocks on missions received a minimap", and "improved visualization of some blocks, minimaps". This points to modular, separately authored chunks, each with its own minimap. — [Patch 10.1](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6242640076600668220); [Update 22](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1784506359047842); [Update 21](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1783872411985212)

**CyberCorp: story missions are authored and numbered**
- Fixes reference specific numbered missions: "fixed mission 7 traps", "mission 8 collectable music track", "fixed the elevator on mission 5", "some doors wouldn't open on levels 12 and 13", "Improved navigation, scripts and collision in missions 4, 7, 11, 12", "destructible servers… in mission 15". — [First Update](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6909171012614481949); [Patch 10.1](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6242640076600668220); [Update 6](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5875595438706718428); [Update 28](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1790214123085934)
- Games Asylum (June 2025, 7/10):
  - 15 story stages with several boss battles; "Most missions take under ten minutes"; about an 8-hour campaign.
  - Objectives include capturing zones, destroying servers, and "moving platforms into place while following a glowing path". An early mission is an escort quest.
  - Environments are "grimy streets, boxy apartments, nondescript warehouses, and bland office blocks… a little bit drab… little in the way of memorable set-pieces."
  - — [Games Asylum](https://www.gamesasylum.com/2025/06/04/cybercorp-review/)

**CyberCorp: what players actually see**
- Player "pixillest" (25.6 h, Dec 2025) says few missions are repeated and "most have fixed enemy spawns". They want "some kind of endless or lengthy randomly generated dungeon". — [Steam reviews](https://steamcommunity.com/app/1116170/reviews/?browsefilter=toprated&filterLanguage=english)
- Player "Praxxxus" (19.6 h, Nov 2025): "Some side-mission maps repeat, but enemies vary". Some missions have random modifiers. — [Steam reviews](https://steamcommunity.com/app/1116170/reviews/?browsefilter=toprated&filterLanguage=english)
- Side missions are re-rolled as a set:
  - "completing any side mission now randomizes all side missions on the map again" — [Update 10, 2024-09-05](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6242640076597265942)
  - "Completing any story mission now also regenerates all side missions on the map" — [Patch 10.1](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6242640076600668220)
  - The Sept 2023 demo already had "4 types of additional missions (after completion it will be replaced by another random one)". — [New Demo better than Old, 2023-09-26](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5219165352642769312)

**CyberCorp: linearity, gating, navigation**
- TechGoggles: "level design is well-paced, with a good mix of linear and open-world areas". — [TechGoggles, 2024-12-03](https://www.techgoggles.net/2024/12/03/cybercorp-review/)
- Missions gate on clearing enemies:
  - The dev FAQ answers "I killed all the enemies - but the game says there are more somewhere" with "Enemies sometimes hide… On the mini-map, the signs are marked in red."
  - The same FAQ answers "I'm stuck" with "Maybe there's a button somewhere that opens the door."
  - Later patches added "battle barriers" (arena lock-ins) and "enemy spawner changes (to find all mobs exactly)".
  - — [FAQ](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6909171012610572433); [Update 11](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6250522009513739537); [Update 33](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1801617199543884)
- Navigation aids:
  - A navigation hint that is "periodically re-called outside of combat" (later "hidden during battle").
  - An "Unstuck" button that returns you "to the point where you were already on the way to the main objective".
  - Lighting changes "so that it is better to see the areas where the player can go".
  - On the world map, story missions are connected by a line.
  - — [Update 6](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5875595438706718428); [Patch 10.2](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6242640076611326159); [Update 15](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6931694080291924199); [Update 28](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1790214123085934)

**CyberCorp: secrets, chests, hazards**
- Secret loot boxes exist:
  - "secret loot boxes can be opened twice" (bug fix).
  - Claiming the daily reward "resets opened secret chests in missions. They will not be empty anymore."
  - — [Update 6](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5875595438706718428); [Update 21](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1783872411985212)
- NoobFeed: "Bring out your inner loot goblin and stray from the path to the objective." — [NoobFeed](https://www.noobfeed.com/reviews/cybercorp-review)
- Yellow crates drop loot ("fixed yellow crates sometimes not dropping anything"). Each mission awards a loot box. — [Update 3](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5875595438688315922); [Games Asylum](https://www.gamesasylum.com/2025/06/04/cybercorp-review/)
- Hazards and props:
  - Explosive barrels (grenades explode barrels; barrels were removed from some boss arenas on Nightmare).
  - Landmines.
  - Destructible servers.
  - — [Update 30](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1791580425965866); [Update 31](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1799817379461768); [Steam news 2022-04-25](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/4348797798089492323)
- Seasonal reskins: the Halloween missions had "the lights are off, the color of the bullets is changed, and some barrels may suddenly start walking". — [Halloween & Discount, 2024-11-01](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6146943657173939222)

**Combat Complex: procedural layout with fixed seeds**
- Store page: "Procedurally generated levels: No two levels are the same." — [Steam store](https://store.steampowered.com/app/1899300/)
- Replays keep the layout: "Replayed missions have the same layout but enemies and loot are randomized for each replay." — [Update 2025-03-12](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1794014851393086)
- Structural vocabulary from patch notes:
  - "segment doors" on the "main mission path" and an "exit door".
  - The closed exit door "now shows a text prompt explaining what you need to do to open it".
  - "The final loot chest is now highlighted with a glowing floor decal."
  - "a Story Terminal is missing and thus the segment door cannot be opened".
  - "a floor spawn hatch could erase a Story Terminal".
  - An "Objective Terminal" (given a sound "to make it easier to locate").
  - — [Urgent Update 2024-10-05](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6350729003502074780); [Update 2024-11-24](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1783872412137112); [Skill Tree & Options 2024-09-26](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6339469370181113412)
- Layout tuning:
  - "Missions now have slightly more open spaces / slightly less tight corridors." — [Update 2024-10-12](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6211118320229769832)
  - Small breakables were removed "to make player movement more streamlined", and later removed "around segment and exit doors on the main mission path" and "around chests". — [2024-09-26](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6339469370181113412); [2024-10-07](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6350729003509882555)
  - The generator has "dead ends", where Shield Bots no longer spawn on levels 1-2. — [Early Game Improvements 2026-05-13](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1832700592787374)
  - "Fixed the map generation algorithm so that generated mission layouts don't contain resemblances to a certain undesirable historical symbol anymore." — [Wrecking Ball Update 2026-04-25](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1830797770239127)
- Secrets:
  - A sound plays "for player visiting a secret area".
  - "Secret Areas now contain more rewards, and reward placement is more convenient."
  - Later, "Loot chests were removed from Secret Areas to prevent replay-farming of missions with lucky secret chests."
  - Entrances now have doors that "open automatically when the player is nearby".
  - — [2024-09-26](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6339469370181113412); [2024-11-24](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1783872412137112); [2025-03-12](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1794014851393086); [2026-04-25](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1830797770239127)
- Chests and map:
  - Loot containers are graded ("previously Gold, Silver etc.").
  - The in-mission Map screen has "map abilities" (e.g. "Scan Surroundings"), issued by terminals.
  - — [2024-09-26](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6339469370181113412); [2024-11-24](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1783872412137112)
- Hazards placed in levels:
  - Boom Barrels, now with an always-visible explosion radius and "cannot spawn closer than 8m to a door" or in Secret Areas.
  - Retractable Plasma Turrets.
  - Laser walls and Deflector walls (planned).
  - — [2025-03-12](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1794014851393086); [2025-06-26](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1803527891510116); [Roadmap](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6250522009527845924)
- Player views:
  - Procedural levels are built for "frantic enemy culling" rather than rich visuals.
  - Another player: "Spacious levels, but navigation is hard."
  - Another: "missions are fixed" with unlimited retries.
  - — [Steam reviews](https://steamcommunity.com/app/1899300/reviews/?browsefilter=toprated&filterLanguage=english)

### Inferences
- CyberCorp's "procedural" claim is best read as modular assembly plus randomized side-mission selection, enemies, loot and modifiers. Story missions behave like hand-authored levels. This is inferred from the block-count note, mission-numbered scripted fixes, and player reports of fixed spawns.
- Combat Complex is closer to true procedural generation, but it seeds each mission and keeps the layout. Its level grammar resembles a dungeon generator:
  - a chain of segments behind doors;
  - terminals that act as keys;
  - side branches holding secrets;
  - a final chest that opens the exit.
  - The "undesirable symbol" fix suggests a grid or orthogonal-corridor generator. This is inferred.
- Both games tuned levels the same way: wider spaces, fewer breakables on the critical path, and clearer critical-path signposting (glowing decals, objective sounds, navigation hints, a world-map line). Navigation readability was a real problem in both.

### Gaps
- I found no source for CyberCorp's level dimensions, verticality (it has elevators and moving platforms, but no detail), or the randomized weather the store claims. No patch note mentions weather.
- I found no hard numbers for Combat Complex mission length, segment count, or map size. Its generator algorithm has no devlog.
- The "1-3 player co-op" figure for CyberCorp was not confirmed in the sources I fetched. The store page says only "Online Co-op".

---

## 2. Mission types, run/session structure, hub, difficulty scaling

### Takeaway
- **CyberCorp** is a mission-select looter in the style of Destiny or Warframe:
  - a hub apartment (forge, shop, paint and transmog) with a map of 15 story missions plus random side missions;
  - three lives per mission;
  - Normal, Hard and Nightmare tiers;
  - later modes added: Survival, Defense, Extraction, Capture, Data Capture, boss missions, and an endless wave "stay or leave" mode;
  - Warframe-style dailies and milestones.
- **Combat Complex** is a hub plus numbered-level mission ARPG:
  - difficulty-coloured missions (White, Yellow, Orange, Red) with mission modifiers;
  - roguelike Power-Ups that last 4 missions and are lost on death;
  - the developer stresses it "still plays as a mission-based ARPG, not as a roguelike".

### Cited Findings

**CyberCorp: mission types**
- Store-listed objectives: "Defend objects, Hack security systems, Capture control points, Uncover hidden items". — [Steam store](https://store.steampowered.com/app/1116170/)
- Modes added during Early Access: "New mission types: Survival, Defense, Extraction, Capture". — [Changes During Early Access, 2025-04-21](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1797185861772586)
- Extraction mode: "need to successfully complete the mission to get the loot (available after the mission of level 15 hard difficulty)". It has its own exclusive exotic drops. — [Update 12, 2024-09-19](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6341720536502998670)
- Survival: "Decreased survival time from 7.5 to 5 minutes, increased enemy spawn speed". — [Update 30, 2025-02-13](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1791580425965866)
- Endless wave mode: the "Halloween Kills" mission introduced a mode "where you can stay and continue the fight. With each wave, the chance for more valuable rewards increases, but the enemies become stronger." After the event it was kept as "endless survival" without the festive decorations. — [Update 35, 2025-10-21](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1813674389095279); [Patch 35.3](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1816849002023879)
  - It was pitched beforehand as "defense against waves of enemies with an option to evacuate with loot – all or nothing". — [Working on the Autumn Update, 2025-09-10](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1810503566386914)
- Other mission types named in patch notes: Nightmare "data capture and clearing the area", an escort mission, "ship missions", and boss missions on Nightmare for side missions.
  - A boss mission (DAINSLEIF / "Armament") unlocks after story mission 12. Completing it unlocks "chips" for exotic slot unlocking and perk rerolls.
  - — [Patch 23.1](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1785321795643651); [Update 31](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1799817379461768); [Patch 35.4](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1818752592136121); [Update 30](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1791580425965866); [Update 34](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1811772772436534)
- Entertainment Geekly lists objectives as "clearing gang territories, protecting terminals, and reaching an exit". It calls them repetitive: "the objectives blur together after just a few hours." — [Entertainment Geekly, 2025-06-08](https://www.entertainmentgeekly.com/2025/06/08/cybercorp-review-fun-firefights-but-struggles-to-stay-fresh/)
- NoobFeed: missions "range from run-and-gun to stealth". After a limited number of respawns, the mission restarts. — [NoobFeed](https://www.noobfeed.com/reviews/cybercorp-review)

**CyberCorp: session structure**
- Games Asylum describes the loop:
  - 15 story stages, with "Each mission gives three lives".
  - Side content is "shorter survival and data capture missions for grinding".
  - Story missions are replayable on harder difficulties for higher-level loot.
  - — [Games Asylum](https://www.gamesasylum.com/2025/06/04/cybercorp-review/)
- Player "ShockZz" (Dec 2025, negative): by hour 2 you must replay older missions to continue the story. — [Steam reviews](https://steamcommunity.com/app/1116170/reviews/?browsefilter=toprated&filterLanguage=english)
- Player "Alex.N": "Mission-based progression rather than an open map makes short sessions viable." — [Steam reviews](https://steamcommunity.com/app/1116170/reviews/?browsefilter=toprated&filterLanguage=english)
- Retention systems:
  - Daily quests (Update 13).
  - Login milestone rewards "similar to the milestone mechanic from Warframe" (Update 14).
  - A Codex that gives "+1% damage per enemy type".
  - Seasonal events (Halloween, Christmas) with exclusive loot.
  - — [Update 13](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6339469370182411582); [Update 14](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6350729003494822375); [Changes During EA](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1797185861772586)

**CyberCorp: hub**
- The hub is a player base for "modifying, upgrading, and painting weapons/armor". — [Dropped New Demo, 2024-05-15](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5747233970414425096)
- Hub features:
  - The forge (available after the 3rd mission).
  - A shop.
  - A radio.
  - NPCs: a rat and a cat.
  - "The environment at the second base changes depending on the progress in the story missions".
  - — [Update 11](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6250522009513739537); [Update 17](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6212245217911851443)
- Co-op flow: the host picks the mission from the lobby. Matchmaking shows teammates' power level, mission difficulty, reward level and reward type. — [FAQ](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6909171012610572433); [4 Weeks till Release](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5963413094348567826)

**CyberCorp: difficulty scaling**
- Store: "Difficulty levels scale rewards, from casual to hardcore." — [Steam store](https://store.steampowered.com/app/1116170/)
- Tiers are Normal, Hard and Nightmare, "added for all missions, with new mechanics, enemies, and rewards". Nightmare story bosses were added at 1.0. — [Changes During EA](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1797185861772586); [Leaving EA](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1796631172248182)
- A "hardcore" mission with level-60 loot unlocks after defeating the final story boss on high difficulty. — [Update 10](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6242640076597265942)
- Level clamping:
  - Player level was originally clamped down on old missions.
  - The developer softened the clamp after a bad review: "on old missions the level decreases significantly less".
  - Later: "player power level is no longer limited in missions".
  - — [Update 7](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6240387642451087153); [Patch 14.1](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6350729003497487657)
- Level cap was raised from 60 to 70 at 1.0. — [1.0 Out Now](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1797185861802763)

**Combat Complex: mission and difficulty structure**
- The core loop is "Loot is permanent once you bring it home, but power-ups are lost on death". — [Steam store](https://store.steampowered.com/app/1899300/)
- Difficulty colours appear in patch notes as "White / Yellow / Orange / Red missions", with a "Risk-Taker – Complete 5 red missions" challenge. — [2025-07-19](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1805431065400567); [2026-04-19](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1830163047264795)
- Levels are numbered, and content gates by level:
  - Roundshield appears at Level 3+ and Minigun Tank at Level 4+.
  - "Levels before 7 are now a bit easier, and levels above 7 are now harder."
  - — [2025-06-26](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1803527891510116); [2024-10-07](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6350729003509882555)
- Mission modifiers (affixes) named in patch notes:
  - "No Going Back" (lasers activate behind the player).
  - "Explosives Everywhere".
  - "Mortar Mayhem" (grenade bots fire 3-round bursts).
  - "Backspawn" (30% of enemy "biomass" spawns from behind).
  - Modifiers are assigned per "map sector", and hazards "are reserved for mission affixes on higher-difficulty missions".
  - — [2024-10-07](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6350729003509882555); [2025-07-19](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1805431065400567); [Roadmap](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6250522009527845924)
- Power-Ups:
  - "three power-ups, pick one, maybe reroll", issued by Power-Up Terminals on missions, with a limited number of rerolls.
  - They "persist through missions, but you'll lose them if you die".
  - They "last 4 missions", are "infinitely stackable", and are "added on top" of player power.
  - The developer says the game "still plays as a mission-based ARPG, not as a roguelike – though power-ups definitely add some spicy roguelike sauce".
  - — [2024-11-24](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1783872412137112)
- Death and replay rules:
  - Since Mar 2025: "When you die on a mission, you now keep the loot you've collected", and Power-Ups are still lost.
  - Leaving through the pause menu forfeits that mission's loot.
  - "All completed missions can now be replayed" for gear farming.
  - "To prevent replay-farming, loot chests at the end of missions are now fixed rarity that depends only on mission difficulty."
  - — [2025-03-12](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1794014851393086)
- Hub: a hub area with Inventory, Map screen (shows power-ups), Skills, Challenges, and a Crafting bench from Level 1. Story is delivered as "email-like" messages. — [2024-11-29](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1784506359053555); [2025-09-29](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1811772772383709); [2024-09-26](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6339469370181113412)
- Planned or longer-term items: "Endlessly repeatable / farmable missions", biomes (Mining, High-tech, Infested), co-op. — [Roadmap](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6250522009527845924)
- Player reception of the structure:
  - One player found the systems "muddled": "chunks of rogue-likes, ARPG, and extraction shooters… just not quite fitting together".
  - Another said "It's **not** a roguelite".
  - — [Steam reviews](https://steamcommunity.com/app/1899300/reviews/?browsefilter=toprated&filterLanguage=english)

### Inferences
- Both games moved toward letting players keep loot. CyberCorp kept extraction-style risk as an opt-in mode (Extraction; endless "stay or evacuate"). Combat Complex removed loot loss on death and moved the risk onto temporary Power-Ups. For a new game, risk is best confined to a clearly signposted mode or resource rather than core loot.
- Combat Complex's per-sector modifiers and difficulty colours give procedural maps variety cheaply. CyberCorp relies on new authored missions and Nightmare variants of old ones.

### Gaps
- I found no exact count of CyberCorp side-mission templates, and no confirmation of the randomized boss and weather claims beyond the store blurb.
- Combat Complex's mission count per level and full modifier list are not published. Bosses and Treasure Goblins were still unshipped as of the June 2026 roadmap.

---

## 3. Encounter pacing: waves, horde sizes, elites, bosses

### Takeaway
- **CyberCorp** pacing:
  - arena-style "battles" gated by barriers;
  - roaming "Invader" mini-bosses that drop in unannounced, the main cause of death;
  - Stalkers and Champions that spawn enemies;
  - multi-wave boss fights ending in a takedown;
  - a combo/style rank that carries over between battles.
- **Combat Complex** pacing:
  - budget-based ("biomass") horde spawning from spawn doors and floor hatches, with some flanking spawns;
  - colour-tiered elites;
  - no true bosses yet, by design: the developer wants bosses that are "not just bullet sponges".

### Cited Findings

**CyberCorp**
- Invaders:
  - Stronger, faster enemies with meme-style names. They "drop into missions without warning" and are the usual cause of death. — [Games Asylum](https://www.gamesasylum.com/2025/06/04/cybercorp-review/)
  - Day-2 patch: "Invader: no longer spawn in the early levels"; "slight nerf for Invader boss improved loot for killing him". — [Update 2](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5875595438685255725); [First Update](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6909171012614481949)
  - A negative review (Dec 2025) calls the invader "braindead", "seemingly 20 levels above the player", "appearing every second mission and sometimes one-shotting the player". The same review says some enemies don't telegraph attacks. — [Steam reviews](https://steamcommunity.com/app/1116170/reviews/?browsefilter=toprated&filterLanguage=english)
- Enemy roles named in patch notes:
  - "champion wouldn't spawn enemies"; the Stalker drops guaranteed loot.
  - "fast crawling robots"; melee syndicate soldiers; spider mobs that "bite while running".
  - Bosses: Delilah/Delaila, Komodo with henchmen under a shield, Shimada (teleports), Spike, Spider.
  - — [Patch 10.1](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6242640076600668220); [Update 10](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6242640076597265942); [Update 5](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5875595438699052555); [Update 34](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1811772772436534); [1.0 Out Now](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1797185861802763)
- Bosses:
  - "Bosses are praised as the more inventive part of the mission design… usually have several waves." — [Games Asylum](https://www.gamesasylum.com/2025/06/04/cybercorp-review/)
  - Bosses end with a takedown, and "Bosses: now automatically die if not finished off within 10 seconds". — [Update 2](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5875595438685255725)
  - At 1.0: "Bosses Delilah and Spider — laser attacks reworked, now actually dangerous". — [1.0 Out Now](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1797185861802763)
  - "Defeating Delaila on nightmare difficulty now stops enemy spawns" (add spawns ran on during the boss). — [Update 31](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1799817379461768)
  - TechGoggles: bosses "lack the epic scale of other games in the genre". — [TechGoggles](https://www.techgoggles.net/2024/12/03/cybercorp-review/)
- Finishers by tier: "normal enemies should now be finished off with quick finishing moves, and elite ones with rarer and longer finishing moves." Takedowns grant invulnerability and heal. — [Update 18](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6146943657173904568); [Update 10](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6242640076597265942)
- Combo rank: "combo rank is not reset between battles, the next battle will start immediately with the combo of the previous battle". The premium currency (Cuberium) is rewarded for combo rank. Pop-ups include "Double Kill" and "Cool Dodge". — [Update 22](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1784506359047842); [Patch 10.1](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6242640076600668220)
- Music changes "between combat phases" in side missions; the endless mode changes music between waves. — [Update 31](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1799817379461768); [Patch 35.1](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1814309641405360)
- Shielded enemies: NoobFeed (Aug 2024 build) says "Guns simply don't work against them". They had to be handled with the environment or melee. — [NoobFeed](https://www.noobfeed.com/reviews/cybercorp-review)
- The developer's 2022 marketing mentions "intense firefights with mobs and minibosses" and a mark appearing on the synth as a threat telegraph. — [Steam news 2022-07-26](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/4598755821884755446); [2022-06-30](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/4474904295756707278)

**Combat Complex**
- Store: "Hordes of enemies… prepare to be overwhelmed." — [Steam store](https://store.steampowered.com/app/1899300/)
- Spawn budget: "Previously, [Backspawn] spawned 100% biomass from the front and 30% from the back (130% in total). Now it spawns 70%… from the front and 30% from the back (100% in total)." — [2025-07-19](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1805431065400567)
- Flanking:
  - "Fodder enemy spawns now have a 15% chance to occur behind the player." — [2025-07-19](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1805431065400567)
  - Later, rear spawns were limited to a single enemy type, and the amount was reduced. — [2025-10-18](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1813674389000805)
- Spawn sources: "Spawn doors now blink and play a sound effect when spawning enemies"; floor spawn hatches; enemies hatch from eggs; "prespawn" (placed) enemies. — [2026-05-13](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1832700592787374); [2024-11-24](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1783872412137112)
- Early-level spawn rules: "On level 1, Centipedes no longer spawn from eggs, only via prespawn… On levels 1 and 2, Centipedes and Shield Bots no longer spawn at the beginning of a mission." — [2026-05-13](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1832700592787374)
- Roster and roles:
  - Bugs: small bugs and eggs, Centipedes, Maggots (spawn swarms), soldier bugs (25% become jumping bugs).
  - Bots: Laser Bots, Shield Bots in blue (kinetic-vulnerable) and red/deflector variants, Grenade Bots.
  - Heavies: Laser Tank ("divides the battlefield by creating a line of fire"), Minigun Tank (moves while firing), Rocket Tank.
  - Wrecking Ball (armored, slam and charge attacks).
  - Roundshield: a "bodyguard" with six independent shields that stands behind its ward.
  - — [2025-06-26](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1803527891510116); [2025-07-19](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1805431065400567); [2026-04-25](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1830797770239127)
- Elites:
  - Blue elite Rocket Tank HP multiplier was cut from x4 to x2, and purple from x8 to x4.
  - One player notes purple elites stand in for bosses.
  - Planned: "Special / Legendary Elites (extremely dangerous but fragile)".
  - — [2026-04-25](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1830797770239127); [Steam reviews](https://steamcommunity.com/app/1899300/reviews/?browsefilter=toprated&filterLanguage=english); [Roadmap](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6250522009527845924)
- Signature mechanic: "enemies damage each other, so you can… pull or push a group of enemies into a laser beam fired by another enemy, instantly killing the entire group." — [EA release post](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6350729003497945980)
  - Counter-tuning: Roundshield got "90% damage resistance to friendly fire".
  - XP is "awarded for any enemy death, regardless of what caused it", including friendly fire.
  - — [2025-10-18](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1813674389000805)
- Red shields as flow-breakers: "one of the biggest flow-breakers of the game: red shields". Deflector spawn chance was cut from 50% to 30-36% depending on difficulty, which "significantly lower[s] the chance of encountering a group of red Shield Bots". — [2025-07-19](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1805431065400567)
- Bosses and Treasure Goblins (planned):
  - Bosses are "designed to avoid 'bullet sponges' and to let players use their full arsenal". — [Steam store](https://store.steampowered.com/app/1899300/)
  - Treasure Goblin: "Tough to kill, temporary (escapes after some time). High risk / reward… dilemma with the upcoming Ultimate Abilities (use it or save for danger?)". — [Roadmap](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6250522009527845924)
- Player views:
  - Swarms are "very hectic" and difficulty rises deeper into a level.
  - "Too many enemies"; one player requested Diablo-style difficulty where harder means more enemies and loot.
  - — [Steam reviews](https://steamcommunity.com/app/1899300/reviews/?browsefilter=toprated&filterLanguage=english)

### Inferences
- Combat Complex's "biomass budget" (a spawn-points pool split between front and back spawns) is a reusable director pattern. Its tuning history (130% to 100%; rear spawns limited to one faction) shows that flank spawns quickly feel unfair unless they are capped and readable (blinking doors plus sound).
- In CyberCorp, the surprise Invader is a memorable threat but the top cause of frustration. Telegraphing and level-matching such roaming elites matters, which the developer partly addressed by excluding Invaders from early levels.

### Gaps
- No numeric horde sizes or wave counts for either game, other than Survival's 5-minute timer and the biomass percentages.
- No CyberCorp elite-modifier list.
- CyberCorp boss fights are described only by name and patch notes; I found no structured breakdown.

---

## 4. Loot and upgrades: card system, rarities and affixes, legendaries, skills, builds, crafting

### Takeaway
- **CyberCorp** loot model:
  - Synth gear: two firearms, a melee weapon, and head, body and legs armour.
  - Rarities: gray/white, green, blue "Elite", red "Exotic", plus a rarer "prototype".
  - Fixed perks on items.
  - Slottable modification cards for weapons, armour and skills. Cards are levelled 1-6 by fusing duplicates in the forge (3 copies become the next level), and extracting them costs currency.
  - Exotics originally could not take cards. Late updates let "chips" unlock card slots on exotics and reroll gun perks.
  - Skills (3 slots) are dropped items with their own upgrade cards.
  - Pity timers and paid "targeted loot" smooth out drop luck.
- **Combat Complex** loot model is Diablo-like:
  - Random stat mods. Rare (blue) and Epic (purple) differ by mod count, and Legendaries carry named effects.
  - A skill tree with 6 branches and free respec.
  - Active, passive and ultimate abilities as equippable items.
  - A deep crafting bench (Sep 2025) with upgrade levels and tiers and "Starred" locked stats.

### Cited Findings

**CyberCorp: slots and rarities**
- Store: "Upgrade your equipment using a card-based system of weapon and armor enhancements"; "create their own build, whether it's close combat, skills, or long-range sniping". — [Steam store](https://store.steampowered.com/app/1116170/)
- Slots: "two firearms and a melee weapon. Armour covers the head, torso, and legs". Rarities are "colour-coded as common, rare, or exotic". — [Games Asylum](https://www.gamesasylum.com/2025/06/04/cybercorp-review/)
  - NoobFeed lists Primary, Secondary and Melee weapon slots plus Head, Body and Legs parts. — [NoobFeed](https://www.noobfeed.com/reviews/cybercorp-review)
- Rarity ladder from patch notes: gray and green (junk-sellable), "Elite quality items (blue)", exotic (red), and "10% that a prototype will drop" on Extraction. — [Update 19](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6148070194801599535); [Update 11](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6250522009513739537); [Update 15](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6931694080291924199)

**CyberCorp: how the cards work**
- Games Asylum: "Rarer weapons have slots for perk cards, such as ricochet effects. Duplicate perk cards can be combined to increase their rank. Every item can be upgraded at the forge… each upgrade costs credits." — [Games Asylum](https://www.gamesasylum.com/2025/06/04/cybercorp-review/)
- Card level and colour: "the colors of the upgrade cards depends of their level (1- gray, 2-3 green, 4-5 blue… level 6… purple)". — [Patch 19.1](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6148070194801626671)
- Fusing: "added level 6 of some cards (can be crafted from 3 pcs of level 5 in the forge)"; "the required number of cards for crafting in the forge at level 4 and 5 has been reduced, now you need 3 pcs". — [Update 20](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1783238125218992)
- Cards carry trade-offs: "now basic cards do not have negative effects and penalties". An early demo fix mentions "inverted red and green numbers in card info". — [Update 10](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6242640076597265942); [Demo Path #1, 2022](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/4480532686366418155)
- Card count and variety:
  - "balanced hundreds of cards". — [4 Weeks till Release](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5963413094348567826)
  - Further additions: "7 new cards", "new extra powerful cards… for completing nightmare difficulty and the 'extraction' mission", "joker cards".
  - Named examples: "power accumulator sword card", "large caliber card", a "pet skill boost card" that also affects drones, a card reducing damage taken below 35% HP.
  - — [Update 21](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1783872411985212); [Update 20](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1783238125218992); [Update 28](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1790214123085934); [Patch 19.1](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6148070194801626671); [Update 24](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1785774543562375); [Update 30](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1791580425965866)
- Extraction cost:
  - "the price of manually pulling cards from weapons was different when selling and pulling". — [Patch 15.1](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6931694080295416381)
  - "Card extraction from equipment is now much cheaper — more freedom to experiment with builds!" Card effects at levels 4-6 were increased and their reforge cost cut. — [Update 31](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1799817379461768)
  - Player "Praxxxus" wishes modding were free "to allow easy and convnenient build-crafting". They call the endgame grindy because higher card upgrades need many resources. — [Steam reviews](https://steamcommunity.com/app/1116170/reviews/?browsefilter=toprated&filterLanguage=english)
- Exotics and cards:
  - An EA reviewer said cards fit only white, green or blue items, not red exotics: "What are these red items for then?" — [Steam reviews](https://steamcommunity.com/app/1116170/reviews/?browsefilter=toprated&filterLanguage=english)
  - Update 34 (Oct 2025) added chips that "unlock card slots on exotic items, and then freely insert cards" and "reroll a gun's perks to random ones (the number and level of perks remain the same)". The currency drops only on Nightmare. — [Update 34](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1811772772436534); [Update 35](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1813674389095279)

**CyberCorp: exotics, skills and economy**
- Exotic examples, each built around a gimmick:
  - SG 422 Reaper: throws grenades on an empty-mag reload.
  - Hunter revolver: always crits stationary targets.
  - Object 97 Nullifier: shield break causes an explosion.
  - AC21 Purge: shots explode past a distance.
  - An exotic pistol whose crit kills explode bodies.
  - Type-7 sword: penetrates shields and restores the player's shield.
  - Vulcan SMG: quick reloads raise fire rate.
  - Pain Carrier pistol: marks a target and mirrors damage.
  - — [Update 24](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1785774543562375); [Update 14](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6350729003494822375); [Update 12](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6341720536502998670); [Update 35](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1813674389095279)
- Skills:
  - Two cooldown skill slots at first, a third unlocked later (after mission 10).
  - Skills include turrets, drones, an EMP shockwave, a healing beacon, Blink, auras, mines, grenades and a protective dome.
  - — [Games Asylum](https://www.gamesasylum.com/2025/06/04/cybercorp-review/); [Update 15](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6931694080291924199); [Update 30](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1791580425965866)
  - NoobFeed: "No skill tree or level-up system. Skills are picked up and equipped directly". — [NoobFeed](https://www.noobfeed.com/reviews/cybercorp-review)
  - Skills drop as loot and are farmable per mission. — [Update 11](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6250522009513739537)
- Drop-luck smoothing:
  - Pity system: "Every time you complete a mission, if no exotic/blue items dropped, the chances will increase for the next mission". The developer explains the reasoning: a 10% rate can still give 0 drops in 20 runs. — [Update 21](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1783872411985212)
  - Targeted loot: "pay credits to increase the chance of getting a specific gun, armor, card… around 5x the drop rate… lasts until the item drops". — [Patch 21.1](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1783872412016406)
  - A loot preview per mission (press G). — [Update 10](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6242640076597265942)
- Economy:
  - Two currencies, credits and Cuberium (premium; used for skills, cards and forge). — [NoobFeed](https://www.noobfeed.com/reviews/cybercorp-review); [Update 22](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1784506359047842)
  - Rectify Gaming: currency "feels almost pointless" because looted gear beats the shop. — [Rectify Gaming](https://www.rectifygaming.com/review-cybercorp/)
  - An EA player: currency is "worthless". — [Steam reviews](https://steamcommunity.com/app/1116170/reviews/?browsefilter=toprated&filterLanguage=english)
  - Games Asylum: the shop is "a bit surplus". — [Games Asylum](https://www.gamesasylum.com/2025/06/04/cybercorp-review/)
- Cosmetics: paints, transmog, and armour sets (Devour, Renegade, Eagle, Alien, female variants). — [Changes During EA](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1797185861772586)

**Combat Complex: loot and rarities**
- Store: "Random loot: Rare, epic, and legendary tiers, including railguns, pulse rifles, and flamethrowers"; "Stats and skill tree: … tanky, glass-cannon, or 'space wizard'". — [Steam store](https://store.steampowered.com/app/1899300/)
- Rarity design note: "our epic (purple) loot differs from rare (blue) only in the number of stat mods". A plan to add +1 skill-rank mods to epics was dropped as "too OP". — [Roadmap](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6250522009527845924); [Pinned roadmap thread](https://steamcommunity.com/app/1899300/discussions/0/4756452548787980214/)
- Slots:
  - Primary, Secondary and Special weapons; Helmet; Active Ability; Passive Ability; Ultimate Ability.
  - Weapons overheat instead of reloading.
  - Weapon types: Rifle, SMG, Shotgun, Minigun, Railgun, Flamethrower, Lightning Gun.
  - Grenades come in Physical, Fire and Shock variants.
  - — [2024-10-12](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6211118320229769832); [2025-06-26](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1803527891510116); [2026-06-06](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1834602721194038)
- Weapon counters to enemy defences: kinetic weapons cannot hurt red/deflector shields or armor unless they have the "Crimson" legendary effect. Miniguns "damage deflector (red) shields and armored targets". — [2024-10-12](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6211118320229769832); [2025-06-26](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1803527891510116)
- Legendary effects (named affixes):
  - Vector, Angular, Raycast (+1 ricochet).
  - Frenzy and Combo (friendly-fire kills of gravity-affected enemies grant Frenzy or cut cooldowns).
  - Trinity, Bouncer, Cluster (grenades).
  - Mjölnir, Supercell, Nexus (lightning gun).
  - Napalm, Wildfire (flamethrower).
  - Reach (+50% range).
  - — [2024-10-12](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6211118320229769832); [2026-06-06](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1834602721194038); [2026-06-27](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1836506165557220)
- Stat mods named include Movement Speed (capped at 6%), Movement Speed When Healthy, Movement Speed After Dash (cut from 30% to 12%), Damage vs Breakables, XP Gain, Beam Damage Reduction, and Rare Item Find (from an orb). — [2024-10-05](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6350729003502074780); [2025-10-18](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1813674389000805); [2026-06-06](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1834602721194038)

**Combat Complex: crafting (Sep 2025)**
- "Crafting allows you to upgrade, add, modify, randomize, and remove item stats." Materials come from missions or from salvaging.
- Blueprints: Upgrade Item, Randomize Item Stats, Reroll Stat Values, Remove Random Stat, Add Random Stat, Increase Item Rarity, Duplicate Item ("item backups before risky crafting"), and Finalize Item ("major stat increase but locks the item").
- Each Upgrade Level gives +5% to all stats. Tiers come at levels 4, 8, 12, 16 and 20. At each tier a random stat gets +20% and becomes "Starred", which locks it from rerolls.
- Loot can drop pre-upgraded, more often on higher difficulties.
- The developer did not compensate enemy stats for the added power.
- — [2025-09-29](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1811772772383709)

**Combat Complex: skill tree and progression**
- Skill tree history:
  - Preliminary tree in Sept 2024, with skill points from on-mission Skill Stations.
  - Skill Stations replaced by XP in Oct 2025 because they were "clunky, hard to understand".
  - Reworked tree in Mar 2026 with branches Movement, Attack, Close-Quarters Combat, Defense, Luck, and Fire & Shock.
  - "Respec is now instant and free."
  - — [2024-09-26](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6339469370181113412); [2025-10-18](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1813674389000805); [2026-03-15](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1826992588600158)
- Abilities:
  - Dash.
  - Gravity Vortex, Gravity Pull, Gravity Push, Gravity Hook (all 3 charges).
  - Grenade and Contact Grenade (9 s cooldown, 3 charges).
  - Passives: Mistake Mitigator, Safeguard (50% damage reduction below 30% HP, 80% below 10%).
  - Ultimates: Shredder (two drones copy your weapons for 10 s), Salvation, Stoneskin. Ultimates recharge over 90 s of combat time, later 30% longer.
  - — [2025-03-12](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1794014851393086); [2026-06-06](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1834602721194038); [2026-03-15](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1826992588600158)
- Orbs as an in-mission economy:
  - Health orbs; Frenzy; a purple "Rare Item Find" buff (60 s, later 120 s); a Revive orb.
  - Ultimate Orbs: small gives 10% ultimate charge, large gives full charge; both reset the active-ability cooldown and weapon heat. The stated goal is to "enhance the flow of the game by increasing the uptime of player guns and abilities".
  - — [2025-06-26](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1803527891510116); [2025-10-18](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1813674389000805)
- Builds the developer and players name:
  - "The full Movement-CQC hybrid build is TONS of fun, even OP at times." — [2024-09-26](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6339469370181113412)
  - Lightning Gun builds were "the most productive in the game while being the least mechanically-demanding" and were nerfed 20%. The developer's goal is to "balance the 'productivity' of a build… with the effort required for running the build". — [2026-03-15](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1826992588600158)
  - The Minigun Tank was the "main cause of death for pure glass cannon builds". — [2026-03-15](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1826992588600158)
- Challenges such as weapon-kill milestones award XP and are tied to achievements (28 at launch of the feature). — [2026-04-19](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1830163047264795)

### Inferences
- CyberCorp's cards act as a second, player-controlled affix layer on top of fixed item perks, with fusion-based ranks. This is closer to Warframe mods than Diablo affixes, which fits the developer's repeated Warframe references (milestones, codex). The early friction came from:
  - exotics without card slots;
  - paid extraction;
  - grind for high card levels.
  - Patches moved toward cheaper extraction and slot unlocks on exotics. Inferred from the patch sequence.
- Combat Complex's most distinctive item ideas:
  - Legendary effects that reward its friendly-fire hook (Frenzy and Combo trigger on enemy-on-enemy kills).
  - "Starred" stats, which let crafting create permanent progress while keeping rerolls risky.
  - The Duplicate Item blueprint, which takes the sting out of risky crafting.

### Gaps
- I found no official total card count for CyberCorp ("hundreds" is the only figure), no per-rarity slot counts, and no wiki or guide documenting card slot rules. A Steam guide search returned nothing usable.
- No Combat Complex numbers for affix pools or drop rates. Set items were not found in any source; I could not confirm sets for either game.

---

## 5. Reception: Steam summaries, recurring praise and complaints, Game8's "dull combat", what Combat Complex players want

### Takeaway
- **CyberCorp** (75% positive of 360 Steam reviews):
  - Praised for fast, readable gunplay, weapon and loot variety, short missions, controller and Steam Deck play, and very frequent patches.
  - Criticised for weak melee, weak hit-reaction feedback, early bugs and co-op desync, a pointless shop economy, drab and repetitive mission design, Invader spikes, and a grindy endgame.
  - Game8 (60/100, Aug 16, 2024, before Early Access launch) summed this up as "lack of excitement, novelty, and polish". Its "Dull Combat" section singles out unsatisfying melee and odd boss fights.
- **Combat Complex** (81% of 66):
  - Players praise the friendly-fire hook, overheat gunplay, hectic swarms and horror atmosphere.
  - They want more loot depth and affixes, bosses, crafting (since shipped), better navigation and performance, and clearer onboarding.

### Cited Findings

**Game8 on CyberCorp**
- OpenCritic lists Game8 (Alfonso Majarucon) 60/100, dated Aug 16, 2024: "CyberCorp is an above average game severely weighed down by its general lack of excitement, novelty, and polish." — [OpenCritic](https://opencritic.com/game/18728/cybercorp/reviews)
- From search-engine snippets only, because the Game8 page returned HTTP 403 to direct fetch:
  - The review is headlined "Unpolished, But With Potential", with a section "Unpolished With Unrealized Potential".
  - Listed weaknesses: "weird boss fights, dull combat, looter shooter stats", and lack of polish.
  - Its "Dull Combat" section says you "would be hard-pressed to gain any aesthetic gratification from the melee combat".
  - It concludes it is "difficult to recommend CyberCorp as it is right now".
  - Strengths include "Above-Textbook Shooter Gameplay" and "Weapon Variety Pops".
  - — [Game8](https://game8.co/articles/reviews/cybercorp-review); [Game8 alt URL](https://game8.co/reviews/cybercorp/cybercorp-review)
- Corroborating critics on the same complaints:
  - NoobFeed (80, Aug 27, 2024): melee damage "so negligible that they can't even be considered weapons"; attacks are "Boring and clunky"; controls are stiff; shielded enemies are immune to guns. — [NoobFeed](https://www.noobfeed.com/reviews/cybercorp-review)
  - Respawn Island (Mar 2025): melee damage "disappointingly low, and the animations feel clunky". — [Respawn Island](https://respawnisland.com/2025/03/20/cybercorp-review/) (via search snippet)
  - TheBigBois: melee "lacking in impact and excitement". — [TheBigBois](https://thebigbois.com/action/cybercorp-review-a-fast-paced-co-op-looter-shooter-with-high-replayability/) (via search snippet)

**Other CyberCorp critic scores**
- Rectify Gaming 6/10 (Aug 22, 2024):
  - "lukewarm entry".
  - Voice acting via Google Translate was "horrible".
  - UI "laggy and buggy"; controller support an "afterthought".
  - — [Rectify Gaming](https://www.rectifygaming.com/review-cybercorp/)
- TechGoggles 8/10 (Dec 2024): combat "fluid and responsive, with satisfying feedback"; "enemy variety is limited"; the world "feels somewhat empty and lifeless". — [TechGoggles](https://www.techgoggles.net/2024/12/03/cybercorp-review/)
- Games Asylum 7/10 (June 2025): the loot system is where it "excels the most"; "There isn't much here in the way of innovation"; no mission "stood out from the rest". — [Games Asylum](https://www.gamesasylum.com/2025/06/04/cybercorp-review/)
- Entertainment Geekly 3/5 (June 2025, console era):
  - "Mission structure is painfully repetitive".
  - Animation glitches and AI breakdowns.
  - Co-op players get stuck behind doors.
  - — [Entertainment Geekly](https://www.entertainmentgeekly.com/2025/06/08/cybercorp-review-fun-firefights-but-struggles-to-stay-fresh/)
- Gaming Professors 5/10 and Games Freezer 7/10 (Xbox Series X). — [OpenCritic](https://opencritic.com/game/18728/cybercorp/reviews)
- Snippet-only scores: The Xbox Hub 2.5/5 ("Generic Shooter with Lofty Aspirations") and GamesCreed 3.5/5. — [The Xbox Hub](https://www.thexboxhub.com/cybercorp-review/); [GamesCreed](https://www.gamescreed.com/reviews/cybercorp-review)

**CyberCorp Steam players**
- Hit feedback:
  - "Shooting feels kinda weak"; abilities feel "puffy" (Apr 2025).
  - Enemies "barely flinch", "ragdoll on death and that's it"; finisher animations are awkward (Dec 2025).
  - Comparison: "Boring bland stat-based mobile version of the Ascent" (Nov 2025, negative).
  - — [Steam reviews](https://steamcommunity.com/app/1116170/reviews/?browsefilter=toprated&filterLanguage=english)
- Praise:
  - "Instead of the more typical twin stick bullet hell", combat focuses on positioning, dodge timing, skills and weapon switching.
  - Guns sound "punchy and impactful".
  - "A great combo of Synthetik, Roboquest, and Ruiner".
  - Frequent impactful patches.
  - — [Steam reviews](https://steamcommunity.com/app/1116170/reviews/?browsefilter=toprated&filterLanguage=english)
- Early Access complaints: co-op network bugs; exotics outclassed by the next mission's drops. — [Steam reviews](https://steamcommunity.com/app/1116170/reviews/?browsefilter=toprated&filterLanguage=english)

**CyberCorp: how the developer responded to combat-feel complaints**
- Update 20: "visualization of hits on enemies has been improved and depends on the type of damage inflicted"; passive regen delay cut from 3 s to 0.6 s. — [Update 20](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1783238125218992)
- Update 22: "enemies can now die from fire"; new finisher animations. — [Update 22](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1784506359047842)
- Update 26: "reworked game sounds". — [Update 26](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1789039014399823)
- Update 31: "Player bullet speed increased by 25%"; "Greatly increased player ability damage at higher levels". — [Update 31](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1799817379461768)
- EA recap: "Reworked damage system, finishers, enemy AI". — [Changes During EA](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1797185861772586)

**Combat Complex Steam players**
- Praise:
  - Twin-stick gunplay with three firing modes: "this, right here, is _magic_".
  - Enemies kill each other; luring enemies into hazards is "amusing".
  - Orbs "definitely" try to get you killed ("The game asks you to take chances").
  - Overheat instead of reload; screen shake and VFX.
  - Industrial maps give a "horrorish" feel.
  - — [Steam reviews](https://steamcommunity.com/app/1899300/reviews/?browsefilter=toprated&filterLanguage=english)
- Complaints and requests:
  - Basic affixes; it is hard to tell which gear is better; long sessions feel repetitive.
  - Weapon variety is "boring" and enemy manipulation feels like "happy coincidence".
  - Skill points tied to specific-weapon challenges (since replaced by XP).
  - Too many enemies; slow movement (fixed with +20% speed); collisions catching the player.
  - Poor frame rate on low-end GPUs.
  - Requested: crafting (since delivered), a bestiary, Diablo-style difficulty selection, orange-tier enemies, more story, music.
  - — [Steam reviews](https://steamcommunity.com/app/1899300/reviews/?browsefilter=toprated&filterLanguage=english); [Urgent Update](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6350729003502074780)
- Earlier snapshot: a search snippet reported "Mostly Positive (43) – 74%" at an earlier date, versus 81% of 66 now. — [Steam store](https://store.steampowered.com/app/1899300/)
- No professional critic reviews of Combat Complex were found.

### Inferences
- The "dull combat" critique of CyberCorp is mostly about feedback and impact, not encounter design:
  - melee that does little damage;
  - enemies that do not react to hits;
  - awkward finishers;
  - stiff movement.
  - Shooting itself is widely rated as solid. The Game8 review predates EA launch (Aug 16 vs Aug 19/20, 2024) and about 30 EA updates, so parts of it describe a build that later changed. Lack of hit reactions was still cited in Dec 2025.
- Combat Complex players respond to emergent systemic kills (friendly fire, hazards, orbs) and dislike opaque gear comparison and repetitive loot. Its strengths are systemic; its weaknesses are content breadth.

### Gaps
- I could not read the full Game8 text (HTTP 403). Its exact sub-scores, apart from a search snippet reporting "gameplay 6/10", and the full "Dull Combat" paragraph are unverified.
- The Steam reviews JSON endpoint redirected, so the analysis uses the 10 top-rated English reviews per game rather than a full corpus. Recent-review percentages were not shown on the store fetch.
- No Reddit threads were checked, because of the tool-call budget.
- Console release dates are unconfirmed. Entertainment Geekly lists PC, Switch and Xbox Series. NoobFeed's "Released August 20, 2024 on PC and Nintendo Switch" conflicts with Switch appearing later and is likely inaccurate. The Nintendo Life eShop page returned HTTP 400.

---

## 6. Developer devlogs and patch notes explaining design decisions

### Takeaway
- **CyberCorp**'s developer writes in the first person as a single dev, citing "4440 hours" of playtesting. They shipped weekly patches during EA (about 30 major updates, "500+ bugs fixed"), and changes were mostly reactive (pity, targeted loot, unstuck, cheaper card extraction).
- **Combat Complex**'s posts are unusually explicit about design intent:
  - hazards that break "Always shoot" and "Always dash" habits;
  - balancing build "productivity" against mechanical effort;
  - making death less punishing;
  - in-the-moment tutorials;
  - spawn budgets.

### Cited Findings

**CyberCorp**
- Development history:
  - "Even after playing 4440 hours while making the game, there are still errors." — [FAQ](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6909171012610572433)
  - The EA delay (Mar 2024) was due to "multiplayer connection and synchronization", "inventory UX is still clumsy", and "hard mode, elite enemies, epic items for late game… not balanced yet". — [Game Release is Delayed](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5686430301732964824)
- Pity system reasoning: "If an exotic item has a 10% drop rate, it doesn't actually mean that after completing 20 missions you'll get 2 exotics… with the pity system, each mission increases the odds, to reduce long losing streaks, and the overall gameplay experience will feel fairer." — [Update 21](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1783872411985212)
- Responses to feedback:
  - Removed voice-over from the start cutscene "due to negative feedback".
  - Enemy voices off by default.
  - End-level timer raised from 10 to 30 s.
  - Level clamp on old missions softened after "the bad review".
  - — [Update 2](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5875595438685255725); [Update 7](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6240387642451087153)
- 1.0 changes:
  - "Grenades and abilities no longer one-shot teammates — friendly fire damage has been reduced".
  - Survival co-op now shares one life with revives.
  - — [1.0 Out Now](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1797185861802763)
- After 1.0, updates slowed (Updates 31-35, May-Oct 2025). The team cited side projects (Koloboke, Matreshka) and later launched *Lord of Undead*. — [Autumn Update post](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1810503566386914); [Bundle post](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1849827110425457)

**Combat Complex**
- Hazards that break autopilot habits: "Deflector Walls (to break the pattern 'Always shoot'). Laser Walls (to break the pattern 'Always dash')." Hazards are to be randomized into regular missions, not only affixes. — [Roadmap](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6250522009527845924)
- Threat must match perceived danger: lasers in "No Going Back" were "perceived as high-damage, which makes them look far more threatening than they currently are… the modifier will eventually be reworked into using some other damage dealing method". — [2024-10-07](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6350729003509882555)
- Death and onboarding: the Mar 2025 update addresses "death being too punishing and the game being too harsh on new players". Mistake Mitigator "demands mechanical skill that new players don't yet have", so it was replaced as default by Safeguard. — [2025-03-12](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1794014851393086)
- Teaching the signature mechanic early: the Plasma Turret was added to "make the first tutorial mission more engaging… and to demonstrate our signature Friendly Fire mechanic… on the first introductory mission". — [2025-06-26](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1803527891510116)
- Contextual tutorials: when cornered, the game grants temporary invulnerability and prompts the Ultimate. If melee enemies attack and the player doesn't switch, it prompts a Shotgun switch. Each prompt shows once per mission. — [2026-05-13](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1832700592787374)
- Default ability swap: Contact Grenade replaced Gravity Vortex as the default. Gravity Vortex has the "highest damage potential" but its "learning curve was too steep for new players". — [2026-06-06](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1834602721194038)
- Productivity versus effort: Lightning Gun was nerfed and Flamethrower and Railgun buffed, "to balance the 'productivity' of a build (i.e. its ability to clear missions quickly and safely) with the effort required for running the build". — [2026-03-15](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1826992588600158)
- Readability fixes:
  - Melee strikes are marked with a red marker under the attacker.
  - Player rim light and red damage flash.
  - Laser beams shake when their bot is hit off-screen.
  - Wrecking Ball slam radius is telegraphed.
  - The "nearby enemies" check now uses collider-to-collider distance.
  - — [2026-04-25](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1830797770239127); [2026-04-19](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1830163047264795)
- Progression clarity: Skill Stations were replaced by XP because the old system was "clunky, hard to understand, and, at times, confusing". — [2025-10-18](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1813674389000805)
- Achievements lesson: "it's better to release achievements with the initial release of the game, instead of postponing them for a couple of years as we did." — [2026-04-19](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1830163047264795)
- Why Early Access: "To collaborate with players on development and to help with finances". Post-1.0 support "depend[s] on financial performance". — [Steam store](https://store.steampowered.com/app/1899300/); [Pinned roadmap thread](https://steamcommunity.com/app/1899300/discussions/0/4756452548787980214/)

### Inferences
- Lessons for a developer building a similar game, inferred from both games' histories:
  1. Signpost the critical path and exit conditions in procedural levels: decals, sounds, prompts.
  2. Keep loot on death and put risk on temporary buffs or opt-in modes.
  3. Add spawn-budget and flank caps.
  4. Ensure every damage type can answer common defences (red shields, guns against shields).
  5. Invest early in hit reactions, impact, and melee feel. This is the most persistent CyberCorp complaint.
  6. Teach the signature mechanic in the first mission.

### Gaps
- Neither developer published a technical devlog on level-generation algorithms.
- CyberCorp's Discord and Combat Complex's Steam discussions beyond the roadmap were not mined.
