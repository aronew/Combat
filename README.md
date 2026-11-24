# Combat (greybox prototype)

Top-down arcade twin-stick action RPG against alien bug swarms: dive, loot, extract, upgrade.
Godot 4.7, GDScript, Forward+.
Everything is built from primitives except the Swarmer, which is a rigged Blender model
(see `art_src/README.md`). The look follows the concept art in `reference/`.

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
| Contracts | Pick a destination (Deepworks, Derelict Hauler, Furnace Chasm) and a depth (1–5, unlocked by extracting) and deploy, or try the small one-floor test level |
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

## The dive: "Deep Descent"

You drop into the Deepworks, a mining complex hanging over the abyss, to steal data from the
reactor uplink on its bottom floor. Every dive generates a new complex: rooms joined by catwalks
over the void, branching with dead ends and loops, so there's always somewhere to run.

### Destinations

Every contract picks where the dive goes. Each has its own floor themes, set pieces and what lies
under the floors:

| Destination | Setting | Under and around the floors | Set pieces |
|---|---|---|---|
| The Deepworks | Mining complex over the abyss | Misty void, giant columns, teal glow far below | Switchgear, servers, containers, tanks |
| Derelict Hauler | A hive-infested starship in orbit; almost every room is inside the hull | The ship's lower hull with running lights and engine vents, debris, stars and nebula, a gas giant | Deck pillars with red bands, hull windows onto space, hazard crates, cargo pods |
| Furnace Chasm | Foundry gantries | A molten lake (cooling crust over glowing seams), iron towers, orange uplight, rising embers | Crucibles and exhaust stacks trailing smoke, furnace pillars, ingot stacks |

Floor themes: Deepworks (Upper Decks, Switchgear Halls, Pump Works, Hive Foundry, Reactor Core),
Derelict Hauler (Cargo Spine, Crew Ring, Engineering Deck, Drive Core), Furnace Chasm (Slag Gantries,
Crucible Halls, Smelter Works, Furnace Core). Sky, fog, ambient and key light change with the
destination. Dev flag: `--dest=deepworks|starship|foundry`.

Part of every floor is **interior**: one or two clusters of rooms that fill their cells and form a
building, joined by walled corridors or opened straight into each other as long halls, with solid
structure between them instead of the abyss. Walls are tall at the back (north, west) and low at
the front (south, east) so the camera still sees in. No void edges there, so bugs burrow or drop in
rather than leaping up. The theme sets how much is interior: about a third of Upper Decks, Pump
Works and the Reactor Core, nearly half of the Hive Foundry, and most of the Switchgear Halls. On the
Derelict Hauler everything but the docking platform and the drive core is inside.

| Depth | Floors | Rooms (about) | Size vs. the old test level |
|---|---|---|---|
| 1 | 2 | 23 | ~7x |
| 3 | 3 | 42 | ~14x |
| 5 | 4 | 63 | ~21x |

Each floor has a theme (Upper Decks, Switchgear Halls, Pump Works, Hive Foundry, and the
Reactor Core at the bottom), and every room has a purpose that decides its name, props, floor
tint and walls: loading bays (hard cases, cable spools), hydroponics (planters), crew quarters
(lockers), control rooms (consoles), junctions, switchgear halls and server galleries (rows of
cabinets or racks), container yards, pump shafts (tanks, pipes over the shaft), pressure locks
(panelled bulkhead with a blast door) and the reactor ring. Far sides of rooms often get solid
walls with light strips and doors; open sides keep railings with tall lamp posts. Decks sit on
steel trusses over a glowing abyss.

**The hive is alive.** Unaware bugs don't stand around: packs feed on carcasses, some lie
burrowed under hive mounds and burst out when you get close (or make a racket), others mill
about, tend their nests, or roam between rooms. Sleepers breathe and twitch. Burrowed and
feeding bugs can be silently killed from any side; wanderers only from behind.

1. **Infiltrate, floor by floor.** The cargo lifts are dead: find and throw the **breakers**
   (yellow squares on the map; 1 on the first floor, 2 below) to power the floor's cargo lift,
   then ride it down. Breakers are loud. Bugs sleep and patrol. The **blade is quiet**:
   sleeping bugs, and patrolling bugs hit from behind, die silently. The **rifle is loud**:
   gunfire raises the hive alert meter. Your haul, health and some of the alert carry down with
   you (you patch up 25% on the ride).
