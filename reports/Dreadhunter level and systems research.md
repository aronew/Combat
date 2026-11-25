# Dreadhunter earns its satisfaction through feel, not cards

Dreadhunter feels good because its studio spent three years of Early Access patching one thing over and over: what happens on screen in the 300 milliseconds after you pull the trigger. Its level structure and upgrade systems are not where the feel comes from. It is a persistent, mission-based action RPG ("It is an RPG, no roguelite"). It has no in-run upgrade cards. Its procedurally assembled maps are the part players most often call "samey" ([Steam "Game systems" thread](https://steamcommunity.com/app/1553710/discussions/0/3878218962826693242/); [Steam reviews](https://steamcommunity.com/app/1553710/reviews/?browsefilter=toprated)). Its launch build was panned for guns that felt like "firing spitballs", which is close to what you found in your own game. Sentiment turned once the developers shipped camera shake and pop, player kickback, scaled damage numbers, stagger and death animations, knockback and hit-stop, and paired them with fast, dodgeable, aggressive enemies and a melee-finisher loop that refills health and ammo ([v0.016 "Combat Experience Revamped"](https://steamcommunity.com/games/1553710/announcements/detail/6560117310279030611); [v0.210 "Impactful Combat"](https://steamcommunity.com/games/1553710/announcements/detail/1803527891935346)). The other references fill the gaps Dreadhunter leaves:

- **Halo** keeps encounters unpredictable by varying context at a three-minute scale.
- **Doom** puts resources inside enemies and gates arenas on movement.
- **Destiny** gives each threat tier a colour and builds a strike grammar.
- **Warframe** uses a library of authored room tiles plus an intensity director.
- **CyberCorp and Combat Complex** show what goes wrong when hit reactions are weak or loot is lost on death.

For your Godot project, the order of work follows from this: fix the camera framing, enemy visibility and impact feedback first; then rebuild levels from authored rooms with loops, height and landmarks; then vary encounters by role and modifier rather than by count; and only then decide whether a card system belongs in the game at all. The evidence says it probably doesn't, in its current form.

## Five assumptions the research overturns

Several premises behind the current strike prototype don't survive contact with the evidence. The table below sets them against what the sources show. The rest of the report builds on these corrections.

| Assumption | What the research shows |
|---|---|
| Dreadhunter is a roguelite with in-run upgrades | The developer says "It is an RPG, no roguelite." Items, money and XP are kept when a mission fails, and no in-run upgrade drafts are documented. In-mission build changes come from loot drops, level-ups (full heal) and ability XP ([Game systems thread](https://steamcommunity.com/app/1553710/discussions/0/3878218962826693242/); [v0.113](https://steamcommunity.com/games/1553710/announcements/detail/1787858252851924)) |
| Its levels are a big part of why it feels good | Players praise the combat loop and criticise the maps: "All the maps are very similar"; "by Act 3 the same enemy encounters were starting to get stale" ([Steam reviews](https://steamcommunity.com/app/1553710/reviews/?browsefilter=toprated); [Current state thread](https://steamcommunity.com/app/1553710/discussions/0/588439869536242794/)) |
| Locked arena after locked arena makes good pacing | Doom 2016's hallway-to-lockdown loop was criticised as repetitive. Eternal added "combat between arenas", which Hugo Martin rated "as good as the arenas… if not better" ([Game Developer Q&A](https://www.gamedeveloper.com/design/q-a-evolving-the-combat-design-of-id-software-s-i-doom-eternal-i-); [Shacknews p.6](https://shacknews.com/article/116635/hell-razer-the-making-of-doom-eternal?page=6)) |
| Losing the haul on death adds good tension | Dreadhunter keeps loot on failure. Combat Complex removed loot loss in March 2025 to address "death being too punishing". CyberCorp kept all-or-nothing risk only as an opt-in mode ([Combat Complex 2025-03-12](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1794014851393086); [CyberCorp Update 12](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6341720536502998670)) |
| More, smaller, weaker bugs read as a horde | Bungie's playtests found the opposite. With weak enemies, 8% of players rated the AI "Very Intelligent". After HP and damage were raised, 43% did ([GDC 2002 p.16](https://halo.bungie.org/misc/gdc.2002.haloai/talk.html?page=16)). Dreadhunter's enemies are mostly as large as the player or larger, and never small dark shapes ([Steam store media](https://store.steampowered.com/app/1553710/)) |

## Dreadhunter is a mission RPG whose feel was patched into place

### What the game actually is

Structurally, Dreadhunter is simple. The campaign is four acts, each a planetary "system" on the ship's starmap. Each act holds replayable missions. Act I launched with **12 missions across 10 environments** ([Game systems thread](https://steamcommunity.com/app/1553710/discussions/0/3878218962826693242/)). A mission runs like this:

- You arrive by drop pod on a map assembled at load time from "handcrafted arenas suitable for combat" with "carefully defined combinations of monsters" ([Gameplay Preview, 2022](https://steamcommunity.com/games/1553710/announcements/detail/4980448574107998350)).
- You push through rooms of small and then medium enemies, kill a bounty boss, and leave through an exit portal.
- You have three revives. A fourth death restarts the mission on a newly generated map, and you keep everything you earned.

One reviewer summed up the loop: "you load in, you dunk some small mobs, you then dunk some medium mobs, you then dunk their dad aka the boss, get the goodies and extract" ([Steam reviews](https://steamcommunity.com/app/1553710/reviews/?browsefilter=toprated)).

The level tools are modest:

- **No secret rooms.** The developer said hidden passages "slowed the experience" in testing ([Feedback thread](https://steamcommunity.com/app/1553710/discussions/0/3879346999818270475/)).
- **Chests are highlighted and marked on the minimap.** Players asked for this until it shipped ([v0.206](https://steamcommunity.com/games/1553710/announcements/detail/1797820624535321)).
- **Room size is the main lever on density.** "Smaller rooms in first three missions for higher enemy density" ([v0.011](https://steamcommunity.com/games/1553710/announcements/detail/5218041989058738966)).

Ordinary rooms appear to aggro on sight rather than lock you in, though the Act IV trailer does project "LOCKED" onto an arena exit during a fight ([Steam store media](https://store.steampowered.com/app/1553710/)).

### Where the satisfaction comes from

The combat loop is Doom's push-forward economy turned top-down. The mech carries light, medium and heavy guns, each with its own ammo, plus a melee weapon that needs none. In the 2023 build, gunfire stunned enemies, and finishing them in melee paid out health and ammo. "If you keep shooting at them, they eventually die, but without giving health or ammo" ([JeuxOnLine preview](https://jv.jeuxonline.info/actualite/63517/apercu-dreadhunter)). Designer Matouš Ježek's December 2024 essay sets out the three pillars:

- **Health Recovery Through Action:** "You can't simply run and wait for your health to restore."
- **High Mobility:** a "relatively long dash with a short cooldown, enabling constant motion".
- **Dynamic Enemies:** "The enemy attacks are set up so that if you stop, they will quickly hunt you down."

([ARPG Combat Innovation](https://steamcommunity.com/games/1553710/announcements/detail/1785774543666984)). The dash uses charges, shown as three pips ([Feedback thread](https://steamcommunity.com/app/1553710/discussions/0/3879346999818270475/)). The enemy brief rules out unfair attrition: "Each enemy attack can be avoided by dash or simply by proper positioning… there are no soldiers with machineguns who would simply spray bullets on you" ([Gameplay Preview](https://steamcommunity.com/games/1553710/announcements/detail/4980448574107998350)).

### The feel was built in passes

None of this felt good at launch. The most helpful negative review on launch day said the guns felt like "firing spitballs… the little bubble blowing puff that popped out of my massive, techno looking assault rifle". It named Synthetik's handling as the benchmark ([Steam reviews](https://steamcommunity.com/app/1553710/reviews/?browsefilter=toprated)). The developer admitted the shooting "didn't meet industry standards" and shipped fixes in passes:

| Date | Pass |
|---|---|
| Nov 2023 | Camera shake and pops on shots, melee, dash and explosions; exposure flashes; kickback "pushing player backwards slightly while shooting"; reworked hit flash; "Damage numbers scale… based on how heavy the attack is"; better player-hurt feedback ([v0.016](https://steamcommunity.com/games/1553710/announcements/detail/6560117310279030611)) |
| Jul 2025 | "New hit, stagger, death animations… New physical impact on enemies" ([v0.210](https://steamcommunity.com/games/1553710/announcements/detail/1803527891935346)) |
| Aug 2025 | More melee knockback "for higher satisfaction" ([v0.213](https://steamcommunity.com/games/1553710/announcements/detail/1808601382438594)) |
| Oct 2025 | "Hit stop effect - frames freezing during melee combat and crit hits"; longer-lasting blood; charged melee ([v0.215](https://steamcommunity.com/games/1553710/announcements/detail/1813041031178575)) |

By 2026, forum posters described the loop as "punchy, movement feels good… super satisfying" ([Current state thread](https://steamcommunity.com/app/1553710/discussions/0/588439869536242794/)). The remaining complaints are about content: guns within a family feel alike, deaths look like enemies "just vaporize after falling over", and encounters repeat ([Insights thread](https://steamcommunity.com/app/1553710/discussions/0/594035508989193220/); [Build diversity thread](https://steamcommunity.com/app/1553710/discussions/0/565920396927477233/)).

Reception splits along the same line. The game sits at **77% positive of 148 Steam reviews**. Seven of the ten most-helpful negative reviews cite price, and several of them still concede "The combat is incredibly fun" ([Steam store](https://store.steampowered.com/app/1553710/DREADHUNTER/); [Steam reviews](https://steamcommunity.com/app/1553710/reviews/?browsefilter=toprated)).

### The rival games show the same split

CyberCorp got the inverse verdict. Its shooting was rated "above-textbook". Game8 (60/100) still called the combat dull because melee lacked impact and enemies "barely flinch, ragdoll on death and that's it" ([OpenCritic](https://opencritic.com/game/18728/cybercorp/reviews); [CyberCorp Steam reviews](https://steamcommunity.com/app/1116170/reviews/?browsefilter=toprated&filterLanguage=english)). Its fixes followed the same playbook: hit visuals that depend on damage type, new finishers, reworked sounds, and **25% faster player bullets** ([Update 20](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1783238125218992); [Update 31](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1799817379461768)).

Combat Complex (81% positive) is the reference closest to your game: small insectoid bugs, catwalks over an abyss. Even there, the bugs carry bright yellow-green emissive markings, and the railgun muzzle flash is three to four times the player's size ([Steam store media](https://store.steampowered.com/app/1899300/)).

## Your game's look and feel miss on visibility and impact

### Framing

The visual analysis compared screenshots and trailer frames against your repository values. Your camera is in `scripts/camera_rig.gd`: pitch 54°, distance 19.5 m, vertical FOV 48°.

- **Yaw.** Both games use the same 45° diagonal.
- **Pitch.** Dreadhunter looks down at about **40-50°**. Ground circles read as ellipses with an axis ratio of 0.57-0.73, against 0.81 for your camera.
- **Hero size.** Dreadhunter's hero fills **11-14% of screen height**. Yours fills about 8%: a 1.8 m capsule inside a frame roughly 17.4 m tall and 31 m wide.
- **Silhouette.** Dreadhunter's hero is a 3 m power-armoured mech with an oversized gun, so it reads wide as well as tall ([Steam store media](https://store.steampowered.com/app/1553710/); [press kit](https://tricksterarts.com/dreadhunter/press_kit.html)).

Dreadhunter's players named the same problem you have: "we completely miss the feeling of being big". The fix was to rescale stairs, barrels and boxes "for better perception of Dreadhunter's size" ([Feedback thread](https://steamcommunity.com/app/1553710/discussions/0/3879346999818270475/); [v0.017](https://steamcommunity.com/games/1553710/announcements/detail/5395937983658337684)). Your rooms are carved from 36 m cells (`CELL := 36.0` in `complex_gen.gd`). That makes them large and flat around a small hero. The camera only adds to the sense of a tactical map rather than a body in a fight.

### Enemies and projectiles

The other two visual gaps are bigger than the camera.

**Enemies.** Dreadhunter puts 5-15 enemies on screen. They are bone-white, red or orange, about 1-2 times the player's size. Its elites and bosses are 2-10 times the player. Your enemies are small black bugs on dark floors, the opposite case.

**Projectiles.** Your bolts have radii of 0.045-0.11 m (`scenes/projectile.tscn`). Dreadhunter fires thick, beam-like tracers with star-burst muzzle flashes, magenta rocket trails, fire jets that cover a quarter of the screen, and red AoE telegraph circles. Kills leave red splats that stay on the floor ([Steam store media](https://store.steampowered.com/app/1553710/)).

### Feedback

Doom's AI team explains why these visuals matter for feel, not only for looks. Sustained damage moves a demon up a visible pain ladder: twitch, then falter or push-back, then a glowing stagger that offers a glory kill. Hit reactions depend on the weapon: the assault rifle pins imps, and shotguns stagger zombies ([Game Developer: AI of DOOM 2016](https://www.gamedeveloper.com/design/cyber-demons-the-ai-of-doom-2016-)). Glory kills are held to "hundreds of milliseconds, just because you want to keep the player moving" ([Bethesda](https://bethesda.net/en-AU/news/the-guts-and-gore-of-doom-glory-kills)).

Your build already has much of the machinery: hit-stop, shake, gibs, breaks and executions. The research points to scale and legibility as the missing pieces.

From the top, a 0.09 m-wide bolt hitting a dark 0.5 m bug cannot carry the hit. A thick, saturated tracer that hits a lit, player-sized enemy, makes it recoil, scales the damage number and pushes the shooter back slightly can. One Dreadhunter forum poster asked for deaths that differ by damage type: "ballistic dismemberment with bodies thrown across the room, explosive fine red mist with gibs, plasma vaporizing" ([Insights thread](https://steamcommunity.com/app/1553710/discussions/0/594035508989193220/)). That kind of per-weapon death is the cheapest way to give each of your guns its own identity.

### Readability and accessibility

Telegraphs have to be readable at speed. Dreadhunter's Act IV drew complaints that hazards and attacks "blend way too much" with the maps ([Act 4 difficulty thread](https://steamcommunity.com/app/1553710/discussions/0/565920396927424047/)). Combat Complex added fixes one at a time ([2026-04-25 update](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1830797770239127)):

- red markers under melee attackers;
- a player rim light;
- a slam radius drawn before the slam lands;
- laser beams that shake when their bot is hit off-screen.

Keep accessibility switches for the shake and flash you add. Dreadhunter had to ship toggles for camera shake, screen flashes and chromatic aberration ([Dec 2024 update](https://steamcommunity.com/games/1553710/announcements/detail/1786573930666965)).

## Encounters stop feeling predictable when context changes, not counts

### Halo: vary the context, let the player set the pace

Halo's "30 seconds of fun" is widely misread. Jaime Griesemer says it meant "a 3-second loop inside of a 30-second loop inside of a 3-minute loop that is always different". The AI owns the 30-second scale (cover, dives, grenades). Designers own the three-minute scale: the space, enemy mix, weapons, vehicles, and third parties that fight each other ([Engadget/Joystiq interview](https://www.engadget.com/2011-07-14-half-minute-halo-an-interview-with-jaime-griesemer.html)).

Bungie's 2002 talk gives the template that covered about 80% of Halo's encounters ([GDC 2002 p.18](https://halo.bungie.org/misc/gdc.2002.haloai/talk.html?page=18)):

- an interconnected space with flank routes for both sides;
- a "killing zone", an open area between two covered positions, so that "multiple enemies [can] fight at once without it degenerating into chaos";
- a collapse from "a large aggressive territory to a small defensive cluster".

Halo 3 formalised this as the "canonical encounter": enemies hold a territory, fall back, make a last stand, break, and are finished off, with "spice" added (snipers, turrets, dropships) ([Isla, Halo 3 Objectives](https://web.cs.wpi.edu/~rich/courses/imgd4000-d10/lectures/halo3.pdf)).

Leader death breaks followers. Bungie learned that even an exaggerated panic run was noticed by "less than a third of our users", so every signal has to be louder than seems reasonable ([GDC 2002 p.19](https://halo.bungie.org/misc/gdc.2002.haloai/talk.html?page=19)). Griesemer also stresses that Halo "lets the player set the pace". That supports keeping your quiet rooms with sleeping and feeding bugs as the openers before each fight.

### Doom: fair pressure

Doom adds the rules that keep a crowded screen fair:

- **Attack tokens** cap how many demons attack at once.
- **"Exposed cover":** enemies stand in the open near cover, where the player can see them.
- **Accuracy falls as player speed rises,** so moving is directly rewarded ([Game Developer: AI of DOOM 2016](https://www.gamedeveloper.com/design/cyber-demons-the-ai-of-doom-2016-)).

When Eternal's dash turned the player into "a souped-up racecar", id made fireball windups about twice as fast and the Mancubus blast nearly instant ([Game Developer Q&A](https://www.gamedeveloper.com/design/q-a-evolving-the-combat-design-of-id-software-s-i-doom-eternal-i-)). The lesson for you: lock the player's speed and dash first, then tune enemy telegraphs to match.

Doom's roster has three tiers. Fodder are resource pumps and distractions. Heavies are the real problem, each with a counter weapon or weak point. Rare "rule-breakers" like the Marauder force a change of approach ([Game Developer: Dark Souls design of DOOM Eternal](https://www.gamedeveloper.com/design/the-dark-souls-design-of-doom-eternal)).

### Destiny: threat colours, modifiers, counters

Destiny gives every tier a health-bar colour: red Minor, orange Elite, yellow Major, and a skull for bosses. Rewards scale with tier: in Destiny 1, a major dropped four orbs to a minor's one ([Destinypedia: Elite](https://www.destinypedia.com/Elite); [Orb of Power](https://www.destinypedia.com/Orb_of_Power)).

Its cheapest variety tool is the Taken. They reuse familiar silhouettes, each with one new ability "designed to counter Guardian abilities": an immunity beam on an ally, self-splitting, blinding bolts, knockback blasts ([Destinypedia: Taken](https://www.destinypedia.com/Taken)). A Dreadhunter player asked for exactly this: "reuse the current enemies but give them new variations or add modifiers" ([Current state thread](https://steamcommunity.com/app/1553710/discussions/0/588439869536242794/)).

At higher difficulties, Champions require a matching counter-effect, which turns loadout choice into a planning check ([Destinypedia: Champion](https://www.destinypedia.com/Champion)).

### Directors and budgets

Combat Complex spends a "biomass" budget split between front and rear spawns. Its tuning history shows how fast flank spawns become unfair:

- **Backspawn** originally added 30% extra enemies from behind on top of a full front wave (130% total). It was cut back to 100% total.
- **Random rear fodder spawns** were set at a 15% chance, then limited to one enemy type.
- **Spawn doors** now blink and play a sound ([2025-07-19](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1805431065400567); [2025-10-18](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1813674389000805)).

Warframe solves pacing on procedural maps in a different way ([MCV: GDC 2013](https://mcvuk.com/development-news/gdc-13-handling-ai-in-procedural-levels/)):

- a **tactical map** raises enemy count and strength as players near the objective;
- an **influence map** spawns enemies ahead of the player's line of sight;
- an **intensity curve** peaks, holds, then eases off.

Action designers converge on a cap of **three enemy types per fight**, rarely four, each with room to "do its best thing" ([Game Developer: melee level design](https://www.gamedeveloper.com/design/level-design-for-melee-combat-systems)).

### A roster plan for your bugs

Set against these sources, your four enemy types cover only part of a working cast:

| Role | Reference precedent | Your game today | Gap to fill |
|---|---|---|---|
| Fodder swarmer (resource pump) | Doom fodder, Hive Thrall | Swarmer | Make it player-sized or bigger, with emissive markings, and have it pay energy or health on execution |
| Leaper or charger | Dreadhunter chargers ("can no longer charge right when they see you"), Vex Minotaur | None | A telegraphed lunge with a long recovery: Halo's Hunter "good mistake" |
| Ranged harasser with dodgeable shots | Fallen Dreg: slow, dodgeable 3-4 round bursts | Turret only | A mobile spitter whose slow, thick globs get through the shield line |
| Frontal blocker | Halo Jackal, Cabal Phalanx | Shield Bug | Already good. Add a shield that covers a nearby ally (Destiny 2 Phalanx) |
| Suicide or area denial | Combat Complex friendly fire | Burster | Already good. Lean into chain reactions |
| Leader with morale break | Halo Elite or Brute Chieftain | Tier aura only | Followers scatter, loudly, when it dies |
| Support or priority target | Taken Goblin immunity beam, Doom Buff Totem | Nest (static) | A mobile buffer that shields or hastes others |
| Heavy with weak point | Doom heavies, Arachnotron turret | None | A large bug with breakable armour plates that change its attacks |

Sources for the table: [Dreadhunter v0.221](https://steamcommunity.com/games/1553710/announcements/detail/1832065502819768); [Destinypedia: Dreg](https://www.destinypedia.com/Dreg); [Isla 2008](https://gamedeveloper.com/game-platforms/in-depth-bungie-on-eight-years-of-i-halo-i-ai).

### Boss fights

Destiny strikes keep bosses from being damage sponges:

- **Immunity gates:** Sepiks Prime is "invulnerable but immobile" until the adds are dead. Bracus Zahn's shield needs a charge taken from a Centurion and dunked elsewhere.
- **Threshold phases:** at roughly two-thirds and one-third health, the boss relocates or summons a wave.

([Destinypedia: Sepiks Prime](https://www.destinypedia.com/Sepiks_Prime); [Bracus Zahn](https://www.destinypedia.com/Bracus_Zahn)). Dreadhunter shows the failure mode. Its bosses lean on summoned adds that double as the ammo supply, and its critics call the finales "a neverending swarm of adds" that "blur the big fights together" ([Tyrian Mollusk review](https://steamcommunity.com/id/tyrianmollusk/recommended/1553710)). CyberCorp had to make add spawns stop when its Nightmare boss died ([Update 31](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1799817379461768)).

## Levels need loops, height and landmarks built from authored rooms

### The shared recipe

Every reference that generates levels does it the same way: hand-authored pieces, a grammar that arranges them, and rules that guarantee required features.

- **Dreadhunter** assembles handcrafted rooms and arenas, with separate generators for caves, wall variants and bridge variants. Its minimap shows blocky rooms with 45° corners joined by short connectors ([v0.202](https://steamcommunity.com/games/1553710/announcements/detail/1794014851393099); [v0.203](https://steamcommunity.com/games/1553710/announcements/detail/1794102528310606)).
- **Warframe** builds each tileset from "at least 30 different tiles". Role strings (Start, Connector, Intermediate, Objective, Dead-end, Exit) are set per mission type, so the same tiles produce linear Exterminates or maze-like Survivals. The Ice Planet tileset targets "40-45 level variations" ([Warframe Wiki: Tileset](https://wiki.warframe.com/w/Tileset); [Building the Ice Planet](https://www.warframe.com/news/building-warframe-ice-planet)).
- **Enter the Gungeon** picks one of 4-8 authored graph "flows" per floor, each built around a loop or a fork. It injects special rooms by probability and fills nodes from "nearly 300" hand-made rooms on floor 1 ([Boris the Brave: Gungeon](https://www.boristhebrave.com/2019/07/28/dungeon-generation-in-enter-the-gungeon/)).
- **Path of Exile** checks density statistically: the team generates thousands of levels and charts monster and chest counts so each area is "not too bare or too dense" ([PoE forum interview](https://pathofexile.com/forum/view-thread/1654235)).

### What reached players

The fixes that reached players point one way. Diablo IV's open beta drew complaints about backtracking. Blizzard responded by:

- moving objectives onto main paths;
- having straggling monsters seek out the player;
- raising dungeon event odds from **10% to 60%**;
- giving carried objective items a +25% speed buff instead of a penalty.

([Blizzard retrospective](https://news.blizzard.com/en-us/article/23938289/diablo-iv-open-beta-retrospective-transforming-feedback-into-change)). Combat Complex widened corridors and cleared breakables off the critical path ([2024-10-12](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/6211118320229769832)). Doom's Lazarus Labs had a main room with dead-end hallways that played badly. id fixed it by adding portals that turned the dead ends into a loop ([PlayStation Blog](https://blog.playstation.com/archive/2017/05/12/classic-levels-deconstructed-the-beautiful-brutality-of-dooms-lazarus-labs)).

### Arena size

Arena size should follow mobility. "Games in which the player can quickly traverse large distances tend to have larger arenas" ([Game Developer: melee level design](https://www.gamedeveloper.com/design/level-design-for-melee-combat-systems)). Eternal's target was a "racetrack": too big feels slow, too small leaves the player "banging against the walls" ([Game Developer Q&A](https://www.gamedeveloper.com/design/q-a-evolving-the-combat-design-of-id-software-s-i-doom-eternal-i-)). Hades starts each biome with medium, walled rooms, where walls become a weapon through wall slams, and opens them up later ([Kotaku](https://kotaku.com/hades-level-design-is-less-random-than-it-seems-1845254545)).

### What the stills show

Dreadhunter's screenshots and trailers show the spatial vocabulary your levels lack:

- X-shaped and L-shaped walkways, three to four character-widths wide, with railings and neon edge strips, over voids filled with orange or teal fog and visible girders;
- a four-pillar combat room;
- a boss arena with a sunken purple X floor and wide staircases up to raised walkways, at least two or three height levels;
- organic cave floors that fall away into black;
- a landmark on every screen: a tower, a pod, a glowing floor shape.

([Steam store media](https://store.steampowered.com/app/1553710/)). Your Epic Isometric reference map uses the same vocabulary:

- about 15 rooms stepping down through two to four height levels, joined by at least five staircases, a spiral tower and ramps;
- low walls on the camera-far edges only;
- four round platforms over the void, joined by narrow bridges;
- a loop that connects the lower chain back to an upper ring.

Diablo I's patterns add four-pillar rooms and corridors that wrap around rooms ([Boris the Brave: Diablo 1](https://boristhebrave.com/2019/07/14/dungeon-generation-in-diablo-1); [ladyofthecake](https://ladyofthecake.com/diablo/dungeon.htm)).

### Your levels against this

Your `complex_gen.gd` places one rectangular room per 36 m cell and joins neighbours with 3-5 m bridges. That makes every room the same flat shape on a regular grid. Two consequences follow:

- **Rooms are large and featureless relative to your 4.5 m dash.** Your dash is 30 m/s for 0.15 s.
- **The strike path's quiet-arena-quiet rhythm is monotone in the same way Doom 2016's hallway-arena loop was.**

Your catwalks are already wider in character-widths than Dreadhunter's. The issue isn't their width. It is that they are the only connective tissue, and they carry no height, landmarks or fights.

### Where the evidence runs out

Nobody has published a sourced corridor width or arena size for a top-down game. The metrics in the next section are rules of thumb derived from these principles, not quoted numbers.

## Upgrades matter only when they change verbs or persist

Your pick-1-of-3 cards felt pointless, and the research explains why. In Hades, card-style choices work for five reasons:

- **Boons change verbs,** not numbers: an attack becomes chain lightning, a dash leaves a blast.
- **They come from themed god pools,** so committing to one god raises the odds of synergy.
- **Payoffs reward commitment:** Duo boons need two gods, and Legendaries need prerequisites.
- **They have two upgrade axes,** rarity and level.
- **They are slot-exclusive:** taking one Attack boon closes off the others.

([saschb2b: Hades boons](https://saschb2b.github.io/game-mechanics/games/hades/boons-and-gods), third-party analysis). Your cards mix stat bumps with legendary effects borrowed from gear. They have no slot competition and no synergy hooks, and they last one operation. Combat Complex is the cautionary twin. Its power-ups ("three power-ups, pick one, maybe reroll") last four missions and are lost on death. A player found the result "chunks of rogue-likes, ARPG, and extraction shooters… just not quite fitting together" ([Combat Complex 2024-11-24](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1783872412137112); [Steam reviews](https://steamcommunity.com/app/1899300/reviews/?browsefilter=toprated&filterLanguage=english)).

Dreadhunter takes the opposite route. Every non-basic item is "legendary" from the first drop: "Plasma guns shoot +2 projectiles", "Launch a barrage of homing missiles on Dash", "Kinetic guns have 50% chance to penetrate enemies". Stat mods are slotted on top later ([Itemization thread](https://steamcommunity.com/app/1553710/discussions/0/7098294773565024015/); [Steam store](https://store.steampowered.com/app/1553710/DREADHUNTER/)). This front-loads novelty. Its known weaknesses come later: "You see every gun and armor in 2-3 hours", and gear sets so strong "there isn't really a reason to go off set" ([Build diversity thread](https://steamcommunity.com/app/1553710/discussions/0/565920396927477233/)).

Each of the other games covers one of those weaknesses:

- **Destiny** limits players to one exotic weapon and one exotic armour piece, so exotics define a build rather than stack. Its 2017 removal of random perk rolls left duplicate drops "static and pre-determined" until Forsaken restored them ([Destinypedia: Exotic](https://www.destinypedia.com/Exotic); [Shacknews](https://shacknews.com/article/106603/destiny-2-forsaken-brings-back-random-rolls-which-can-be-broken-down-for-weapon-mods)).
- **Warframe** gets build tension from a capacity budget and slot polarity, with augments and corrupted trade-off mods carrying the identity ([Warframe Wiki: Mods](https://wiki.warframe.com/w/Mods)).
- **CyberCorp** adds a pity timer, because "a 10% drop rate… doesn't actually mean that after completing 20 missions you'll get 2 exotics" ([Update 21](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1783872411985212)).
- **Doom's Marty Stratton** offers the guiding rule: no "micro steps", and "You'll never regret your choices" ([Bethesda campaign preview](https://bethesda.net/en-US/news/inside-doom's-brutally-fast-single-player-campaign)).

The defensible conclusion is that your game's build expression belongs in gear and in the moment of the drop. A single strike operation is too short for a 5-to-8-card draft to grow into a build, and stat cards duplicate what gear already does.

## Prioritized changes for the Godot build

The list is ordered by expected impact on "satisfying and unpredictable" per unit of work. Items 1-4 change how every second of play feels. Items 5-9 change what each minute contains. Items 10-12 change why players return. Numbers are starting points, derived from the evidence above and your repository's current values.

| # | Area | Change | Concrete starting values | Evidence |
|---|---|---|---|---|
| 1 | Enemies (look) | Make enemies lit, saturated and larger. Give the swarmer bone or orange carapace with emissive glands. Show tiers with Destiny-style colour plus size | Fodder at 1.0x player height, elites at 1.5-2x, heavies at 3x. Emissive accents of 2-4 energy on dark floors | Dreadhunter and Combat Complex stills; Destiny tiers; Bungie's "tougher = smarter" playtest |
| 2 | Combat feel | Thicken and brighten everything the gun emits, and give each weapon family its own hit and death result | Bolt radius about 3x (0.045 → 0.15 m), with a length-stretched tracer. Star muzzle flash at 1-2x player size. Player kickback of 0.1-0.2 m per shot. Damage numbers sized by hit weight. Recoil and stagger on every hit, with a weapon-specific reaction (SMG pins, scattergun knocks back 1-2 m, rail lance pierces and ragdolls) | Dreadhunter v0.016 and v0.210; Doom's pain ladder; CyberCorp's +25% bullet speed |
| 3 | Camera | Frame the hero like Dreadhunter: closer and slightly lower | Distance 13-14 m at FOV 48 (or FOV 33-35° at 19.5 m). Pitch 45-50°. Keep the 45° yaw. Keep the player on screen during boss fights rather than framing the boss | Visual analysis; Dreadhunter boss-camera complaint |
| 4 | Movement and resources | Make the dash a charge pool, and tie recovery to aggression | 2-3 dash charges, each recharging in about 0.8 s. Remove passive out-of-combat regen in strikes, so health comes from executions and pickups. Tune enemy windups after locking the dash, not before | Dreadhunter dash pips and "Health Recovery Through Action"; Doom 2-charge dash and 2x-faster windups |
| 5 | Level layout | Replace one-rectangle-per-cell with an authored room library assembled by a role grammar. Add at least one loop per mission | 25-30 room scenes per destination, each with typed door sockets (`Marker3D`). Role strings such as `S C A C A L A E`. Room shapes: X, L, U, round, four-pillar, with sunken or raised centres. Room footprints 14-24 m with variants. Catwalks used only as short links | Warframe tilesets; Gungeon flows; Lazarus loop fix; Epic Isometric map |
| 6 | Level height and landmarks | Two or three floor heights per mission, joined by wide visible stairs and one-way drops. One oversized landmark per room. Coloured gradient fog with silhouettes in every void | Stairs at least 4 m wide. Tall walls only on the north and west sides (already your rule). A neon edge strip on every platform rim | Dreadhunter boss arena with stairs; user map; visual analysis |
| 7 | Pacing | Break the quiet-arena alternation. Put small fights in connectors, and give each operation a Destiny-style beat sequence | Traversal skirmish → hold-the-point (3 waves, lieutenant in wave 3) → open set-piece heavy → gate with alarm reinforcements → boss. Random events in about half of connector rooms | Eternal's "combat between arenas"; Destiny strikes; Diablo IV's 10% → 60% events |
| 8 | Encounter AI | Add attack tokens, speed-weighted accuracy and Halo-style territories, with fallback and last stand | 2-4 attackers holding tokens at once on normal difficulty. Spitter accuracy falls with player speed. Fallback below 75% alive, last stand below 40%. Followers scatter loudly when the leader dies | Doom AI; Halo 2002 and Halo 3 Objectives |
| 9 | Enemy roster and variety | Add a leaper or charger, a mobile spitter, a support buffer and a weak-point heavy. Cap each fight at three types. Add Taken-style modifiers and mission affixes | One new rule per variant (e.g. a swarmer that splits, a shield bug that shields neighbours). Per-sector affixes such as Backspawn, capped at 15-30% of the spawn budget, with blinking spawn sources | Destiny Taken; Combat Complex affixes and biomass budget; three-types-per-fight rule |
| 10 | Bosses and elites | Give finales immunity gates and threshold phases instead of add-spam | Immune until 2 support nests or adds are cleared. Phases at about 66% and 33% that relocate the boss or summon one capped wave. Adds stop spawning when the boss dies | Sepiks Prime and Bracus Zahn; Dreadhunter and CyberCorp add complaints |
| 11 | Upgrades | Cut the stat cards. Give build choice to in-run gear drops that change a verb and can be equipped on the spot. If you keep any draft, make it Hades-shaped | Every non-common drop carries a behaviour effect (Dreadhunter-style). Mark chests on the minimap. If drafting: slot-exclusive (blade, gun, roll, shockwave), themed pools, a two-card synergy payoff | Dreadhunter itemization; Hades boon analysis; Combat Complex reception |
| 12 | Loot stakes | Stop losing the whole haul on death | Keep found gear on death or failure. Move risk onto run-only buffs or an opt-in "stay for more" extraction mode. Add a pity timer for epics and legendaries | Dreadhunter keeps items; Combat Complex March 2025 change; CyberCorp pity and Extraction mode |

Cheap tooling makes these changes testable. Your `test_complex.gd` already generates hundreds of floors. Extend it the way GGG does: log each seed's role string, room count, enemy budget and chest count to CSV. That lets you check density ranges before you play ([PoE forum interview](https://pathofexile.com/forum/view-thread/1654235); [Warframe Wiki: Tileset](https://wiki.warframe.com/w/Tileset)).

## Conclusion

The research changes the diagnosis. Your game is not missing a system. It has executions, breaks, a shockwave, gibs, gated arenas, tiers and a director, which is more machinery than Dreadhunter shipped with. What it lacks is legibility at the scale the camera shows. Small dark bugs, thin bolts, a distant camera and large flat rooms quietly cancel out the feedback systems you already built. That is why Dreadhunter's turnaround came from visible impact passes rather than new mechanics, and why the first four items in the list above are mostly tuning and art rather than code.

The second lesson concerns predictability. Every reference that stayed fresh varied the three-minute context: room shape, height, enemy roles and modifiers, objective verbs, events. None of them did it by adding more of the same enemy or more cards between fights. Dreadhunter's own weakest reviews say exactly that about its maps. You can copy its feel and its persistent loot model, and improve on it with Warframe's authored tiles, Halo's encounter collapse and Destiny's role colours.
