# Combat (greybox prototype)

Top-down arcade twin-stick action RPG against alien bug swarms: dive, loot, extract, upgrade.
Godot 4.7, GDScript, Forward+.
Everything is built from primitives; the look follows the concept art in `reference/`.

## The loop

**The Rig** (hub) → pick a contract and depth → **dive** → extract with loot → back at the
Rig: equip, scrap, buy crates, spend perk points → dive deeper.

### The Rig (hub)
Walk up to a station and press **E** (Esc or E closes the panel):

| Station | What it does |
|---|---|
| Armory | Equipped gear and your stash. Compare any item against what you're wearing (DPS change or per-stat green/red), equip, unequip armour, scrap for salvage |
| Fabricator | Spend salvage on sealed crates (Field / Armory / Elite) |
| Augments | Spend perk points (one per level) on 12 permanent perks |
| Contracts | Pick a depth (1–5, unlocked by extracting) and deploy |
| Test range | Training dummies with a live DPS readout to try new gear |

### Gear
Six slots: **gun, blade, helmet, chest, boots, implant**. Four rarities that match the enemy
tiers: **common (white), rare (blue), epic (gold), legendary (purple)**. Higher rarity gives
stronger base stats and more random stats; legendaries add a unique effect. Item level comes
from the dive depth.

| Gun | Feel |
|---|---|
| Assault Rifle | All-rounder, 12 shots/s |
| SMG | Fast and a little quieter, short range |
| Scattergun | 7-pellet burst, loud, brutal up close |
| Rail Lance | Slow, huge hits, pierces 5 bugs |
| Hive Popper | Explosive rounds; the blast also hurts you up close |

Blades: **Mono-Blade** (fast) and **Breach Cleaver** (slow, wide, heavy).
Elements from stats: **burn** (damage over time), **shock** (arcs to 2 bugs), **cryo** (50% slow),
**corrode** (+25% damage taken). Crits deal 1.5x and more with crit-damage stats.

| Legendary | Slot | Effect |
|---|---|---|
| Hydra | Gun | Kills split your bolt into three more |
| Ruinmaker | Gun | Bugs you kill have a 35% chance to explode |
| Widowmaker | Blade | Blade kills heal 4 and refresh your roll |
| Bastion Core | Chest | After a roll, take 50% less damage for 1.5 s |
| Ghostwalkers | Boots | Rolls go 40% further and chill nearby bugs |
| Predator Visor | Helmet | Unaware bugs take double damage |
| Adrenal Spike | Implant | Kills stack +8% fire rate and speed (3 s, up to 5 stacks) |
| Overclock Chip | Implant | Every 8th shot also fires a piercing rail bolt |

### Progression and stakes
- **XP** from kills (more for tougher tiers and deeper dives), nests and the uplink. Levels give
  +4 max health and a perk point. XP is kept even if you die.
- **Loot** drops as light beams in its rarity colour; walk over it to pick it up. Purple elites
  always drop one, and the uplink drops a rare-or-better cache.
- **Everything you find on a dive (gear and salvage) is banked only if you extract.** Die and
  it's gone. Your equipped gear is always safe.
- **Depth** 1–5: bugs get +35% health and +18% damage per depth, waves +15%, elite odds rise,
  and gear level and rarity odds improve. Extracting at your deepest depth unlocks the next.

The profile is saved as JSON at `user://combat_profile.json`.

## The dive: "First Dive"

You drop into a mining megastructure over the abyss to steal data from the reactor uplink.

1. **Infiltrate.** Five rooms: Drop Lift, Catwalk Deck, Switchgear Gallery, Pressure Lock, Reactor Ring.
   Bugs sleep and patrol. The **blade is quiet**; sleeping bugs, and patrolling bugs hit from
   behind, die silently. The **rifle is loud**: gunfire raises the hive alert meter.
2. **Uplink.** Start it at the terminal (E). The alarm wakes the station and you hold the zone
   while it uploads. Waves leap up from the void, burrow up, drop from above and crawl out of
   nests. A **purple elite** arrives halfway through.
3. **Extract.** Fight back to the lift you dropped in on and hold the pad until it arrives.

**Health:** green orbs drop from kills (more often from tougher bugs, three from elites, two from
nests) and drift toward you only while you're hurt. You also recover slowly after about 6 s
without taking damage.

**Salvage** drops from kills, nests and the uplink. It's **banked only if you extract**; die and
you lose everything you were carrying. Higher alert means more enemies but bigger drops.

### Hive alert
| Level | What it does |
|---|---|
| Dormant | Bugs asleep or patrolling |
| Stirring | Bugs that hear noise come to investigate |
| Hunting | Packs burrow up or drop in near you every few seconds |
| Alarm | Uplink running: continuous waves, stronger if you arrived loud |