2. **Uplink.** On the bottom floor, start it at the terminal (E). The alarm wakes the station
   and you hold the zone while it uploads. Waves leap up from the void, burrow up, drop from
   above and crawl out of nests. A **purple elite** arrives halfway through.
3. **Extract.** Fight back to the lift you rode down on and hold the pad until it lifts off.

**Map:** the corner map follows you and shows what you've explored (an arrow on its edge points
to the objective). Press **M** for the whole floor: explored areas, plus faint outlines of the
rest so you can plan a route.

The small hand-built **test level** (Drop Lift, Catwalk Deck, Switchgear Gallery, Pressure Lock,
Reactor Ring) is still there: Contracts → *Test level*.

### The blade
The blade is built to flow from bug to bug:
- **Target assist:** a swing snaps to the best bug in front of you (within about 6.5 m).
- **Dash-strike:** if that bug is out of reach, you zip to it (invincible while moving) and
  cut on arrival. About one every 0.6 s, twice as often while your chain is 3 or more.
- **Blade chain:** hits within 1.5 s of each other build a chain (shown under the combo):
  +8% damage per link up to +80%, and longer dash-strikes from 3 links.
- **Counter:** cut a bug while it rears up to bite and it's a **COUNTER**: x3.5 damage that
  goes straight through shield bugs' shields, a moment of slow-motion and a little health back.
- The 3-hit combo ends in a wide spin. Silent kills on unaware bugs and turret-beam parries
  still work.

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
| Map (whole floor) | M | Back |

The camera looks down at 45° (walkways run corner to corner). Movement is relative to the
screen: W is up-screen. The map is rotated to match.
| After the dive: back to the Rig / dive again | E / R | X / Back |
| Close a Rig panel | Esc or E | |
| Fullscreen | F11 | |
| Graphics quality HIGH / MEDIUM / LOW (saved) | V | |
| Volume down / up (saved; all the way down mutes) | - / = | |

### Sound
Everything goes through the `Audio` autoload (`scripts/audio.gd`). The sounds are in
`assets/audio/sfx` as `<name>_<n>.mp3`, made with ElevenLabs sound effects. All the takes of one
name form a bank: one is picked at random each time (never the same twice in a row), with a
little pitch jitter. To add variety, drop in another take (e.g. `rifle_shot_5.mp3`) and it is
picked up automatically.

- World sounds are positioned: you hear bugs to your left on the left, and quiet ones fade out
  with distance. The listener sits on the player, turned with the camera.
- Each place has its own ambience: the Rig, Deepworks (machinery + abyss wind, hive floors,
  reactor core), the Derelict Hauler (starship hull) and the Furnace Chasm (furnace + lava).
- Loops: the station alarm, the uplink, low health, laser fences, feeding bugs, burrow mounds,
  and skittering when a pack is closing in.
- The mix (volume, voices at once, pitch jitter, audible range) for every sound is the `MIX`
  table at the top of `audio.gd`.

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
  level/         level.gd (builds a floor, region-graph nav, spawn queries), complex_gen.gd (generated floors,
                 room purposes), level_kit.gd (deck/rail/truss builders, batched into MultiMeshes),
                 props.gd (prop catalogue: footprints, collision)
  player/        hunter_body.gd (the hunter's animated body: clips by move direction, aimed upper
                 body, swing/roll/hit/death one-shots, weapons, dash ghosts, rim glow)
  enemies/       enemy.gd (base: stealth states, senses, entrances, tiers) + special types
  objects/       interactable, explosive_barrel, hive_nest, laser_grid, blast_door, extraction_lift, training_dummy
  items/         loot.gd (item tables, generation, tooltips), player_stats.gd, perks.gd, loot_drop.gd
  hub/           hub_level.gd (the Rig)
  ui/            hud + widgets (alert meter, minimap, objective marker, boss bar, ...)
  shaders/
  game.gd + profile.gd + graphics.gd + audio.gd (autoloads), mission.gd, hive_director.gd, spawner.gd, player.gd, fx.gd, pickups.gd
tests/           test_loot.gd (items/stats/save), test_hub.gd (stations, every weapon on the range, deploy),
                 test_complex.gd (generates hundreds of floors: reachability, placements, sizes),
                 test_audio.gd (every sound the code plays exists, every file is used, loops loop)
