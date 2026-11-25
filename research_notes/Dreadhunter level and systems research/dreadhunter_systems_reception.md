# DREADHUNTER (Trickster Arts, Prague; Steam app 1553710): combat and progression systems, game feel, and player/press reception

Research date: 2026-11-25. Main primary source: the developer's full Steam announcement and patch-note feed (64 posts, Dec 2022 to Sep 2026), pulled from the Steam News API. Other sources: the Steam store page, Steam user reviews, developer replies in the Steam forums, and the press and previews that exist (few; no Metacritic critic reviews). Patch notes are dated because the game changed a lot during Early Access (EA).

Steam news URL prefix used below: `https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/<id>`. These are the canonical URLs the Steam News API returns for each post.

Status as of Nov 2026: the store page still shows the "Early Access Game" header. Act IV ("full story") shipped on 2026-09-21. One forum user (Sep 2026) called that update "1.0", but the store page contradicts this. The developer says endgame is "still to be decided" ([Steam store](https://store.steampowered.com/app/1553710/Dreadhunter/); [Act IV post, 2026-09-21](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1844115010501968); [Endgame? thread, 2026-09-21](https://steamcommunity.com/app/1553710/discussions/0/565920396927426714/)).

## 1. Combat: guns vs melee, switching, weapon types, ammo and health, dash and mobility, Doom-style resource loop

### Takeaway
The mech carries four weapons: three gun slots (light, medium, heavy), each with its own ammo, which you swap instantly, plus one always-available melee weapon that uses no ammo. The core loop is Doom-like. Guns stagger or stun enemies. Finishing them in melee is the main source of health and also gives ammo, while killing with guns alone gives no resources (per a 2023 preview). There is no passive health regeneration outside combat. A fast, short-cooldown, charge-based dash keeps the player moving against enemies that are fast and leap or charge. Melee began as a resource and finisher tool. It was reworked through 2025 (charged "soulslike" heavy attacks, hit-stop, melee-focused item sets) into a viable main build.

### Cited Findings
**Weapon loadout and switching**
- Pre-EA developer description (Dec 2022): "There are three gun sizes to equip your mech with. You can swap them instantly depending on the threat you are facing and ammo remaining." The gun types then were "kinetic, explosive and plasma", and "there are various melee weapons… something satisfying in smashing a group of aliens with a rocket hammer." ([Steam news "Gameplay Preview", 2022-12-08](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/4980448574107998350))
- JeuxOnLine preview (Peredur, 2023-10-23): the mech has 4 weapons, "3 distances: une légère, une moyenne et une lourde, et 1 de corps-à-corps" (light, medium and heavy guns, plus one melee weapon). The three ammo families are kinetic (bullets), plasma (energy balls) and explosive (detonating rounds). The reviewer found the guns within a family generic, with the rocket launcher the exception. ([JeuxOnLine](https://jv.jeuxonline.info/actualite/63517/apercu-dreadhunter))
- BeyondGaming preview (2023-10-16): you start with a machine gun and two "Energy Blades". Gun stats are global damage, rounds per minute, magazine size and recoil. ([BeyondGaming](https://www.beyondgaming.be/threads/preview-dreadhunter.26851/))
- QoL change (Jan 2025): "When your Light gun runs out of ammo, character switches to Medium instead of Heavy gun now", which confirms per-slot ammo and auto-switch on empty. ([Steam news "Onboarding and Tutorial", 2025-01-06](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1787858252851924))
- Mouse-wheel gun swapping exists (fix: "sensitivity during swapping guns using mouse wheel"). ([Steam news "Environments", 2024-10-06](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6350729003504572715))
- Developer on itemization (Oct 2023): "Guns are usually simple, except the big ones are closer to abilities from other games. Like large plasma gun or rocketlauncher or heavy machinegun spraying bullets." The store page markets "guns that already feel like special abilities". ([Itemization? thread, 2023-10-17](https://steamcommunity.com/app/1553710/discussions/0/7098294773565024015/); [Steam store](https://store.steampowered.com/app/1553710/Dreadhunter/))
- Gun families added over EA:
  - Missile Launcher with homing missiles ("Tired of aiming?", Dec 2023).
  - Disc Launcher with Ricochet and Split mechanics (May 2024).
  - Electro guns with a Shock debuff (Nov 2024; 33 electro items).
  - Fire guns with a Burning DoT (burning system May 2025; 20 fire items including 3 guns, Dec 2025).

  ([Steam news 2023-12-11](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5395938616809852384); [2024-05-31](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5742731639334722893); [2024-11-21](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1783872411988187); [2025-05-12](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1799088287954626); [2025-12-11](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1818752592123200))
- Named guns from reviews and forums: assault rifle, SMG (the developer calls one a Thompson/Hellriegel-inspired, short, large-spread SMG), chaingun, shotgun/heavy shotgun, grenade launcher, rocket launcher. A 2026 forum poster: "My Assault Rifle / SMG / Chaingun feel like the same gun, just with more or less DPS." ([Insights thread, 2025-09-30](https://steamcommunity.com/app/1553710/discussions/0/594035508989193220/); [Build diversity thread, 2026-09-22](https://steamcommunity.com/app/1553710/discussions/0/565920396927477233/))
- Developer on gun-family feel (Nov 2023): "Kinetic guns have a sharp kickback, plasma guns have a softer but still powerful recoil, and the rocket launcher is simply fun to handle. Heavy guns now feel heavier than ever." Also: "Kinetic guns are straightforward, they just become better. Plasmas may feel slow at start but easily become -different-" once the armor set is equipped. ([Steam news "Combat Experience Revamped", 2023-11-20](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6560117310279030611); [Feedback thread](https://steamcommunity.com/app/1553710/discussions/0/3879346999818270475/))

**Melee**
- Melee weapons over time:
  - Launch: Power Sword, Rocket Hammer and Spear (animations reworked 2023-10-23), plus starting Energy Blades.
  - Glass Katana (Jul 2024).
  - Typhoon Blades, which restore dash (Aug 2024).
  - Flaming Sword (Oct 2025).

  ([2023-10-23](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5218041989058738966); [2024-07-18](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5969041959964310981); [2024-08-14](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5875594803674002065); [2025-10-08](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1813041031178575); [BeyondGaming](https://www.beyondgaming.be/threads/preview-dreadhunter.26851/))
- Developer (Jan 2026): "Melee weapons don't have ammo." On melee-only play: "it just is not the regular RPG melee where one can stand, hold a button and wait till it's over. The combat is closer to souls like games where the player has to move and dash to avoid enemy attacks, and use light and charged melee attacks according to situation." ([Gladiator Update / New Melee thread, 2026-01-07](https://steamcommunity.com/app/1553710/discussions/0/693123831462711224/))
- Developer (Sep 2025): "Melee was never really the primary way of fighting in Dreadhunter, but step by step we're finding ways to make it more and more fun." This came with "Tweaked enemy reactivity to improve your chances dealing with them by using melee weapons". ([Steam news "Melee & QoL", 2025-09-03](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1809869180011517))
- Charged melee (Oct 2025, "the biggest gameplay change we've made so far"):
  - Press and hold for a heavier strike. Each weapon gets a special animation and an "ability like unique effect".
  - Developer rationale: "choosing between regular and charged attacks adds a layer of second-to-second tactics, a nice rhythm to combat".
  - Shipped with it: "Complex rework of enemy behavior - making melee combat viable", "Better Melee hits targeting to prevent missing enemies running at you", gamepad auto-aims attacks in the movement direction when the aim stick is idle, and "Hit stop effect - frames freezing during melee combat and crit hits".

  ([Steam news "Melee Charged Attacks", 2025-10-08](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1813041031178575))
- Melee sets (Dec 2025): 18 melee-focused items "that finally make melee a fully viable option". The developer: "Dreadhunter has always been mainly a twin-stick shooter." ([Steam news "The Gladiator", 2025-12-22](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1819386365102123))
- Early melee was a lunge: a 2023 player asked to "let the character move freely… instead of dashing forward while attacking". ([Feedback thread, 2023-10-20](https://steamcommunity.com/app/1553710/discussions/0/3879346999818270475/))
- Melee also breaks destructibles. Fixes include "Tightened constraints for targeting destructible objects with Melee attacks" and melee attacks no longer cancel ability casts. ([2025-03-20](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1794102528310606); [2023-12-21](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5410576585129765910))

**Resource loop (health and ammo), the "glory kill" analogue**
- JeuxOnLine (Oct 2023, translated): ranged fire at first stuns enemies rather than killing them. You finish them in melee to gain health and ammo. "Si on continue à tirer dessus, ils finissent par mourir, mais sans donner de santé et de munition" (if you keep shooting, they eventually die but give no health or ammo). "Si on tarde trop à les achever, ils se remettent à bouger et à attaquer" (wait too long and they get back up and attack). ([JeuxOnLine](https://jv.jeuxonline.info/actualite/63517/apercu-dreadhunter))
- BeyondGaming (Oct 2023): melee finishers cost no ammo and reward extra health and ammo. Multi-hit streaks show a flashy effect "similar to Doom Eternal". ([BeyondGaming](https://www.beyondgaming.be/threads/preview-dreadhunter.26851/))
- Steam reviewer (Feb 2024): "it feels almost like a top down Doom, including the finishers to get ammo, health, etc." ([Steam reviews, top rated](https://steamcommunity.com/app/1553710/reviews/?browsefilter=toprated))
- Temple of Geek (Nov 2024): "using melee attacks to replenish health and ammo", described as a rhythmic combat style. ([Temple of Geek](https://templeofgeek.com/dreadhunter-early-access-first-impressions/))
- Developer design essay (Matouš Ježek, Dec 2024), "Health Recovery Through Action": "Health regenerates only when you're actively engaged in combat. You can't simply run and wait for your health to restore. The primary source of healing comes from melee kills, requiring you to engage enemies up close. There are other ways to get health, but all require you to at least go and pick up health drops from the ground." ([Steam news "ARPG Combat Innovation", 2024-12-16](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1785774543666984))
- Other resource sources:
  - Destructible vending machines "drop money and health pickups" (Nov 2023).
  - The Banshee boss spawns more minions "to spawn more ammo drops for player" (Dec 2023).
  - Full heal on level-up (Jan 2025).
  - Ammo boxes in boss arenas now respawn after a delay: "no more running out of ammo in boss fights" (Jun 2026).
  - Ammo and health drop chances are affected by the difficulty handicap (May 2024).
  - Items, skill nodes and mods for "Health drops, Health Drops Heal, Armor" (Jan 2026).
  - Conductive Gloves drop ammo from electric damage (May 2025).

  ([2023-11-29](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5395937983658337684); [2023-12-11](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5395938616809852384); [2025-01-06](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1787858252851924); [2026-06-07](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1834602721195892); [2024-05-08](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5768625435390872259); [Gladiator thread](https://steamcommunity.com/app/1553710/discussions/0/693123831462711224/); [2025-05-12](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1799088287954626))
- Ammo tuning patches:
  - "Explosive weapons have more ammo" (Jan 2024).
  - "Electro weapons Ammo increased" (Mar 2025).
  - Kinetic set "Extra ammo changed from 75% to 50%" (Dec 2023).

  The developer says ability-tree nodes "assist you with health and ammo management" (Jan 2024). A Nightmare player in 2026 was "Cycling abilities between Barrage, Bulletstorm and Ball Lightning balanced between giving health and ammo." ([2024-01-26](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5519792046252688415); [2025-03-12](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1794014851393099); [Act 4 difficulty thread, 2026-09-21](https://steamcommunity.com/app/1553710/discussions/0/565920396927424047/))
- Player friction with the loop:
  - "You must melee to get ammo and health. You MUST melee to get ammo… I don't want to have melee forced on me to use my guns" (negative review, 0.1 h, Jun 2026).
  - "you run out of ammunition early on and then you just get nuked… melee gets you killed incredibly fast" (negative review, Hard mode, Mar 2025).
  - A 2026 forum user calls melee "only… for boxes and enemy finishers" before the charged-attack rework.

  ([Steam reviews, most recent](https://steamcommunity.com/app/1553710/reviews/?browsefilter=mostrecent); [Steam reviews, top rated](https://steamcommunity.com/app/1553710/reviews/?browsefilter=toprated); [Gladiator thread](https://steamcommunity.com/app/1553710/discussions/0/693123831462711224/))
- Stagger system (Nov to Dec 2023): stagger means a slow debuff. There are Stagger Strength and Stagger Duration mods. Enemies are not staggered during jumps and special actions. "Bosses can now be Staggered, while having 50% Debuff Duration resistance". Ionic Legs apply Stagger instead of Slow. Since Jan 2026, "Enemies Stagger animations now play no matter the source of the Stagger (previously only Melee damage)". ([2023-11-29](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5395937983658337684); [2023-12-21](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5410576585129765910); [2026-01-24](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1822556746163833))

**Dash and mobility**
- Developer (Dec 2024): "The character moves quickly and has relatively long dash with a short cooldown, enabling constant motion. The enemy attacks are set up so that if you stop, they will quickly hunt you down." ([ARPG Combat Innovation](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1785774543666984))
- JOL (Oct 2023): the dash "n'a pas vraiment de temps de récupération" (has no real cooldown). A 2023 player asked to move "the 3 dots of the dash count under the feet of the character", so the dash uses charges, shown as 3 pips. A 2026 player: "The dash is much shorter than I expected." ([JeuxOnLine](https://jv.jeuxonline.info/actualite/63517/apercu-dreadhunter); [Feedback thread](https://steamcommunity.com/app/1553710/discussions/0/3879346999818270475/); [Gladiator thread](https://steamcommunity.com/app/1553710/discussions/0/693123831462711224/))
- Dash across elevation: BeyondGaming says the dash is a gliding move for dodging, speed and navigation that "can carry Drey over higher obstacles, almost like a jump". Patches mention "broken player movement after dashing into final boss arena" and walls "flickering when changing elevation". ([BeyondGaming](https://www.beyondgaming.be/threads/preview-dreadhunter.26851/); [2023-10-26](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5229301621575588711); [2025-03-12](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1794014851393099))
- Dash-modifying items:
  - "+2 Dashes" and wings/jets that add dashes.
  - "Launch a barrage of homing missiles on Dash".
  - Leg gear that adds an explosion to the dash.
  - Retreat Leg Gear, which "Creates Small Grenades on Dash".
  - Dash-restoring Typhoon Blades, plus dash-related skill-tree nodes.

  ([Itemization? thread](https://steamcommunity.com/app/1553710/discussions/0/7098294773565024015/); [Game systems thread](https://steamcommunity.com/app/1553710/discussions/0/3878218962826693242/); [2022-12-08](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/4980448574107998350); [2023-12-11](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5395938616809852384); [2024-08-14](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5875594803674002065))
- Enemy design to match the mobility:
  - "Each enemy attack can be avoided by dash or simply by proper positioning… there are no soldiers with machineguns who would simply spray bullets on you" (2022).
  - Enemies have "special long-range attacks, leaps, teleports" (2024).
  - "Fiend melee attack 33% slower" (2025).
  - "Charging horned enemies can no longer charge right when they see you" (2026).

  ([2022-12-08](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/4980448574107998350); [2024-12-16](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1785774543666984); [2025-08-21](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1808601382438594); [2026-05-10](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1832065502819768))
- Abilities: cooldown-based actives on separate buttons.
  - Launch: Grenade and Barrage (rockets).
  - Turret (Mar 2024), Bulletstorm (Jul 2024; a channel that slows movement, with a skill node restoring 100% speed), Cannon (grenade-launching turret, Aug 2024).
  - Lightningstorm (Jan 2026), Ball Lightning ("low-cooldown", Apr 2026), Meteor Shower (Jun 2026).

  BeyondGaming: the grenade is "infinite-use… limited by a cooldown". ([BeyondGaming](https://www.beyondgaming.be/threads/preview-dreadhunter.26851/); [2024-03-29](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5749481331440643886); [2024-07-18](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5969041959964310981); [2024-08-14](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5875594803674002065); [2025-11-22](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1816849002016511); [2026-01-24](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1822556746163833); [2026-04-16](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1830163047257021); [2026-06-07](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1834602721195892))
- Aim assist: the Missile Launcher and Thunderhawk set target "Tired of aiming?" players. A controller aim-assist toggle was added in Mar 2025, and aiming uses a laser line plus a cursor that switches between orange and green depending on the background. ([2023-12-11](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5395938616809852384); [2025-03-20](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1794102528310606); [Feedback thread](https://steamcommunity.com/app/1553710/discussions/0/3879346999818270475/))
- Death and revives: "You have 3 revives, another death means mission restart and new map generated" (developer, Sep 2023). BeyondGaming: revives come back at half max health, and enemy positions don't reset. ([Game systems thread, 2023-09-26](https://steamcommunity.com/app/1553710/discussions/0/3878218962826693242/); [BeyondGaming](https://www.beyondgaming.be/threads/preview-dreadhunter.26851/))

### Inferences
- Inference: the loop is "guns soften or stagger, melee finishes for health and ammo, dash out", plus cooldown abilities. It is a top-down version of Doom (2016)'s glory-kill and chainsaw economy. Health and ammo are split between melee kills, drops and ability-tree effects rather than tied to one chainsaw-style resource. Whether the 2023 "stunned enemies get back up" state still works exactly this way after the 2025 to 2026 stagger and animation reworks is not confirmed (see Gaps). A 2026 review saying you "MUST melee to get ammo" suggests the melee-for-resources principle still holds.
- Inference: giving each gun slot its own ammo pool, and auto-switching to the next slot when one runs dry, is what makes "swap guns by situation and ammo" a real decision. Players who only want to shoot find the melee requirement intrusive, especially early, before ammo-gain items and skill nodes come online.

### Gaps
- No source states the dash's numbers (cooldown, distance, charge regeneration) or whether it has invulnerability frames. "Short cooldown", "no real cooldown" and "3 dots" are the only data points.
- No source gives explicit numbers for how much health or ammo a melee kill gives, or whether the 2023 "stun, then finish" state still exists in the Act IV build.
- Whether the light gun has finite ammo is ambiguous. A Jan 2025 patch implies it runs out, but a 2026 developer remark ("not much motivation to use the light weapon when there is no ammo limit") is unclear in context.
- No numeric gun stats (DPS, magazine, reload) were found.

## 2. Feel: hit feedback, enemy reactions, gore and explosions, camera; what "satisfying", "fast-paced" and "Doom-like" mean here

### Takeaway
Dreadhunter's feel came from repeated, explicit feel passes made in response to player criticism. At EA launch (Oct 2023) some players called the guns weak ("spitballs"). The studio responded with:
- a camera-shake, kickback and hit-flash pass (Nov 2023);
- new enemy hit, stagger and death animations with physical impact (Jul 2025);
- more melee knockback "for higher satisfaction" (Aug 2025);
- hit-stop on melee and crits, plus longer-lasting blood (Oct 2025).

By 2025 to 2026, players regularly describe the core loop as punchy, smooth and "super satisfying". They also say enemy deaths lack gore, and that encounters and guns feel samey later on.

### Cited Findings
- Developer (2022): "We wanted guns in Dreadhunter to feel special – heavy and empowering." ([2022-12-08](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/4980448574107998350))
- Launch-day negative review (Oct 18, 2023, 158 found it helpful): "Ballistics on guns are awful. Feels like you're firing spitballs… the little bubble blowing puff that popped out of my massive, techno looking assault rifle". The reviewer points to Synthetik ("Recoil, deviation, firerate, jamming, heat production, handling") as the benchmark: "the most important thing for any isometric shooter… is to make the guns feel good to shoot." ([Steam reviews, top rated](https://steamcommunity.com/app/1553710/reviews/?browsefilter=toprated))
- Early forum feedback (Oct 2023): "Gunplay feels a little weak, mostly being that sense of punch when shooting an enemy down." The developer replied that blood particles and knockback pushes already existed, but "There are no hit animations or procedural animations which may cause the feeling you are describing. We also want to experiment with light camera shakes." ([Feedback thread](https://steamcommunity.com/app/1553710/discussions/0/3879346999818270475/))
- "Combat Experience Revamped" (v0.016, Nov 2023). The developer admitted "the shooting experience and overall weapon handling didn't meet industry standards". Changes ([Steam news 2023-11-20](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6560117310279030611)):
  - camera shakes on gunshots, melee attacks and dash;
  - "Camera pops on melee attacks, dash and explosions";
  - "Camera exposure effects on guns and explosions";
  - "Kickback on weapons added - pushing player backwards slightly while shooting";
  - "Flash hit indication on monsters updated";
  - "Damage numbers scale added - based on how heavy the attack is";
  - complex hit-indication effects and sounds when the player is hit, and a death sound;
  - revised explosion damage sounds.
- The melee overhaul (Oct 2023) brought new animations and sounds "to make the whole experience much more satisfying". ([2023-10-23](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5218041989058738966))
- "Impactful Combat" (v0.210, Jul 2025): "New hit, stagger, death animations and related systems for enemies", "Weapon handling feel improved", "New physical impact on enemies". The aim was "to make fighting monsters even more satisfying without compromising on controls or flow… combat feel even more physical." ([2025-07-09](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1803527891935346))
- Aug 2025: "Increased knockback on melee weapons - for higher satisfaction". Oct 2025: "Hit stop effect - frames freezing during melee combat and crit hits", "Blood on ground stays longer". May 2025: "Detailed 'damaged' effect on enemies". Jan 2026: stagger animations play for any stagger source. ([2025-08-21](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1808601382438594); [2025-10-08](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1813041031178575); [2025-05-30](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1800991756344143); [2026-01-24](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1822556746163833))
- Accessibility pushback: "Some players requested a reduction in screen flashes and camera shakes in combat". Toggles followed for Camera Shake, Screen Flashes, Damage Numbers, Lens Flares and Chromatic Aberration (Dec 2024). Haptic controller feedback was added in Sep 2024. ([2024-12-20](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1786573930666965); [2024-09-12](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6250522009512659101))
- Audio as feel: one patch added an ability recharge sound "for no more glances needed". Sound remasters covered SMG shooting (Oct 2024), plasma guns (Jun 2025) and charged-attack sounds for all melee weapons (Nov 2025). Reviewers and BeyondGaming consistently praise the electro/techno and heavy-guitar soundtrack: "De pompende muziek… past voortreffelijk bij de wanorde van de combat" (the pumping music fits the chaos of the combat perfectly). Temple of Geek notes rooms "transition into combat stages where powerful music cranks up". ([2023-10-26](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5229301621575588711); [2024-10-25](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6212245217911859726); [BeyondGaming](https://www.beyondgaming.be/threads/preview-dreadhunter.26851/); [Temple of Geek](https://templeofgeek.com/dreadhunter-early-access-first-impressions/))
- Player praise for feel:
  - "Combat is very good, punchy, impactful and fun… the combination of ranged weapons/skills and melee make it the combat feel great" (Oct 2023).
  - "The combat is incredibly fun" (Oct 2023, negative review).
  - "Great feel and audio, I almost feel like this could use a feedback controller" (Nov 2024, negative review).
  - "The combat loop is easily the best part as its punchy, movement feels good, the guns/melee weapons feel good… the core twinstick style gameplay is super satisfying" (forum, Oct 2026).
  - "feels very slick, gun and then slice them up" (Jul 2026).
  - "This is THE BEST aRPG gameplay bar none!" (Sep 2026).

  ([Steam reviews, top rated](https://steamcommunity.com/app/1553710/reviews/?browsefilter=toprated); [Steam reviews, most recent](https://steamcommunity.com/app/1553710/reviews/?browsefilter=mostrecent); [Current state thread, 2026-10-08](https://steamcommunity.com/app/1553710/discussions/0/588439869536242794/))
- Splattercatgaming quote (store page): "This core gameplay loop is really really good and very well implemented here. The developers have figured out the magic sauce to make it work and it tastes good!" ([Steam store](https://store.steampowered.com/app/1553710/Dreadhunter/))
- Remaining feel complaints (forum, Sep 2025):
  - "there could be a bit more of a visual cue of an enemy being 'mauled'".
  - "While shooting feels nice the impact is somewhat lost that enemies just vaporize after falling over". The poster asked for per-weapon death states: ballistic dismemberment with bodies thrown across the room, explosive "fine red mist with gibs", plasma vaporizing.
  - Kiting exploit: "running in circles can really flabbergast melee enemies."

  ([Insights thread, 2025-09-30](https://steamcommunity.com/app/1553710/discussions/0/594035508989193220/))
- Readability and telegraphing complaints:
  - "the tall thin charging enemy sometimes just hits you from off screen" and "melee hits feel kind of random at times" (Sep 2026).
  - Act IV maps "blend way too much with the hazards, enemies attacks and so do some of the bosses attacks, which makes dodging almost impossible" (Sep 2026); the developer patched "fast spells" that could instakill and "spongy minions" (v0.953).
  - Small enemies and the laser line blend into red floors (2023).

  ([Build diversity thread](https://steamcommunity.com/app/1553710/discussions/0/565920396927477233/); [Act 4 difficulty thread](https://steamcommunity.com/app/1553710/discussions/0/565920396927424047/); [Feedback thread](https://steamcommunity.com/app/1553710/discussions/0/3879346999818270475/))
- Scale and "mech" feel: a 2023 player said "we completely miss the feeling of being big", and the developer agreed. Later patches added stairs, barrels and boxes with "more realistic scale for better perception of Dreadhunter's size". ([Feedback thread](https://steamcommunity.com/app/1553710/discussions/0/3879346999818270475/); [2023-11-04](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5288974951215029513); [2023-11-29](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5395937983658337684))
- Camera: isometric/top-down ("Vertical shooting is not possible", per BeyondGaming). In a boss fight, a 2023 player complained the camera "was trying to hold both of us - my character and the boss" and asked for it to stay on the player. ([BeyondGaming](https://www.beyondgaming.be/threads/preview-dreadhunter.26851/); [Feedback thread](https://steamcommunity.com/app/1553710/discussions/0/3879346999818270475/))
- "Fast-paced": the developer's thesis is that you "don't need to slow the game down". The design rests on high mobility (dash), no passive regeneration, and fast enemies with leaps and teleports. "Some players… say, 'The gameplay is too fast.' But it's not—try it!… keeps players in a state of flow." ([ARPG Combat Innovation, 2024-12-16](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1785774543666984))
- Pacing praise (Oct 2023 review): "you load in, you dunk some small mobs, you then dunk some medium mobs, you then dunk their dad aka the boss, get the goodies and extract… you could play 10 minutes or 3 hours". Temple of Geek: "each combat sequence is purposefully crafted", with breathing room rather than endless waves. ([Steam reviews, top rated](https://steamcommunity.com/app/1553710/reviews/?browsefilter=toprated); [Temple of Geek](https://templeofgeek.com/dreadhunter-early-access-first-impressions/))
- Enemy density was repeatedly raised to improve the "first impression": smaller rooms in the first missions (Oct 2023), a big density increase in the first 3 missions (Nov 2023), and new enemies that "can be especially unforgiving if you pause" (Nov 2024). ([2023-10-23](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5218041989058738966); [2023-11-15](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5322753221338878434); [2024-11-27](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1784506358975923))

### Inferences
- Inference: the documented feel stack is the developer's own checklist of what moved player sentiment:
  - camera shake and "pop" on shot, melee, dash and explosion;
  - player kickback while firing;
  - per-gun-family recoil profiles;
  - a hit flash on enemies;
  - damage numbers scaled to hit weight;
  - enemy hit, stagger and death animations with physical push;
  - melee knockback;
  - hit-stop on melee and crits;
  - persistent blood;
  - strong player-damage feedback;
  - loud, punchy audio and music.

  Gore and death spectacle (bodies "vaporize after falling over") is the main gap players still name.
- Inference: providing shake and flash toggles was necessary. The heavy feedback that makes it satisfying also bothered part of the audience.

### Gaps
- No video frame-by-frame or GIF analysis was done, so camera distance, field of view and zoom behavior are not documented.
- No source documents gibs or dismemberment. One player said enemies "vaporize" after falling, which suggests limited gore as of Sep 2025.

## 3. Progression: skill tree, items (~40 at EA to 140+ now), loot sources, roguelike vs permanent, currencies, crafting/modding, difficulty

### Takeaway
Dreadhunter is not a roguelite. The developer: "It is an RPG, no roguelite." It is a mission-based ARPG with fully persistent progression:
- character XP and a large character skill tree;
- per-ability XP and ability trees;
- an item inventory with level-scaled gear;
- Credits for a Market (shop) and for modding;
- a stash.

The "roguelike" label some sites use refers only to procedurally generated levels and the optional Hardcore permadeath mode. Itemization is deliberately "upside down". Every non-basic item has a "legendary" effect from the start, usually a set-style armor piece that changes how a gun family, ability or dash works. Stat affix "mods" are slotted and upgraded on top. Content grew from about 40 items in Oct 2023 to "over 140 moddable items" by late 2026.

### Cited Findings
**Roguelike vs permanent**
- Developer Q&A (Sep 2023): "It is an RPG, no roguelite. You keep your items in the inventory… When you fail a mission you still keep your items, money and experience." Also: "You can re-spec anything, anytime." ([Game systems thread, 2023-09-26](https://steamcommunity.com/app/1553710/discussions/0/3878218962826693242/))
- BeyondGaming: it resembles Hades visually "but is not a roguelike or roguelite". Gamepressure, by contrast, lists "roguelike elements", meaning procedural locations and selectable difficulty. ([BeyondGaming](https://www.beyondgaming.be/threads/preview-dreadhunter.26851/); [Gamepressure](https://gamepressure.com/games/dreadhunter/z36490))
- Store page: "All environments in the story campaign are uniquely generated every time you enter them". Missions are replayable, and a mission fails after the 3 revives are used up. ([Steam store](https://store.steampowered.com/app/1553710/Dreadhunter/); [Game systems thread](https://steamcommunity.com/app/1553710/discussions/0/3878218962826693242/))
- No in-run upgrade drafts are documented. JOL describes scripted story missions followed by procedurally generated missions that repeat the gameplay without story. ([JeuxOnLine](https://jv.jeuxonline.info/actualite/63517/apercu-dreadhunter))

**Items, slots and how they change play**
- EA launch (Oct 2023): "the core gameplay systems, the first story act and around 40 items… 12 replayable, procedurally generated dungeons with bossfights and various difficulty levels including Hardcore (permadeath) mode." ([Steam news "Early Access Released!", 2023-10-18](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5218041989038767556))
- Item count over time:
  - Nov 2024: 33 electro items added "nearly 50% more equipment" (implying about 70 before).
  - Feb 2025 (Act III): "+100% items".
  - Late 2026: the store page's EA section says "over 140 moddable items".

  ([2024-11-21](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1783872411988187); [2025-02-19](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1792116353155890); [Steam store](https://store.steampowered.com/app/1553710/Dreadhunter/))
- Slots: three guns (light, medium, heavy), one melee weapon, and armor pieces (JOL counted 7 armor pieces in Oct 2023). Named slots and examples: helmets/headsets, pauldrons/shoulders, armor (chest), gauntlets/gloves, leg gear, wings/backpack.
  - Thunderhawk set (Dec 2023): Pauldrons "+30% explosion Damage" for missiles; Wings "Continuously launches Missiles at active enemies"; Armor "launches Missiles… while firing primary weapons"; Headset "+30% Damage on impact"; Gauntlets "+2 Missiles and +50% Missiles fire rate".
  - Grenadier Gauntlets: "+2 Small Grenades".

  ([JeuxOnLine](https://jv.jeuxonline.info/actualite/63517/apercu-dreadhunter); [Steam news 2023-12-11](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5395938616809852384))
- Developer's legendary-item examples (Oct 2023):
  - "Plasma guns shoot +2 projectiles".
  - "Plasma projectiles discharge Plasma arcs to nearby enemies".
  - "+2 Dashes".
  - "Launch a barrage of homing missiles on Dash".
  - "Explosive gun projectiles spawn 3 smaller grenades on hit".
  - "Kinetic guns have 50% chance to penetrate enemies".

  The developer's framing: "The itemization is sort of upside down, you get your special 'legendary' feature soon and then you can get the same item with better stats or (later) mod it by yourself." ([Itemization? thread](https://steamcommunity.com/app/1553710/discussions/0/7098294773565024015/))
- Store page: "ALL ITEMS ARE 'LEGENDARY'… All item drops you find have unique and meaningful upgrades to your mech, weapons or abilities." The Game systems Q&A adds: "when you play plasma build for example your character has a distinct 'plasma style' look." ([Steam store](https://store.steampowered.com/app/1553710/Dreadhunter/); [Game systems thread](https://steamcommunity.com/app/1553710/discussions/0/3878218962826693242/))
- Cross-cutting mechanics added over time:
  - Ricochet and Split for kinetic (May 2024).
  - Supports/summons (Turret, Cannon) with their own mods (Support Armor, Damage, Fire Rate, Duration, Range).
  - Shock (electro).
  - Burning.
  - Turret and Bulletstorm "now benefit from selected Penetrate/Split/Ricochet items and Skill Tree upgrades" (Jul 2024).

  ([2024-05-31](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5742731639334722893); [2024-05-17](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5747233970423204598); [2024-07-18](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5969041959964310981); [2025-05-12](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1799088287954626))
- Rarity means modding capacity. "Green stripes are 'rarity'… this item can have +1,+2 or +3 capsules in single modification row." Bonus mod slots on higher-rarity items were highlighted in Oct 2024. A "Perks system where higher rarity weapons have 1-3 perks" was announced as in progress (Oct 2026), along with "a rare consumable for removing rows on items". ([Itemization? thread](https://steamcommunity.com/app/1553710/discussions/0/7098294773565024015/); [2024-10-06](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6350729003504572715); [Current state thread, 2026-10-08](https://steamcommunity.com/app/1553710/discussions/0/588439869536242794/); [Build diversity thread](https://steamcommunity.com/app/1553710/discussions/0/565920396927477233/))

**Crafting, modding and currencies**
- Modding (v0.011, Oct 2023): "upgrade your weapons and armor pieces with various mods you collect in missions", done at a modding table on the ship. Its timeline:
  - Mods include Stagger Strength/Duration and Map Reveal (Nov 2023), Ability Crit Chance/Damage (Feb 2024), Shock Power (Nov 2024) and Burning Strength/Duration (May 2025).
  - Same-mod stacking was allowed and the modding UX improved (Sep 2025).
  - Damage from special item effects (missiles, small grenades) "scales by 2% for each item level".

  ([2023-10-21](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5218041989049375146); [2023-10-23](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5218041989058738966); [2023-11-29](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5395937983658337684); [2024-02-28](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5688680204366322328); [2025-09-03](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1809869180011517); [2023-12-21](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5410576585129765910))
- Currency: Credits ("money"), earned from mission bounties (scaled by difficulty since Oct 2023), from selling items, and from vending machines. The Market (Nov 2023) lets you sell items "or more importantly you have a chance to buy item pieces missing for your preferred build… the character progression is less about drop chances and more about your own preferences". Shop stock was increased (Mar 2025) and bulk quick-sell added (Jul 2025). A Stash came in Nov 2023. ([2023-10-26](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5229301621575588711); [2023-11-04](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5288974951215029513); [2023-11-11](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5302486388006302571); [2025-03-12](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1794014851393099); [2025-07-23](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1806064758575614))
- Player critiques of the economy:
  - "Instead of incremental upgrades that cost increasingly large amount of money" (Sep 2025).
  - "You barely have enough mods / money to upgrade anyway, and when you DO, it doesn't make much difference to your gameplay" (Sep 2026).

  ([Insights thread](https://steamcommunity.com/app/1553710/discussions/0/594035508989193220/); [Build diversity thread](https://steamcommunity.com/app/1553710/discussions/0/565920396927477233/))

**Loot sources**
- Loot comes from enemy drops (weapons, armor, mods), chests (with highlight effects, then marked on the overlay map and later the minimap), bosses (the first boss drops a Level 2 gun "to show a modded item earlier"), vending machines (money and health), the Market, and mission bounties. Changes over time:
  - "Default items don't drop in first few levels, to make initial drops more interesting" (Apr 2025).
  - "Significantly improved drop rates and drops quality for high level players" (Jul 2025).
  - "Adjusted drops from bosses on Melee hits" (Dec 2025).

  ([JeuxOnLine](https://jv.jeuxonline.info/actualite/63517/apercu-dreadhunter); [2023-10-23](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5218041989058738966); [2023-10-26](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5229301621575588711); [2025-04-26](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1797820624535321); [2025-04-04](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1795917897358239); [2025-07-23](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1806064758575614); [2025-12-22](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1819386365102123))
- Bosses: "The main objective of most missions is to find and hunt down a boss. Each story act then results in a boss fight with a massive monster." The store calls these "bounty bosses in each level". The developer described minibosses ending each mission and is "considering elites for endgame". ([2022-12-08](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/4980448574107998350); [Steam store](https://store.steampowered.com/app/1553710/Dreadhunter/); [Game systems thread](https://steamcommunity.com/app/1553710/discussions/0/3878218962826693242/))

**Skill tree and ability trees**
- At launch, the character skill points were flat stat buckets. Early criticism: "dumping a bunch of points in various categories giving +2-5% to an unknown stat for an unknown total is not fun". The developer agreed it was "the least interesting system". ([Feedback thread](https://steamcommunity.com/app/1553710/discussions/0/3879346999818270475/))
- New Skill Tree (v0.022, Feb 2024): "Instead of simply spending skill points on stats, we are introducing a proper skill tree… more interesting contextual progression… interplay with existing Items and Abilities". Branches were then added for:
  - Supports (May 2024);
  - kinetic Ricochet and Split (May 2024);
  - dash nodes (Aug 2024);
  - electro (Nov 2024);
  - burning (May 2025);
  - a Fire weapons branch (Dec 2025);
  - a melee subtree.

  "Completed" skill tree (Nov 2025): "tons of new nodes, especially the big ones… more meaningful choices earlier in the tree… large enough for you to explore a variety of builds, yet not so massive that it becomes overwhelming." ([2024-02-28](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5688680204366322328); [2024-05-17](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5747233970423204598); [2024-05-31](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5742731639334722893); [2024-08-14](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5875594803674002065); [2025-12-11](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1818752592123200); [2025-11-22](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1816849002016511))
- Character level cap is 50 (a Jun 2025 fix stopped it capping at 45). A character Stats screen was added Aug 2025 after "Most YouTubers and streamers were scrambling to find the character stats window." ([2025-06-22](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1802893906832519); [2025-08-04](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1806698490823036))
- Ability trees (reworked Jan 2024): "Some ability nodes simply add power, while others assist you with health and ammo management, and some alter the way abilities behave in combat." Max ability level went from 21 to 26 (25 ability points). Ability items found in missions can be "consumed for experience". Example node from JOL: a grenade that splits into three smaller grenades. A 2026 forum example: Barrage "Heavy target preference". ([2024-01-26](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5519792046252688415); [2023-10-23](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5218041989058738966); [JeuxOnLine](https://jv.jeuxonline.info/actualite/63517/apercu-dreadhunter); [Act 4 difficulty thread](https://steamcommunity.com/app/1553710/discussions/0/565920396927424047/))
- Developer framing of the archetypes (Jan 2026): "we started out by implementing a ranger character, then recently added systems for a warrior—and now, finally, a sorcerer!" This refers to gun builds, melee sets, and lightning/meteor abilities, all on the same mech. ([2026-01-24](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1822556746163833))

**Difficulty**
- Difficulty levels: Easy, Normal, Hard, Nightmare, plus Hardcore permadeath (skull icon, any difficulty except Easy). Bounties pay more on higher difficulty, Hard has been unlocked from the start since Mar 2025, and ammo/health drop chances are reduced by a difficulty handicap. ([BeyondGaming](https://www.beyondgaming.be/threads/preview-dreadhunter.26851/); [2023-10-26](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5229301621575588711); [2025-03-12](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1794014851393099); [2024-05-08](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5768625435390872259))
- Gating complaints:
  - "you can't play the higher difficulty until you clear the entire second highest difficulty, and when you move up… the story progress is completely reset… just enemy stats are boosted" (Jun 2025 review).
  - A 2026 thread asks to switch difficulty without a story reset.
  - A 2023 user noted Hard is "the point at which you start getting epic grade drops".
  - Nightmare (Jul 2026): "less ammo… enemies are stronger… fewer hit points. But it's no fun, the pace of the game is slowing down… same number of enemies."

  ([Steam reviews, top rated](https://steamcommunity.com/app/1553710/reviews/?browsefilter=toprated); [QoL difficulty thread, 2026-09-25](https://steamcommunity.com/app/1553710/discussions/0/588438602971940226/); [Feedback thread](https://steamcommunity.com/app/1553710/discussions/0/3879346999818270475/); [Nightmare difficulty thread, 2026-07-24](https://steamcommunity.com/app/1553710/discussions/0/588432892837959708/))
- Hub and meta features: the ship hub has a modding table, Market, Stash, star map and a trophy room displaying killed enemy types (May 2025). Save slots arrived in Jun 2025. There is no endgame yet: "Endgame is still to be decided based on success of this round of early access" (developer, Sep 2026). Co-op "would mean massive rework… possible only if the game becomes somewhat popular". ([2025-05-30](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1800991756344143); [Endgame? thread](https://steamcommunity.com/app/1553710/discussions/0/565920396927426714/); [Insights thread](https://steamcommunity.com/app/1553710/discussions/0/594035508989193220/))

**Itemization criticism (recurring)**
- "the gear and armor pieces are the same… You see every gun and armor in 2-3 hours" (2023). Martin ~ asked whether the "legendary" items were just plain white items with two generic affixes, as the screenshots showed (2023).
- "You have one set per skill / type, and that set adds so many stacking power boosts that there isn't really a reason to go off set… similar to the issue with Diablo 3s gearing system" (Sep 2026).
- "The guns you get in act 1 are the exact same guns you get in act 2… you need to find the same guns and armor again that match your level" (Jun 2026 review).
- "you must get all the gears first before trying a build" (2026).

([Itemization? thread](https://steamcommunity.com/app/1553710/discussions/0/7098294773565024015/); [Build diversity thread](https://steamcommunity.com/app/1553710/discussions/0/565920396927477233/); [Steam reviews, most recent](https://steamcommunity.com/app/1553710/reviews/?browsefilter=mostrecent); [Gladiator thread](https://steamcommunity.com/app/1553710/discussions/0/693123831462711224/))

### Inferences
- Inference: the "legendary from the start" design gives a strong early hook, since every drop visibly changes behavior. It also front-loads novelty. Once a player owns the full set for their gun family, later drops are mostly the same item at a higher level with small affixes. That explains the recurring "samey" and "seen everything in 2-3 hours" complaints, and the studio's planned rarity perks.
- Inference: for a developer wanting run-based "pick an upgrade" moments, Dreadhunter offers no direct template. Its in-mission build expression comes from loot drops, level-ups (full heal) and ability XP, not from roguelite drafts.

### Gaps
- No full item list or skill-tree node list was found. Only examples from patch notes and forum posts are available.
- The exact ability and armor slot count in the current build is not confirmed (JOL counted 7 armor pieces in Oct 2023).
- No source gives the current total of missions or environments. Oct 2023 had 12 missions and 10 environments for Act I; Act II doubled game time, Act III added about 50%, and Act IV was added in Sep 2026.

## 4. Reception: Steam review summary, recurring praise and complaints, Indie Cup Europe'24, review scores

### Takeaway
On Steam the game is "Mostly Positive" (77% of 148 user reviews, all time, as of 2026-11-25). The overwhelming complaint has been price ($34.99 / €35 during most of EA, reduced to $24.99 by late 2026), followed by thin content, repetition and stability or hitching. Praise centers on the combat loop, controls and soundtrack. The most-helpful reviews skew negative, mostly on price; the latest reviews (Jun to Sep 2026) skew positive. There are no aggregated critic scores (Metacritic has 0 critic reviews), and press coverage consists of announcement pieces and EA previews without numeric scores. It was nominated in three Indie Cup Europe'24 categories but won none, so 80.lv's "award-winning" headline is loose.

### Cited Findings
- Steam store, all reviews: "Mostly Positive (77% of 148)". No recent-review summary is shown. 37 curators. Price $24.99; bundle with OST $28.14 (−12%). ([Steam store](https://store.steampowered.com/app/1553710/Dreadhunter/))
- Price history: $35 / €35 at EA launch, with "no promotion planned during early access" (JOL). Reviews repeatedly cite "$35". In the Act IV post (Sep 2026) the developer says, "We also reduced the price of the game." A search snippet showed "Save 20% on Dreadhunter", meaning some sale took place (date unknown). ([JeuxOnLine](https://jv.jeuxonline.info/actualite/63517/apercu-dreadhunter); [Act IV post](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1844115010501968); [Steam reviews, top rated](https://steamcommunity.com/app/1553710/reviews/?browsefilter=toprated))
- My count of the 10 most-helpful English reviews (Steam "top rated" filter, fetched 2026-11-25): 2 recommended and 8 not recommended. 7 of the 8 negatives explicitly cite price ("nowhere near worth $35", "overpriced, underdeveloped", "a hard pill to swallow"). Several negatives still praise combat ("The combat is really good!"; "The combat is incredibly fun"). ([Steam reviews, top rated](https://steamcommunity.com/app/1553710/reviews/?browsefilter=toprated))
- My count of the 10 most recent English reviews (Jun 7 to Sep 25, 2026): 7 recommended and 3 not recommended.
  - Positive: "Great art style, engaging gameplay. Responsive controls"; "the dev keeps adding in absolute heat"; "REALLY good bones… could be a GUARANTEED hit, especially if had a console release".
  - Negative: "small game, too expensive… it's a tech demo… POE2, Last Epoch, etc, are within this budget"; same guns across acts; forced melee for ammo.

  ([Steam reviews, most recent](https://steamcommunity.com/app/1553710/reviews/?browsefilter=mostrecent))
- Content complaints:
  - Oct 2023: the shop and mod system were missing at launch, and one review said "The progression and customization mechanics are all currently locked under 'not available in early access'". The developer shipped modding in 5 days, the Market in about 2.5 weeks and the Stash in about 3.5 weeks.
  - May 2024: "Really only 4 ways to play… melee, kinetic, explosions, plasma. All the maps are very similar."
  - Jun 2025: "The level grind is glacial… samey fights."

  ([Steam reviews, top rated](https://steamcommunity.com/app/1553710/reviews/?browsefilter=toprated); [2023-10-23](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5218041989058738966); [2023-11-04](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5288974951215029513); [2023-11-11](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5302486388006302571))
- Performance and stability issues over time:
  - Launch crashes: "a single crash per several hours of gameplay, if any", with Fullscreen Window as a workaround (Oct 2023).
  - "The game constantly hard freezes" (Oct 2023 review).
  - "Some hitches in performance from time to time. Crashed several times in the 3 hours" (May 2024).
  - An engine update causing "initial stuttering due to shader recompilation" (Oct 2024), then shader prewarming added.
  - "If you notice stuttering, try switching Screen Mode… 'Fullscreen Window'" (Aug 2025).
  - The skill-tree menu "taxes the hardware more then it needs to" (2025).
  - Random teleport-to-map-edge bug (Mar 2025).
  - Navigation-mesh control bug when aggroing many rooms (developer, 2026).
  - "few times it crashed or had a frozen red screen" (Jun 2026).

  It is Steam Deck Verified (Nov 2023) and runs on ROG Ally. ([2023-10-21](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5218041989049375146); [2024-10-11](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6931694080295810923); [2024-10-25](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6212245217911859726); [2025-08-21](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1808601382438594); [Insights thread](https://steamcommunity.com/app/1553710/discussions/0/594035508989193220/); [Character movement thread, 2026-05-17](https://steamcommunity.com/app/1553710/discussions/0/837250707030663468/); [2023-11-08](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5302486387995755230); [Steam reviews](https://steamcommunity.com/app/1553710/reviews/?browsefilter=toprated))
- Developer's own assessment:
  - "After a bumpy Early Access release a year ago, it was clear that the game needed much more work to meet the quality standards expected by Steam users", and improvements had "already started to reflect in recent reviews" (Oct 2024).
  - "Early Access feedback made it clear—player expectations are sky-high" for a team of "just two developers" (Jul 2025).
  - The original plan was to finish EA in one year; it took 3 (Sep 2026).

  ([2024-10-18](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6212244583178813874); [2025-07-09](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1803527891935346); [2026-09-21](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1844115010501968))
- Team: "Two developers with 15+ years of experience each", Prague. Development began in early 2020, previous games have 15M+ downloads (the developer cites their earlier game MONOLISK), and EA came "after 3.5 years in development". ([Press kit](https://tricksterarts.com/dreadhunter/press_kit.html); [2023-10-18](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5218041989038767556); [Feedback thread](https://steamcommunity.com/app/1553710/discussions/0/3879346999818270475/))
- Indie Cup Europe'24 (nominees announced Jul 2024): Dreadhunter was nominated for the Gameplay Excellence, Rising Star and Critics' Choice awards, "selected from among 450 participants". Winners were The Darkest Files (Gameplay Excellence), Yes, Your Grace: Snowfall (Rising Star) and Phonopolis (Critics' Choice). ([GamesMarket, 2024-07-05](https://www.gamesmarket.global/largest-indie-cup-yet-many-studios-from-germany-and-switzerland-nominated-for-indie-cup-europe24-awards-e89d133ab564ec35f88769b9e34f7088/); [Steam news 2024-07-08](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/5842939267350716854); [Mezha winners, 2024-08-16 (via search summary; direct fetch returned 403)](https://mezha.ua/en/2024/08/16/the-winners-of-indie-cup-europe-24-have-been-announced-among-them-is-one-ukrainian-game/))
- 80.lv (Rita Hou, 2024-07-12), "Check out This Award-Winning Fast-Paced Shooter RPG": the body mentions only the three nominations and "mostly positive reviews on Steam". ([80.lv](https://80.lv/articles/check-out-this-award-winning-fast-paced-shooter-rpg/))
- Press and previews, none with numeric scores:
  - Temple of Geek (Kurosh Jozavi, 2024-11-02): "a solid foundation and impressive polish for an indie title… a must-try".
  - BeyondGaming (2023-10-16): smooth controls and excellent soundtrack, but "deze Early Access-versie… niet helemaal weet te overtuigen" (this EA version doesn't fully convince). Criticisms: scripted-feeling enemies, revives that don't reset enemy positions, repetitive and dull-colored maze-like levels.
  - JeuxOnLine (2023-10-23): "comme une démo" (like a demo), not recommended "en l'état" (in its current state), and hard to justify above €20.
  - Metacritic shows 0 critic reviews.

  ([Temple of Geek](https://templeofgeek.com/dreadhunter-early-access-first-impressions/); [BeyondGaming](https://www.beyondgaming.be/threads/preview-dreadhunter.26851/); [JeuxOnLine](https://jv.jeuxonline.info/actualite/63517/apercu-dreadhunter); [Metacritic](https://www.metacritic.com/game/dreadhunter/))

### Inferences
- Inference: the review score is weighed down mainly by price-to-content complaints during a long EA, not by the moment-to-moment combat. Even negative reviewers often concede the combat is good. For a developer this separates "feel" from "content breadth" as the two axes of reception.
- Inference: the sentiment trend is improving (most-helpful negatives are mostly 2023 to 2025; recent reviews are mostly positive). That matches the developer's 2024 claim. The 10-review samples are mine and small, not a Steam statistic.

### Gaps
- Steam's API endpoint for exact positive/negative counts by period could not be retrieved (it redirected), so no recent-period percentage is available. The store page shows no "Recent Reviews" summary.
- No professional numeric review scores exist; I found no OpenCritic or Metacritic critic entries.
- Steam's peak or concurrent player counts and sales figures were not researched or found.
- The four award banner images on the store page could not be read as text.

## 5. Comparisons reviewers draw (Doom, Diablo, Hades, Ruiner, etc.) and what they mean

### Takeaway
"Doom" is the dominant comparison. It means the melee-finisher-for-health-and-ammo loop, constant forward aggression, high-intensity shooting and the pumping metal/electro music. "Diablo" means isometric ARPG loot, levels and skill trees. "Hades" is mostly a headline and visual comparison (isometric, dash-heavy, flashy), and BeyondGaming explicitly says the game is not a roguelite. Other comparisons: Ruiner and Kill Knight (aesthetic and twin-stick flow), Synthetik (as the benchmark Dreadhunter's early gunfeel failed), The Ascent and Killsquad (genre and price peers), No Rest for the Wicked (souls-ish ARPG combat), Diablo 3 (set-gear dominance), and Vampire Survivors (enemy swarms).

### Cited Findings
- Windows Central headline (May 15, 2023): "'Dreadhunter' for PC looks like an unholy fusion between DOOM and Hades". The body does not explain the comparison; it only describes a "twin-stick shooter/action-RPG hybrid" with procedurally generated levels and about 40 items at EA. ([Windows Central](https://www.windowscentral.com/gaming/pc-gaming/dreadhunter-looks-like-an-unholy-fusion-between-doom-and-hades); [mirror with body text](https://jfiles.pages.dev/post/dreadhunter-for-pc-looks-like-an-unholy-fusion-between-doom-and-hades-udaxr))
- Doom as a resource loop: "it feels almost like a top down Doom, including the finishers to get ammo, health, etc." (Steam review, Feb 2024). BeyondGaming compares the multi-hit streak flash to Doom Eternal. ([Steam reviews, top rated](https://steamcommunity.com/app/1553710/reviews/?browsefilter=toprated); [BeyondGaming](https://www.beyondgaming.be/threads/preview-dreadhunter.26851/))
- Doom plus Diablo: Temple of Geek describes Doom's "free-roaming, high-intensity shooting" with "an isometric view and skill trees borrowed from Diablo". 80.lv pitches it "for fans of Helldivers, Doom, Diablo". A Steam review calls it "diablo-esque sci-fi/cyberpunk". ([Temple of Geek](https://templeofgeek.com/dreadhunter-early-access-first-impressions/); [80.lv](https://80.lv/articles/check-out-this-award-winning-fast-paced-shooter-rpg/); [Steam reviews](https://steamcommunity.com/app/1553710/reviews/?browsefilter=toprated))
- A Sep 2026 Steam review: "This is if No Rest for The Wicked and Doom 2016 had a cyberpunk-diablo baby!" ([Steam reviews, most recent](https://steamcommunity.com/app/1553710/reviews/?browsefilter=mostrecent))
- A YouTube EA first impression by RPG Division, linked by the developer, is titled "When Doom meets Aliens vs Predator". ([YouTube](https://www.youtube.com/watch?v=N2VaNK0FemQ); [Videos thread](https://steamcommunity.com/app/1553710/discussions/0/3879346999816503897/))
- Ruiner and Kill Knight: "kind a mix between Ruiner and Kill Knight with some Warhammer touch… perfect combo between gameplay/gameflow and artistic direction, the music is already classic" (forum, Oct 2026). ([Just congrats thread, 2026-10-17](https://steamcommunity.com/app/1553710/discussions/0/706660083369813738/))
- Hades: BeyondGaming says it resembles Hades visually but is not a roguelite. It also compares the chaos to Vampire Survivors and the starting Energy Blades to Halo. ([BeyondGaming](https://www.beyondgaming.be/threads/preview-dreadhunter.26851/))
- JeuxOnLine compares it to The Ascent (a full twin-stick RPG at €30) and Killsquad (closer concept, multiplayer, more polished, €25) to argue it was overpriced. ([JeuxOnLine](https://jv.jeuxonline.info/actualite/63517/apercu-dreadhunter))
- Negative benchmarks:
  - Synthetik, for gun handling (Oct 2023 review).
  - Death Must Die, for itemization: "Each item has potential to really enhance or change way you play" (2023 forum).
  - Diablo 3, for set bonuses overwhelming build choice (2026 forum).
  - POE2 and Last Epoch, for value (2026 review).

  ([Steam reviews](https://steamcommunity.com/app/1553710/reviews/?browsefilter=toprated); [Itemization? thread](https://steamcommunity.com/app/1553710/discussions/0/7098294773565024015/); [Build diversity thread](https://steamcommunity.com/app/1553710/discussions/0/565920396927477233/); [Steam reviews, most recent](https://steamcommunity.com/app/1553710/reviews/?browsefilter=mostrecent))
- Developer self-positioning: the developer frames Dreadhunter against modern ARPGs. It adds a dash and WASD/twin-stick movement but rejects automatic regeneration (which they argue forces "instakill" bosses), and it rejects slowing down into soulslike pacing as other ARPGs do. The charged melee is pitched as "Soulslike melee combat, no speed and flow compromises". ([ARPG Combat Innovation, 2024-12-16](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1785774543666984); [Melee Charged Attacks, 2025-10-08](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1813041031178575))

### Inferences
- Inference: when players say "Doom-like" about Dreadhunter, they consistently point to three things: (1) melee finishers that refill health and ammo, (2) pressure to keep moving forward and engage rather than kite and regenerate, and (3) aggressive music synced to combat. "Hades-like" is mostly about the camera, look and dash, not structure.
- Inference: the negative benchmarks show where a similar game should invest beyond feel:
  - gun-to-gun differentiation within a family (Synthetik-style handling variety, per-weapon perks);
  - items that change play throughout, not just at first pickup (Death Must Die);
  - avoiding single-set dominance (Diablo 3).

### Gaps
- The Windows Central article never explains its Doom/Hades comparison, so the headline cannot be attributed to specific mechanics.
- YouTube video content (Splattercat, RPG Division) could not be read; only titles and the store's Splattercat quote are available.
- No Reddit discussion of Dreadhunter was found by search.