### Enemies
| Enemy | How to deal with it |
|---|---|
| Swarmer | Fodder that swarms your position. Every biter swells and rears up before it lunges, so keep moving (a blade hit interrupts the bite) |
| Burster | Explodes near you, and when killed. The blast hurts other bugs too, so pop it inside a crowd |
| Shield Bug | Frontal shield blocks bullets and blade. It turns slowly, so roll behind it (back hits do x1.5) |
| Sentry Turret | Wakes when it sees or hears you. Red aim line, then a beam that also cuts through bugs. Roll out, use cover, or **parry it with the blade** to reflect it |
| Tiers | Blue / gold / purple auras multiply health, damage and loot. Purples get a health bar |

### Hazards (they hurt everyone)
Explosive barrels, a switchable **laser grid** on the gallery-to-lock catwalk, a **blast door**
in the pressure lock (seal it behind you on the way out; it crushes bugs under it), and hive
nests (destroy them to cut off spawns).

## Controls

| Action | Keyboard / mouse | Gamepad |
|---|---|---|
| Move | WASD / arrow keys | Left stick |
| Aim | Mouse | Right stick |
| Attack (rifle / blade) | Left mouse | Right trigger |
| Roll (i-frames) | Space or right mouse | A / RB |
| Swap rifle / blade | Q or mouse wheel | Y |
| Interact | E | X |
| After the dive: back to the Rig / dive again | E / R | X / Back |
| Close a Rig panel | Esc or E | |
| Fullscreen | F11 | |
| Graphics quality HIGH / MEDIUM / LOW (saved) | V | |

### Low-end machines (Chromebooks, integrated GPUs)
Press **V** until the corner reads **LOW**. That turns off volumetric fog, SSAO, glow, shadows
and the point lights, swaps in a cheaper floor shader, renders at 67% resolution and caps how
many bugs can be alive at once. The corner readout shows your FPS.

If it's still slow, run the lighter **Compatibility** (OpenGL) renderer, which defaults to LOW:
in the Godot editor, *Project → Project Settings → Rendering → Renderer → Rendering Method* =
`gl_compatibility` (then restart the editor), or from a terminal:

```bash
godot --path . --rendering-method gl_compatibility
```

## Layout

```
scenes/          hub (the Rig, main scene), dive (the mission), level, player, camera_rig, spawner, projectile, FX scenes,
  enemies/       swarmer, burster, shield_bug, sentry_turret
scripts/
  level/         level.gd (rooms, region-graph nav, spawn queries), level_kit.gd (greybox builders)
  enemies/       enemy.gd (base: stealth states, senses, entrances, tiers) + special types
  objects/       interactable, explosive_barrel, hive_nest, laser_grid, blast_door, extraction_lift, training_dummy
  items/         loot.gd (item tables, generation, tooltips), player_stats.gd, perks.gd, loot_drop.gd
  hub/           hub_level.gd (the Rig)
  ui/            hud + widgets (alert meter, minimap, objective marker, boss bar, ...)
  shaders/
  game.gd + profile.gd (autoloads), mission.gd, hive_director.gd, spawner.gd, player.gd, fx.gd, pickups.gd
tests/           test_loot.gd (items/stats/save), test_hub.gd (stations, every weapon on the range, deploy)
ui/              hud.tscn
reference/       concept art (ignored by the importer via .gdignore)
```

## Where the tuning lives (all `@export`)

| Node / scene | What |
|---|---|
| `scripts/items/loot.gd` | gun/blade archetypes, armour bases, random-stat pools, legendaries, drop odds |
| `scripts/items/perks.gd` / `scripts/profile.gd` | perks and ranks / crate prices and odds, XP curve, depth item level |
| Player | movement, roll, base health, blade combo feel, parry window (weapon numbers come from gear) |
| HiveDirector | alert thresholds and decay, noise per weapon, hunting packs, alarm wave rates, enemy mix, loot bonus |
| Mission | uplink duration and zone radius, lift countdown, elite timing, XP and drop chance by tier |
| Spawner | pool sizes, max alive, spawn warning times, swarm separation |
| Enemy scenes | health, speed, damage, senses (sight range and cone), shield arc, burst radius, beam timing |
| FX | hitstop, shake, damage numbers, explosion lights |
| Level | lamp colours per room, hive glow, void fog |
| WorldEnvironment / CameraRig | fog, glow, grading / framing, follow, shake |

The level layout itself (room rects, bridges, placements) is data at the top of `scripts/level/level.gd`.

## Dev helper

`scripts/debug_autoplay.gd` is a bot that plays the mission (also works as an attract mode):

```bash
godot --path . res://scenes/dive.tscn -- --autoplay --god
```

Flags: `--god`, `--stealth` (uses the blade on sleepers), `--skip-to=uplink`, `--depth=N`,
`--gear=legendary|epic|random` (or `legendary:overclock`, `epic:shock` to force one effect;
test gear is never saved), `--fresh` (a brand-new level 1 character with starter gear, not saved), `--loot-demo`, `--shots=DIR`, `--shot-times=a,b,c`,
`--quit-after=SECONDS`, `--test-restart`. Every 2 s it prints FPS, frame times, phase, alert,
room and swarm stats, and it flags any bug that stops making progress.

Tests (they back up and restore your save):

```bash
godot --headless --path . --script res://tests/test_loot.gd
```

```bash
godot --headless --path . --script res://tests/test_hub.gd
```
