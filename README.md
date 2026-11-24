# Combat (greybox prototype)

Top-down arcade twin-stick action RPG against alien bug swarms. Godot 4.7, GDScript, Forward+.
Everything is built from primitives; the look follows the concept art in `reference/`.

## The dive: "First Dive"

You drop into a mining megastructure over the abyss to steal data from the reactor uplink.

1. **Infiltrate.** Five rooms: Drop Lift, Catwalk Deck, Switchgear Gallery, Pressure Lock, Reactor Ring.
   Bugs sleep and patrol. The **blade is quiet**; sleeping bugs, and patrolling bugs hit from
   behind, die silently. The **rifle is loud**: gunfire raises the hive alert meter.
2. **Uplink.** Start it at the terminal (E). The alarm wakes the station and you hold the zone
   while it uploads. Waves leap up from the void, burrow up, drop from above and crawl out of
   nests. A **purple elite** arrives halfway through.
3. **Extract.** Fight back to the lift you dropped in on and hold the pad until it arrives.

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
| Swarmer | Fodder that swarms your position |
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
| Restart after the dive | R | Back |
| Fullscreen | F11 | |

## Layout

```
scenes/          main, level, player, camera_rig, spawner, projectile, FX scenes,
  enemies/       swarmer, burster, shield_bug, sentry_turret
scripts/
  level/         level.gd (rooms, region-graph nav, spawn queries), level_kit.gd (greybox builders)
  enemies/       enemy.gd (base: stealth states, senses, entrances, tiers) + special types
  objects/       interactable, explosive_barrel, hive_nest, laser_grid, blast_door, extraction_lift
  ui/            hud + widgets (alert meter, minimap, objective marker, boss bar, ...)
  shaders/
  game.gd (autoload), mission.gd, hive_director.gd, spawner.gd, player.gd, fx.gd, pickups.gd, save_data.gd
ui/              hud.tscn
reference/       concept art (ignored by the importer via .gdignore)
```

## Where the tuning lives (all `@export`)

| Node / scene | What |
|---|---|
| Player | move, rifle, blade (damage, arc, combo, parry window), roll, health |
| HiveDirector | alert thresholds and decay, noise per weapon, hunting packs, alarm wave rates, enemy mix, loot bonus |
| Mission | uplink duration and zone radius, lift countdown, elite timing, uplink reward |
| Spawner | pool sizes, max alive, spawn warning times, swarm separation |
| Enemy scenes | health, speed, damage, senses (sight range and cone), shield arc, burst radius, beam timing |
| FX | hitstop, shake, damage numbers, explosion lights |
| Level | lamp colours per room, hive glow, void fog |
| WorldEnvironment / CameraRig | fog, glow, grading / framing, follow, shake |

The level layout itself (room rects, bridges, placements) is data at the top of `scripts/level/level.gd`.

## Dev helper

`scripts/debug_autoplay.gd` is a bot that plays the mission (also works as an attract mode):

```bash
godot --path . -- --autoplay --god
```

Flags: `--god`, `--stealth` (uses the blade on sleepers), `--skip-to=uplink`, `--shots=DIR`,
`--shot-times=a,b,c`, `--quit-after=SECONDS`, `--test-restart`. Every 2 s it prints FPS, frame
times, phase, alert, room and swarm stats, and it flags any bug that stops making progress.

The save file is `user://combat_save.cfg` (banked salvage, dives, extractions).
