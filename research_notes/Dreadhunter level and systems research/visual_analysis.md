# Visual analysis: Dreadhunter, CyberCorp and Combat Complex (stills and trailer frames) plus isometric dungeon layouts

Method. Media lists came from the Steam store API (`appdetails`) for [Dreadhunter 1553710](https://store.steampowered.com/api/appdetails?appids=1553710&l=english), [CyberCorp 1116170](https://store.steampowered.com/api/appdetails?appids=1116170&l=english) and [Combat Complex 1899300](https://store.steampowered.com/api/appdetails?appids=1899300&l=english). Steam now serves trailers only as HLS/DASH, so I downloaded the 1080p HLS segments, joined them and extracted frames with ffmpeg at 960 px wide.

What I saved:
- Dreadhunter: all 16 screenshots, plus frames from four videos. The Early Access trailer (46 s) and the Act IV trailer (60 s) were sampled every 2.5 s. The "Gameplay - Thunderhawk" video (289 s) was sampled every 4 s, and "Gameplay - Electro Sets" (255 s) every 5 s.
- CyberCorp: 12 screenshots and the 1.0 trailer (58 s), sampled every 2.5 s.
- Combat Complex: 14 screenshots and the Early Access trailer (58 s), sampled every 2.5 s.

All files are in `stills/<game>/` and `stills/<game>/trailer/<video>/tNNNs.jpg`, where NNN is the approximate second. I viewed every screenshot and every frame as 3x3 contact sheets, then opened key frames at full resolution and drew grid overlays on some to measure them.

The dev's camera numbers come from `scripts/camera_rig.gd`: pitch 54°, yaw 45°, distance 19.5 m, and vertical FOV 48° (Godot default keep-height). The player capsule is 1.8 m tall with a 0.4 m radius (`scenes/player.tscn`). All pixel measurements below are my own estimates, accurate to about ±15%.

## Camera: angle, distance, player size on screen, arena field of view

### Takeaway
Dreadhunter uses almost the same 45° diagonal yaw as the dev's game. Its effective pitch is a bit lower, about 40-50°, and it frames the hero about 1.5x larger: roughly 11-14% of screen height, against about 8% for the dev's camera.

CyberCorp and Combat Complex look down far more steeply, at roughly 65-80°, close to straight down, with strong perspective splay on tall geometry. Combat Complex frames the player very small (about 6% of screen height) and relies on huge VFX and towering set pieces to fill the screen.

### Cited findings
- **Dreadhunter yaw.** Floors, walkways and walls run corner to corner on screen. The X-shaped catwalk crossing in `dreadhunter/shot_09.jpg`, the purple X floor in the gameplay video at `t216s`, and the factory walls in `gameplay_electro/t020s` all show the 45° diagonal view. This is the same yaw the dev uses. — [Steam screenshots/videos](https://store.steampowered.com/app/1553710/)
- **Dreadhunter pitch.** Ground circles read as ellipses:
  - The manhole cover in `shot_09.jpg` measures about 210 × 120 px, a ratio of 0.57. It sits in the upper quarter of the screen.
  - The red AoE telegraph circles in `shot_10.jpg`, `ea_trailer/t020s` and `gameplay_thunderhawk/t100s` measure ratios of about 0.65-0.73.
  - A ratio of sin(pitch) between 0.57 and 0.73 means the view ray meets the ground at about 35-47°, so the pitch at screen centre is about 40-50°. The dev's 54° gives a ratio of 0.81, so the dev's floor looks more "map-like" and less foreshortened.
- **Dreadhunter player size.**
  - `shot_09.jpg`: about 120 px tall in 1080 (11%), and about 175 px wide including the minigun.
  - `shot_01.jpg`: about 150 px (14%).
  - `gameplay_thunderhawk/t216s`: about 70 px in 540 (13%).
  - In the cave level (`gameplay_thunderhawk/t000s–t068s`), the camera is a bit further out and the hero is about 8-10%.
  - The silhouette is bulky power armour with an oversized gun, so it reads wide as well as tall.
- **Dreadhunter boss framing.** In boss scenes the camera pitches lower and frames the boss so large it fills the screen while the player becomes a small figure at the bottom. Examples: Moebius in `shot_05.jpg` and `act4_trailer/t040s–t050s`, and the giant spider in `shot_12.jpg` and `ea_trailer/t035s–t038s`.
- **CyberCorp.** The view is near top-down, about 60-70°. The player's selection ring looks almost circular in `cybercorp/shot_06.jpg` and `shot_11.jpg`. Lamp posts and building edges lean strongly outward from screen centre, which means a wide FOV and a high pitch. The player is about 110 px in 1080 (10%) in `shot_11.jpg`, and about 6-8% in the trailer (`trailer_1_0/t010s–t045s`). Foreground cables and a lamp post pass between the camera and the player without being hidden. — [Steam](https://store.steampowered.com/app/1116170/)
- **Combat Complex.**
  - The view is near top-down, about 70-80°, with strong vertical splay: towers and scaffolds lean outward in `combat_complex/shot_06.jpg`, `shot_11.jpg` and `shot_12.jpg`.
  - The player is tiny: about 70 px tall in 1080 (6.5%) in `shot_11.jpg`, and smaller in `shot_07`, `shot_08` and `shot_09` (hub rooms).
  - The camera shows a wide arena, roughly 3-4 room-widths of industrial walkway per screen. — [Steam](https://store.steampowered.com/app/1899300/)
- **Dev camera (my calculation from the repo values).**
  - At the focus distance, the frame is 2 × 19.5 × tan 24° ≈ 17.4 m tall and about 30.9 m wide at 16:9.
  - On the ground, it shows about 8 m toward the camera and about 16 m beyond the player, so about 24 m of depth.
  - A 1.8 m character at 54° projects to about 1.3-1.5 m of that 17.4 m, so about 8% of screen height.

### Inferences
- To match Dreadhunter's framing, the dev would have to move the camera about 1.4-1.6x closer (roughly 12-14 m at FOV 48), or narrow the FOV to about 32-35° at the current distance. Lowering the pitch to about 45-50° would also show more wall faces and character fronts. Dreadhunter's view feels "3/4 cinematic" rather than "tactical map".
- At 54° and 19.5 m, the dev's view is already between Dreadhunter (closer, lower) and Combat Complex (farther, steeper). A fully top-down feel like Combat Complex only works because its set dressing is extremely dense and its VFX are very large.

### Gaps
- Exact FOV and camera distance cannot be recovered from 2D frames. The pitch values come from ellipse ratios and assume circular ground decals.
- I found no zoom-in or zoom-out during normal play in the Dreadhunter gameplay videos. The camera stays fixed except for boss intros.

## Space: room sizes, corridors, chokepoints, height levels, cover, connections, loot

### Takeaway
Dreadhunter's spaces are not a grid of flat platforms. They mix:
- enclosed rooms with tall back walls,
- walkways 2-4 character-widths wide with railings, which form X and L junctions over a coloured, fog-filled void,
- irregular organic cave floors whose edges drop into pure black,
- boss arenas with a sunken or glowing centre and stairs up to a raised rim.

Every screen has a landmark: a tower, a pod, a glowing floor shape, or a big prop. Cover is sparse but present: pillars, pods, barrel clusters and tyres.

### Cited findings (Dreadhunter unless noted)
- **Walkways over a void.**
  - `shot_09.jpg` shows an X-shaped crossing of 4-5 m-wide catwalks (each arm about 3-4 player-widths). They have pipe railings with red-and-white posts, and the gaps between arms open onto an orange fog void with girders visible far below.
  - `shot_01.jpg` shows a hex-tiled walkway about 5-6 player-widths wide, with a teal fog void beyond a railing.
  - These are the closest match to the dev's catwalks, but they are wider, have railings and edge trim, and the void has colour, depth and fog instead of black.
- **Station level** (`gameplay_thunderhawk/t112s–t212s`).
  - Long corridors are lined by white-and-red ribbed walls with big circular logos, and glass panels and stasis pods sit along them.
  - Glowing cyan square floor lights are scattered as wayfinding.
  - A purple-glow channel (a lower trench or energy floor) runs down the middle of walkways (`t156s–t164s`).
  - Squared railed pits look down into teal void (`t168s–t184s`).
  - A room with 4 white pillars and cyan light caps (`t188s–t212s`) is a classic 4-pillar combat room.
- **Boss arena "Brain Implants Expert"** (`t216s–t284s`).
  - A large square room has a recessed purple-lit X-shaped floor in its centre, with arms about 2 player-widths wide.
  - Wide white staircases (8-10 steps) climb from the main floor to raised walkways around the edges (`t220s`, `t264s`, `t272s`).
  - The arena has at least 2-3 height levels, and enemies stream down the stairs.
- **Cave level** (`t000s–t104s`).
  - Organic open floors are about 3-4 screen-widths of continuous ground, with no right angles.
  - Floor edges fall into pure-black void at the bottom and sides of the frame, while tall rock walls rise at the top (camera-far) side. That is the classic "back walls tall, front open" occlusion solution.
  - Glowing green pod clusters act as landmarks and pickups.
  - The "Screecher" boss arena (`t072s–t104s`) is a large round clearing ringed by organic stalks with egg-pods.
- **Factory level** (`gameplay_electro/t000s–t040s`).
  - Enclosed rooms have tall back walls with green-lit panels, steel pylons, pipe railings dividing the floor, tyres and barrels as cover, and manhole details.
  - The "Steelmaster" boss arena (`t185s–t220s`) has flaming floor-grate hazards laid out in an X, with lamp posts lining walkways.
  - The temple area (`t090s–t130s`) has stone pillars, raised blocks, circular floor inlays, and torch posts with red lights at regular intervals.
- **Set pieces and level transitions.**
  - `ea_trailer/t000s`: a circular raised dais in a ribbed hall.
  - `t002s`: a giant glowing tower in the room's centre.
  - `t010s`: a white ramp or bridge between two levels.
  - `t022s`: a curved bridge with glowing tubes over red fog.
  - `act4_trailer/t025s`: a large circular platform with radial engravings, joined by straight bridges over a void.
  - `act4_trailer/t000s` and `t048s`: the word "LOCKED" projected on the floor at the arena exit while a fight is active.
- **Minimap.** A circular minimap at the top-right (every gameplay shot) shows level shapes as irregular room clusters joined by corridors, not a regular grid (`shot_09`, `shot_15`, `gameplay_electro/*`).
- **Loot.** Red and green supply crates and ammo boxes sit at corridor edges and corners (`gameplay_thunderhawk/t052s`, `t060s`). Weapon drops show in-world as glowing items (`act4_trailer/t002s` "New Items").
- **CyberCorp.** Dense, enclosed urban blocks: alleys 3-6 m wide crowded with crates, vending machines, cars, AC units, neon signs and trees (`cybercorp/shot_02`, `shot_06`, `shot_11`; `trailer_1_0/t010s–t045s`). Vehicles and crates are used as cover. The objective text (for example "Hack Terminal 1") drives the route.
- **Combat Complex.**
  - Multi-storey industrial structures: catwalks with railings, ladders and spiral stairs between floors (`shot_11.jpg`), scaffold towers and pipes.
  - It shows deep vertical voids: an orange abyss with walkways criss-crossing at different depths (`shot_12`), and a teal fog void with giant pillars (`shot_11`, `shot_00`).
  - Glowing blue hex-glass barriers act as walls.
  - The "Map" screen (`shot_04`) shows the run as sectors of 3-5 rectangular rooms joined by corridors, with modifiers per area.
  - The hub (`shot_07–09`) is a dressed interior: lounge sofa, workbenches, a medical scanner.

### Inferences
- The dev's flat rectangles on a 36 m grid with narrow catwalks are the single biggest departure. The references vary the plan shapes (X, L, U and round platforms, organic caves), make walkways wider with railings, add 2-3 height levels joined by visible staircases, and always place a landmark per space.
- Dreadhunter uses voids only next to walkways or at cave edges. Most fighting takes place in bounded rooms or wide floors.

### Gaps
- The trailers don't show a whole level end to end, so I could not measure total path length or count rooms per level.

## Combat presentation: enemy density and size, effects, deaths, damage numbers, HUD

### Takeaway
Dreadhunter puts 5-15 enemies on screen. Most are as big as or bigger than the player, and elites and bosses are 2-10x bigger. Enemies are lit, coloured silhouettes: red, orange or bone-white, and translucent blue for summons. They are never small black shapes.

Weapons produce thick bright tracers, star-shaped muzzle flashes, fire jets, lightning arcs and big explosions. Kills leave red gore splats on the floor. Stacked red and white damage numbers pop everywhere, along with "Critical!" and "Absorbed!" callouts.

### Cited findings
- **Dreadhunter enemies.**
  - Insectoid and demonic monsters with pale, white or bone-coloured carapaces and red gore highlights, about 1-2 player sizes. Examples: the scythe-armed beast in `shot_01`, the hulking white brute in `shot_09` (about 2x the player), crawling quadrupeds in `shot_09`, and translucent blue summoned spiders in `shot_13`.
  - Small swarmers are red or orange, glowing, and about player-sized (`gameplay_thunderhawk/t004s–t048s`).
  - Bosses range from about 3x the player (General Durcaan in `shot_10`) to bigger than the screen (Moebius and the spider).
- **Dreadhunter effects.**
  - Minigun: a yellow-white star-burst at the muzzle and a thick glowing beam-like tracer (`shot_09`, `shot_07`, `shot_04`).
  - Rockets leave magenta trails (`shot_09`). The flamethrower fills about a quarter of the screen with fire (`shot_00`).
  - Chain lightning arcs between enemies (`shot_03`, `gameplay_electro/*`). Electro-orbs appear as blue spheres (`shot_08`).
  - Grenades and explosions: big orange-red fireballs (`ea_trailer/t015s`, `act4_trailer/t005s`).
  - Enemy AoE: translucent red circle telegraphs on the floor (`shot_10`, `ea_trailer/t020s`, `gameplay_thunderhawk/t100s`).
  - Light beams and god rays from above (`gameplay_thunderhawk/t060s–t068s`, `t120s`).
- **Dreadhunter deaths.** Red blood splats and pools stay on the floor (`shot_04`, `shot_09`, `ea_trailer/t002s`, `gameplay_thunderhawk/t020s`). Explosive red-gib bursts appear in `shot_15` and `gameplay_thunderhawk/t176s`. I saw no visible ragdoll in the stills.
- **Dreadhunter text.** Floating numbers in red, white or pink, often stacked 5-10 per target ("202 202 202"). Callouts include "Critical!", "Absorbed!", "TARGET ACQUIRED" (a boss intro stamp) and "LOCKED".
- **Dreadhunter HUD.**
  - Bottom-left: a segmented red health bar with a blue shield or energy line below, small consumable pips, and 2 ability icons.
  - Bottom-right: 3 stacked weapon cards, each with an ammo count.
  - Top-right: a circular minimap. Top-centre: the boss bar with its name.
  - A chromatic-aberration and glitch treatment tints the HUD edges.
- **Dreadhunter screen shake.** Shake can't be confirmed from stills. The motion-blurred and glitchy frames during explosions (`gameplay_thunderhawk/t188s`, `act4_trailer/t048s`) suggest heavy post-processing on impacts. This is an inference.
- **CyberCorp.**
  - Humanoid gang enemies are the same size as the player and carry name labels ("RIFLER", "RANGER", "SYNDICATE FIGHTER") with pink segmented health bars and a purple crosshair icon (`shot_11`, `trailer_1_0/t010s`).
  - Tracers are thin orange or white. The boss mech "Komodo" has a red targeting circle (`trailer_1_0/t030s–t032s`).
  - Style feedback: a combo counter (top-right), a style-rank letter (D/C/B/A, `t012s`, `t018s`, `t025s`), and callouts "COOL DODGE!", "SO FAST!", "Break!!" and "TRIPLE KILL!!!" (`t015s`, `t042s`).
  - HUD: objectives and minimap top-left, a centre-bottom health bar, and weapon and ammo bottom-right.
- **Combat Complex.**
  - Enemies are small insectoid robots and bugs, about player-sized, with glowing yellow-green highlights and accents on dark floors. A white segmented larva appears in `shot_11`, and a centipede in `shot_13` and `ea_trailer/t045s`.
  - Weapon effects are enormous. The railgun fires a cyan feather-burst muzzle flash 3-4x the player's size with a long beam (`shot_00`, `shot_01`, `shot_10`, `shot_11`).
  - Enemy shots are orange teardrop bolts. Bouncing laser traps draw orange zig-zag lines (`shot_05`, `shot_12`, `ea_trailer/t000s`, `t025s`). Green acid clouds appear too.
  - Damage numbers are yellow, with decimals ("72,1"), plus status words "SLOWED", "STUNNED" and "Multistrike".
  - HUD: weapon silhouettes top-left, an HP bar "468 | 468" bottom-left, resource cube counts on the left, and 2 ability icons bottom-right.
  - The trailer's hook is "Turn their attacks against them / Enemies damage each other" (`ea_trailer/t022s`, `t020s`).

### Inferences
- The dev's small black bugs and thin bolt projectiles are the opposite of all three references, which make enemies light, saturated or glow-accented against their floors, and make projectiles thick, emissive and blooming.
- Even Combat Complex, whose small bug enemies are closest to the dev's, gives the bugs bright yellow emissive markings and pairs them with huge muzzle effects.

### Gaps
- Hit-stop, screen-shake strength and the death animation timing need watching in real time, which stills can't show.

## Art direction: palette, lighting, detail, materials

### Takeaway
- **Dreadhunter.** A saturated neon-horror palette: magenta, teal and orange, with red gore. Heavy bloom and chromatic aberration, coloured volumetric fog in every void, practical lights everywhere, and very dense surface detail.
- **CyberCorp.** Flat-shaded low-poly with neon signage and comic-book UI.
- **Combat Complex.** Realistic PBR industrial sci-fi, dark with warm and cool practical lights, and deep atmospheric fog in its abysses.

### Cited findings
- **Dreadhunter by level.** Each level has a dominant colour:
  - Station: teal and white with red rings (`gameplay_thunderhawk/t112s+`).
  - Factory: rust-red haze with green screens (`gameplay_electro/t000s`).
  - Cave: blue-green floor with red walls (`t000s`).
  - Snow: white with teal and orange fire (`shot_00`).
  - Boss: magenta and red (`shot_05`, `shot_10`).
- **Dreadhunter lighting.** Practical lights include neon edge strips on walkways (cyan and magenta lines), glowing floor tiles, red lamps on walls, and pods with internal glow. Voids are filled with coloured fog rather than black: teal in `shot_01`, orange in `shot_09`, red in `ea_trailer/t022s`.
- **Dreadhunter post-processing.** Chromatic aberration and glitch effects are on almost every frame.
- **CyberCorp.** Low-poly faceted characters and props (`cybercorp/shot_00`, `trailer_1_0/t002s–t008s`). Neon kanji signs, orange autumn trees, wet streets. HUD has scanline and red vignette framing when hurt (`shot_02`, `shot_09`).
- **Combat Complex.** Realistic metal and concrete, hex-glass barriers, yellow hazard paint. Orange and teal fog in shafts, and spotlights on catwalks (`shot_06`, `shot_12`, `shot_00`).

### Inferences
- A cheap, high-impact step for the dev: give each void a coloured gradient fog with distant silhouettes (girders, pillars), and add emissive edge strips to every walkway and platform rim.

### Gaps
- None material.

## Isometric dungeon map designs (user's Epic Isometric map plus others)

### Takeaway
The user's map (`/tmp/claude-0/.../images/1.jpg`) is a hub-and-ring layout. A chain of stair-linked rooms forms the lower area, a curved wall-ringed upper courtyard sits above it, and round floating platforms join by bridges over a grey void. That is exactly the vocabulary the dev's level lacks: height steps, stairs, round platforms, walls on the far side only, and landmarks per room. Diablo-style layouts add rectangle rooms with pillars, corridors that loop around rooms, and large open rooms linked by short wide halls.

### Cited findings
- **The user's map, read directly from the image.**
  - About 15 rectangular rooms in the lower half step down in 2-4 height levels. They are joined by straight staircases (at least 5 visible flights), a spiral stair inside a round tower, and short ramps.
  - Rooms are low-walled boxes of skull-and-bone masonry on the camera-far edges. Their camera-near edges are open or have only a ledge.
  - The upper middle holds 4 large circular platforms floating in the void, each engraved with a compass rose and joined by narrow plank bridges and arrow-shaped spars.
  - A tall curved cliff or cave wall rings the upper half like an amphitheatre.
  - One cross-shaped raised stone platform has stairs. A natural rock outcrop holds a pit.
  - A ruined cliff-top area sits at the top-left. Torch pillars or braziers stand on room corners, and lone pillars rise out of the void.
  - The layout is a loop: the lower room chain connects round both sides to the upper ring. It is not a straight line.
- **Epic Isometric** is a Patreon artist group that sells hand-drawn isometric dungeon maps and separate map elements (a core set of 466 items on Roll20) for virtual-tabletop D&D. Examples include "Cold Dungeon Depths" and community maps such as "The Flooded Dungeon" built from its assets. — [Roll20 core set](https://marketplace.roll20.net/browse/set/3442/%7B%7B0%7D%7D); [Roll20 Cold Dungeon Depths](https://marketplace.roll20.net/browse/set/31775/cold-dungeon-depths-map-from-epic-isometric); [Patreon](https://www.patreon.com/c/epicisometric); [Flooded Dungeon](https://legendlore.notion.site/The-Flooded-Dungeon-Epic-isometric-patreon-community-map-of-the-week-1232600493f181da8eb7e6451f63a206)
- **Diablo I dungeon patterns.**
  - Upper levels: rectangular rooms joined by corridors that snake back on themselves, a common 24×24-tile room with four central pillars, and grilled arches you can shoot through.
  - Catacombs: 8×16-tile rooms with a single door, surrounded by 3-tile-wide corridors that run all the way around.
  - Caves: large open irregular areas bordered by tight passages.
  - Hell: very large open rooms connected by short wide halls, with almost no cover. — [ladyofthecake Diablo dungeon guide](https://ladyofthecake.com/diablo/dungeon.htm)
- **Diablo I generation.** Each stage has its own generator. The Cathedral grows rooms by recursive "budding", and a level is regenerated if it has too few walkable tiles. — [BorisTheBrave](https://boristhebrave.com/2019/07/14/dungeon-generation-in-diablo-1)
- **Pacing across the series.** Diablo I's tight corridors support a claustrophobic tone, Diablo II opens into larger sprawling areas, and Diablo III uses more flexible layouts with set pieces. — [PureDiablo](https://www.purediablo.com/?p=28246); [PureDiablo](https://www.purediablo.com/?p=32583)

### Inferences
Common patterns the dev could adopt:
1. Rooms of varied size, some with 4 pillars as cover.
2. A loop or ring circulation instead of a straight chain.
3. Stairs or ramps as the visible connection between 2-4 height levels.
4. Round arena platforms over a void, linked by bridges. Make them several, not one.
5. Tall walls only on the camera-far side.
6. One landmark per room: a brazier, statue, pit or dais.
7. Narrow bridges used only as short transitions between wide fighting spaces.

### Gaps
- Medium's isometric-map tutorial returned HTTP 403, and I did not download or view other Epic Isometric maps. The pattern summary therefore rests on the user's map and the Diablo text sources.

## Biggest visible differences vs the developer's game, and the most representative files

### Takeaway
The five biggest gaps, in order:
1. Enemy readability: lit, coloured, player-sized-or-larger enemies against the dev's small black bugs.
2. Projectile and impact scale: thick, blooming tracers, star flashes and explosions against thin bolts.
3. Space shape: varied rooms, wide railed walkways, stairs and 2-3 height levels, and landmarks, against flat rectangles on a 36 m grid with narrow catwalks.
4. Void treatment: coloured fog with visible depth and distant structures, against a plain void.
5. Framing: Dreadhunter's hero is about 1.5x larger on screen at a slightly lower pitch.

### Cited findings
- **Yaw.** The dev's 45° yaw matches Dreadhunter (see the Camera section).
- **Pitch and distance.** The dev's 54° and 19.5 m are steeper and further than Dreadhunter's (about 40-50°, hero 11-14% of screen height) but less extreme than Combat Complex (about 70-80°, hero about 6%).
- **Catwalks.** `dreadhunter/shot_09.jpg` is the nearest analogue to the dev's catwalk layout. There the catwalks are about 3-4 player-widths wide, railed and lit, over an orange fog void with visible support girders.

### Inferences
Suggested priorities:
1. Recolour enemies or add emissive markings (bone, red or yellow glow) and scale enemy variety up to 1-3x player size.
2. Thicken projectiles about 3x, and add star muzzle flashes, impact bursts and floor gore decals.
3. Widen catwalks, add railings and edge lights, and add stair-linked height changes and a per-room landmark.
4. Fill the void with coloured height fog and distant set-piece silhouettes.
5. Optionally move the camera closer, to about 13-14 m, or narrow the FOV to about 35°.

### Representative files
All paths are under `/home/user/Combat/research_notes/Dreadhunter level and systems research/stills/`.
1. `dreadhunter/shot_09.jpg`: X-catwalk junction over an orange void, minigun tracer, brute enemy, gore (closest to the dev's layout)
2. `dreadhunter/shot_01.jpg`: railed hex walkway over a teal fog void, stacked damage numbers, full HUD
3. `dreadhunter/shot_10.jpg`: boss with red AoE circle telegraphs, Critical/Absorbed text
4. `dreadhunter/shot_15.jpg`: neon-edged station floor, gib burst
5. `dreadhunter/trailer/gameplay_thunderhawk/t216s.jpg`: boss arena X-floor and stairs; player-size reference
6. `dreadhunter/trailer/gameplay_thunderhawk/t264s.jpg`: the same arena in combat, stairs to the upper level, enemy swarm
7. `dreadhunter/trailer/gameplay_thunderhawk/t160s.jpg`: walkway with purple channel, railings and explosion
8. `dreadhunter/trailer/gameplay_thunderhawk/t048s.jpg`: cave organic floor edging into black void, damage-number spam
9. `dreadhunter/trailer/gameplay_electro/t190s.jpg`: Steelmaster arena with an X of fire-grate hazards
10. `dreadhunter/trailer/ea_trailer/t010s.jpg`: ramp/bridge between levels, orbs, landmark pod
11. `dreadhunter/trailer/act4_trailer/t025s.jpg`: circular platform with bridges
12. `cybercorp/shot_11.jpg`: near top-down, labelled enemies, combo and objectives HUD
13. `cybercorp/trailer/trailer_1_0/t018s.jpg`: style rank letter and "SO FAST!" callout
14. `combat_complex/shot_11.jpg`: tiny player, giant railgun VFX, bug enemies with glow, teal fog abyss with pillars
15. `combat_complex/shot_12.jpg`: deep orange shaft with multi-level catwalks and laser traps

The user's map is at `/tmp/claude-0/-home-user-Combat/c29a1910-eb6c-5a31-bdd8-de27f5dc67a4/images/1.jpg`.

### Gaps
- Contact sheets used for viewing are in the session scratchpad (`/tmp/claude-0/-home-user-Combat/c29a1910-eb6c-5a31-bdd8-de27f5dc67a4/scratchpad/sheets/`) and may be cleared. The source frames are kept in `stills/`.