ui/              hud.tscn
assets/          models (.glb from art_src/), shared materials, audio/sfx (sound banks)
art_src/         Blender Python scripts that build the models
assets/models/   enemies/ (rigged bugs) and props/ (set dressing), exported from art_src/blender
art_src/blender/ Blender Python scripts that build the models (see art_src/README.md)
art_src/vfx/     build_vfx.gd: authors the combat effects in scenes/vfx/ (see "Combat VFX" below)
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
| HunterBody (`scripts/player/hunter_body.gd`) | clip speeds, swing/roll/hit timing, weapon size and grip, material and rim-glow tuning, hero scale |
| FX | hitstop, shake, damage numbers, VFX registry and pool sizes, which gun uses which muzzle effect |
| `scenes/vfx/profiles/*.tres` | per-effect colour, intensity, scale, particle count, light, camera feedback (shake, kick, hitstop, distance falloff) |
| Level | lamp colours per room, hive glow, void fog |
| WorldEnvironment / CameraRig | fog, glow, grading / framing, follow, shake |

Generated floors: `scripts/level/complex_gen.gd` (floors and rooms per depth, themes, room
sizes and purposes, which props go where, wall chances, how many nests/turrets/laser fences,
population density and idle activities). Props are modelled in
`art_src/blender/build_props.py`; rebuild with `python art_src/blender/build_props.py`
(bpy 5.x) and reimport. The hand-built test level's
layout is data at the top of `scripts/level/level.gd`.

## Combat VFX

A small framework for weapon and impact effects, built from GPU particles, a few
camera-facing meshes, one shared shader pair and a short light:

- `scripts/fx.gd` is the VFX manager. `Game.fx.play_vfx(key, {position, direction, scale,
  color, intensity, follow})` takes an effect from its pool (the oldest one is recycled when
  the pool is full). `impact(surface, pos, normal)` picks the effect for the surface and
  `muzzle(gun_code, ...)` the gun's flash (`WEAPON_MUZZLE`; a gun without one keeps the old flash).
- `scripts/vfx/`: `VfxEffect` (pooled root: emitters, delays, recolouring, quality scaling),
  `VfxPulse` (one-shot scale/fade/light animation on a mesh or light), `VfxProfile` (the
  tunables), `CameraFeedback` (shake, directional kick and hitstop that fade with distance from
  the player; any system can use it), `Surface` (organic, metal, shield, environment).
- Surfaces: enemies have `surface_kind` (the sentry turret is metal), props can set the
  `surface` meta; anything else counts as environment.
- `scripts/shaders/vfx/`: additive (`vfx_add`) and alpha (`vfx_mix`) variants of one shader with
  procedural shapes (dot, streak, star, ring, eroding puff, hex ripple, flare). No textures.
- Effects so far: assault rifle muzzle, bullet impacts on the four surfaces, grenade explosion.
  They are authored in code: edit `art_src/vfx/build_vfx.gd`, then rebuild with
  `godot --headless --path . --script res://art_src/vfx/build_vfx.gd`.
- Particle counts scale with the graphics quality (100/75/45 %) and lights are off on Low.

**VFX arena** (contract board in the Rig, "VFX ARENA", or `scenes/test/vfx_arena.tscn`): a test
room with targets of each surface. Keys: `1` muzzle demo, `2` impacts on every surface,
`3` explosion at the cursor, `G` throw a grenade, `4` spawn a pack, `5` stress test,
`T` slow motion, `K` clear, `F1` stats (FPS, draw calls, pool use, live particles).

## Dev helper

`scripts/debug_autoplay.gd` is a bot that plays the mission (also works as an attract mode):

```bash
godot --path . res://scenes/dive.tscn -- --autoplay --god
```

Flags: `--god`, `--stealth` (uses the blade on sleepers), `--blade` (fights with the blade),
`--skip-to=uplink` (jumps to the bottom floor), `--depth=N`, `--classic` (the small test level),
`--seed=N` and `--floor=N` (a specific complex and floor), `--map-at=SECONDS` (opens the map),
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

```bash
godot --headless --path . --script res://tests/test_complex.gd
```

```bash
godot --headless --path . --script res://tests/test_audio.gd
```
