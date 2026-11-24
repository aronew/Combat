# Combat (greybox prototype)

Top-down arcade twin-stick shooter against alien bug swarms. Godot 4.7, GDScript, Forward+.
Everything is built from primitives; the look follows the concept art in `reference/`.

## Controls

| Action  | Keyboard / mouse        | Gamepad              |
|---------|-------------------------|----------------------|
| Move    | WASD / arrow keys       | Left stick           |
| Aim     | Mouse                   | Right stick          |
| Fire    | Hold left mouse         | Right trigger        |
| Dash    | Space (or right mouse)  | A / RB               |
| Restart | R (on game over)        | Back                 |
| Fullscreen | F11                  |                      |

## Layout

```
scenes/    main, arena, player, enemy (Swarmer), projectile, spawner, camera_rig,
           death_burst, hit_spark, damage_number, materials/
scripts/   one script per scene + game.gd (autoload), fx.gd, palette.gd, shaders/
ui/        hud.tscn
reference/ concept art (ignored by the importer via .gdignore)
```

- `Game` (autoload): shared references, wave/kill/combo state, hitstop.
- `Arena` (`@tool`): builds the platform, bridges, rails, lamps, crates, hive and void
  from code, so it also shows in the editor. Use **Rebuild arena** in the inspector after edits.
- `Spawner`: wave director + enemy pool + spatial grid (separation and bullet hits).
- `FX`: every juice knob (hitstop, shake, particles, damage numbers) in one inspector.

## Where the tuning lives

| Node (in `main.tscn`) | What |
|---|---|
| Player | move speed/accel, fire rate, damage, bolt speed, spread, knockback, dash, health |
| Spawner | wave size/growth, enemy speed/health scaling, spawn pacing, swarm separation |
| FX | hitstop durations, camera-shake amounts, damage numbers, spark colours |
| CameraRig | pitch, distance, FOV, follow smoothing, look-ahead, shake response |
| WorldEnvironment | ambient, depth/height fog, volumetric fog, glow, grading |
| Arena | lamps, hive glow, crate layout, void fog volume |
| Swarmer (`enemy.tscn`) | contact damage, acceleration, knockback decay, leap/emerge timing |

## Dev helper

`scripts/debug_autoplay.gd` is a bot that plays the game (also handy as an attract mode):

```bash
godot --path . -- --autoplay --god --wave=7 --shots=screenshots --shot-times=4,8 --quit-after=10
```

Flags: `--god`, `--wave=N` (start at wave N), `--shots=DIR`, `--shot-times=a,b,c`,
`--quit-after=SECONDS`, `--test-restart`. It prints FPS, frame times and swarm stats
every 2 s and flags any bug that stops making progress.
