# Halo and Destiny: Encounter Design, Enemy AI Roles and Mission Structure (lessons for a 3/4 top-down sci-fi action looter)

Source note: the most important primary source here is the slide notes from Jaime Griesemer and Chris Butcher's GDC 2002 talk "The Illusion of Intelligence: The Integration of AI and Level Design in Halo", mirrored page by page on halo.bungie.org (the mirror's HTML title wrongly says "Producing Audio for Halo"; the URL path is `gdc.2002.haloai` and the content is the AI talk). Damian Isla's Halo 3 "Building a Better Battle: The Halo 3 AI Objectives System" slides (GDC 2008) and his Halo 2 spatial-reasoning talk were read as PDFs used in university course pages. Destiny facts come mostly from Destinypedia (a fan wiki, read in raw wikitext) because I found no Bungie GDC talk on Destiny combatant AI. Treat wiki claims as reliable for "what is in the game" and weak for "why Bungie did it".

---

## 1. Halo's "30 seconds of fun": what it means and where it comes from

### Takeaway
The phrase is Jaime Griesemer's. It comes from the Halo 2 making-of documentary, and its roots are in the 2002 GDC talk's split between AI behavior on a 30-second scale and designer-scripted behavior on a 3-minute scale. Griesemer says people read it backwards. The point is not "repeat one 30-second loop". It is "a 3-second loop inside a 30-second loop inside a 3-minute loop that is always different": the core fight stays the same, but the missions keep changing its context (environment, weapons, vehicles, enemy mixes).

### Cited Findings
- The documentary quote: "In Halo 1, there was maybe 30 seconds of fun that happened over and over and over and over again," which can be "stretch[ed] out to be an entire game." — [Engadget/Joystiq, "Half-Minute Halo: An Interview with Jaime Griesemer" (2011)](https://www.engadget.com/2011-07-14-half-minute-halo-an-interview-with-jaime-griesemer.html)
- Griesemer: "everyone uses it to mean exactly the opposite of what I meant… No 30 second stretch of Halo is ever repeated; the missions are constantly changing the context on you." A longer explanation that was cut from the documentary talked about playing the 30 seconds "in different environments, with different weapons, different vehicles, against different enemies", plus mixes of enemies, including "enemies that are fighting each other." — [Engadget/Joystiq](https://www.engadget.com/2011-07-14-half-minute-halo-an-interview-with-jaime-griesemer.html)
- His description of a typical 30 seconds: "Encountering a bunch of guys, melee attacking one of them before they were aware, throwing a grenade into a group of other guys." — [Engadget/Joystiq](https://www.engadget.com/2011-07-14-half-minute-halo-an-interview-with-jaime-griesemer.html)
- The nested structure: AI handles "all the decisions on the 30-second timescale" (where to stand, when to shoot, when to dive from a grenade), mission designers handle "what happens on the 3-minute timescale" (reinforcements, retreats, encounter tactics), and the result is "a 3-second loop inside of a 30-second loop inside of a 3-minute loop that is always different." — [Engadget/Joystiq](https://www.engadget.com/2011-07-14-half-minute-halo-an-interview-with-jaime-griesemer.html)
- Primary 2002 source for the split. "In Halo, the Designers were responsible for anything that had a 3 minute scope", for example racial personalities ("Grunts are _always_ comical and cowardly / Elites are _always_ tough and aggressive") and strategic purpose ("Secure the landing zone", "Protect the flag"). "Code responsible for 30 second scope": cover choice ("This rock is good cover… This enemy tank is not good cover") and instant reactions ("This grenade is going to explode, I need to dive away"). — [GDC 2002 slide notes, p.5](https://halo.bungie.org/misc/gdc.2002.haloai/talk.html?page=5)
- In 2008 Damian Isla described the same model this way: "200 or 300" such encounters "laid back to back" make a game. Each encounter has three steps: entering a space, planning an approach, executing it. — [Game Developer, "In-Depth: Bungie On Eight Years Of Halo AI" (2008)](https://gamedeveloper.com/game-platforms/in-depth-bungie-on-eight-years-of-i-halo-i-ai)
- On pacing, Griesemer says "Halo is fundamentally different in that it lets the player set the pace." The AI "waits to see what you will do, how hard you will push, and then it pushes back at just the right resistance." He says this is not dynamic difficulty but "precisely tuned". — [Engadget/Joystiq](https://www.engadget.com/2011-07-14-half-minute-halo-an-interview-with-jaime-griesemer.html)

### Inferences
- For a looter, the transferable unit is the roughly 30-second engagement: approach, read the group, open (often with a stealth melee or grenade), deal with the reaction, mop up. The variety budget belongs at the 3-minute level (arena shape, enemy mix, a vehicle or turret, a third-party faction), not in reinventing the core verbs.
- "Lets the player set the pace" argues against constant spawn pressure in most encounters. Enemies should hold territory and respond to the player's push (see section 4) rather than always rushing.

### Gaps
- I did not obtain the original documentary footage. The quote is relayed by the Joystiq interview and Halopedia.

---

## 2. Halo's combat sandbox: weapons, grenades, melee, vehicles, and how they interact

### Takeaway
Halo's combat triangle is gun, grenade and melee (the "golden triangle"), sitting on top of a recharging shield. Bungie used AI tuning to punish boring tactics (assault-rifle rushes, melee rushes) and to reward interesting ones (stealth melee from behind, headshots, killing leaders, matching the right weapon to the right enemy). Interactions emerge because the world simulation is rich, not because the AI is complex, and AI can use the same weapons and vehicles the player does.

### Cited Findings
- Halopedia says Bungie calls the weapons/grenades/melee format the "Golden Triangle of Halo", which stayed fundamentally unchanged across the trilogy. Melee is always available, a hit in the back is typically lethal to most enemies, and a single melee often fully strips shields. — [Halopedia, Weapons (gameplay)](https://www.halopedia.org/Weapons_(gameplay)) (fan wiki, read via search summary)
- Reach kept gun/grenade/melee and trimmed the arsenal so each weapon type was more distinct. Grenades that duplicated plasma grenades were cut. — [GamesRadar, "Halo Reach's huge battles and new guns"](https://www.gamesradar.com/halo-reachs-huge-battles-and-new-guns) (via search summary)
- A Game Developer opinion piece questions whether the triangle was ever a formal principle, pointing at Halo 4's drift. — [Game Developer, "Three Weapon Monte: What happened to Halo 4's game mechanics"](https://www.gamedeveloper.com/design/three-weapon-monte-what-happened-to-halo-4-s-game-mechanics-) (via search summary)
- Recharging shields as a teaching tool: "the Player was equipped with a recharging shield / this allowed him to take temporary damage / so we could show him that he was using the wrong tactic without killing him." — [GDC 2002 p.17](https://halo.bungie.org/misc/gdc.2002.haloai/talk.html?page=17)
- Discouraging the "Assault Rifle Rush": "our AI gets more accurate the longer the Players stays out of cover / a long charge will almost always get you killed". Discouraging the "Melee Attack Rush": "we gave some of the characters powerful melee attacks." — [GDC 2002 p.17](https://halo.bungie.org/misc/gdc.2002.haloai/talk.html?page=17)
- "If you are going to punish boring tactics you had better reward experimentation". The rewards were instant-kill melee from behind for stealthy players, Grunts fleeing when an Elite dies for careful target selection, headshots for accuracy, and "making some weapons much better at certain enemies than others" for planning. — [GDC 2002 p.17](https://halo.bungie.org/misc/gdc.2002.haloai/talk.html?page=17)
- Parity: "Elites shields recharge exactly like the Player's shields". No psychic AI, no perfect aim, and invisible AI exist only because the player can also become invisible. Rule of thumb: an AI ability the player lacks is fine "as long as the ability is recognizable and the limits of that ability can be easily predicted" (for example, the Flood jump higher and run faster). — [GDC 2002 p.6](https://halo.bungie.org/misc/gdc.2002.haloai/talk.html?page=6)
- Emergence from simulation, not AI complexity: "we don't need to add complexity to the AI, because there are many game world elements that are designed to be self-contained and interact well together". Examples given: a "jackal shooting elite with charged bolt", a "warthog jump movie", and an "elite swinging sword and breaking glass causing him to leap through window". — [GDC 2002 p.12](https://halo.bungie.org/misc/gdc.2002.haloai/talk.html?page=12)
- Isla (2008): enemies must be roughly player-equivalent, able to "use and board all the vehicles, and use all the weapons." In Halo 2, an AI that tipped its vehicle would walk off and forget it. In Halo 3, objects carry "concepts", so an AI stays near its flipped vehicle and fights until it can right it. "Behavior should be a very thin layer on top of a world of concepts." — [Game Developer, Isla 2008](https://gamedeveloper.com/game-platforms/in-depth-bungie-on-eight-years-of-i-halo-i-ai)
- Halo 2 objects advertise "affordances" through markers. The AI uses them for cornering, mount-to-uncover (jumping onto an object to shoot over it), destroying destructible cover, vaulting and smashing. AI grenade throws "find clusters of nearby enemies", and the AI detects blocked shots ("I wanted my bullets to go X meters, but they only went 0.6X"). — [Isla, Halo 2 spatial competence lecture (U. Michigan EECS 494 adaptation)](https://web.eecs.umich.edu/~sugih/courses/eecs494/fall06/lectures/lecture18-halo2.pdf)
- Vehicle encounters: "Vehicle encounters are not fun without a vehicle." In Halo 3, allied AI drive over to pick up the player when the player needs a vehicle, through a dedicated "player pickup" task per encounter. — [Isla, Halo 3 Objectives slides](https://web.cs.wpi.edu/~rich/courses/imgd4000-d10/lectures/halo3.pdf)
- Jackals carry point-defense gauntlet shields: light blue for minors, violet/red/orange for majors. From Reach on, the shield is in the left hand and the gun in the right, which "generally makes it harder to shoot through the gap in their energy shield". Jackal snipers carry no gauntlet, so they are more exposed. — [Halopedia, Kig-Yar](https://www.halopedia.org/Kig-Yar)

### Inferences
- The Halo pattern for a top-down looter is "punish the degenerate play with AI tuning, reward the clever play with a systemic bonus". For example: ranged enemies get more accurate the longer the player stands in the open, backstab or execution kills on unaware enemies, a morale break when a leader dies, and specific damage types beating specific defenses (the plasma-vs-shields idea, which is a natural fit for elemental damage in a looter).
- Shields that regenerate behind cover give the player safe pockets to retreat to. In top-down, this argues for clearly readable cover clusters and a short recovery window, rather than health potions as the only recovery.
- AI parity (enemies using the same weapons and vehicles as the player) makes enemy behavior legible. In a looter, letting enemies wield recognizable weapon archetypes the player can also loot gives both readability and a loot tease.

### Gaps
- I found no Bungie primary source that uses the exact phrase "golden triangle". Halopedia attributes it to a Halo 3 documentary. Weapon-vs-enemy specifics (for example, plasma pistol overcharge stripping Elite shields, the needler supercombine) were not verified from fetched pages in this pass.

---

## 3. Halo enemy roles and squad behavior (Grunts, Jackals, Elites, Hunters, Brutes, leaders)

### Takeaway
Bungie built each race as a caricature with one dominant personality (Grunts cowardly, Elites aggressive) so behavior is predictable and readable. The race signals the stakes of an encounter (Grunts alone mean an unprepared Covenant; Elites mean they will fight). Each race has a "breaking point" that tells the player they are winning (Grunts flee when their leader dies, Elites berserk when badly hurt, squads retreat after casualties). Halo 3 formalized leader/follower squads, such as a Brute with three Grunts or a Chieftain with a Brute pack, where the leader's death "breaks" the followers.

### Cited Findings
- "In Halo, Grunts are cowards and all their behaviors derive from that: Hide when targeted, Panic when Elite is killed. Elites are aggressive: They rarely hide unless the player hides, Berserk charge on massive damage." Racial personalities "make the design process easier" ("easier to make a caricature than a complex portrait") and help players remember and predict behavior. — [GDC 2002 p.6](https://halo.bungie.org/misc/gdc.2002.haloai/talk.html?page=6)
- First impressions set the personality: "The first time you see an Elite he is a terrifying bad ass / The first time you see a grunt you easily kill him / The first time you see a hunter he is sent in as the last line of defense (and they are accompanied by foreboding music)." — [GDC 2002 p.6](https://halo.bungie.org/misc/gdc.2002.haloai/talk.html?page=6)
- Race composition as information: "Grunts are the fodder so when the Player sees them… the Covenant aren't prepared. Elites are the leaders so when the Player sees them he knows the Covenant are interested in the area and are going to put up a fight." — [GDC 2002 p.6](https://halo.bungie.org/misc/gdc.2002.haloai/talk.html?page=6)
- First-sight reactions: Grunts are surprised and take cover; Elites get angry and "shoot at you and make sure you can't escape"; Marines are impressed ("I didn't think he'd be so tall"). — [GDC 2002 p.7](https://halo.bungie.org/misc/gdc.2002.haloai/talk.html?page=7)
- Breaking points: "A breaking point is a distinct change in behavior that indicates the AI knows it is going to lose." A Grunt "sees enough friends die or sees an Elite killed he flees in terror"; an Elite "takes a large amount of damage he loses his temper and charges". At group level, "when a squad takes enough casualties it will retreat… find a defensive position… stay in cover longer". "This tells the Player that he has won." — [GDC 2002 p.7](https://halo.bungie.org/misc/gdc.2002.haloai/talk.html?page=7)
- The readability lesson: "In Halo the Grunts run away when an Elite is killed. Initially nobody noticed so we had to keep adding clues… By the time we shipped… _every single_ Grunt run away _every single_ time an Elite is killed… an outrageously exaggerated panic run where they wave their hands above their heads, they scream in terror and half the time one of them will say 'Leader Dead, Run Away!' I would still estimate that less than a third of our users made the connection." — [GDC 2002 p.19](https://halo.bungie.org/misc/gdc.2002.haloai/talk.html?page=19)
- Race differences are implemented as small code layers: custom "black box" code per race enables or disables behaviors by condition, and "these rules are very simple and typically less than a page of code." The base layer is an FSM (fight, flee, charge, and so on) driven by an alert cycle, with a "toolbox of behaviors" triggered by stimuli. — [GDC 2002 p.21](https://halo.bungie.org/misc/gdc.2002.haloai/talk.html?page=21)
- Hunters: when a Hunter misses its melee attack it has a long recovery window in which the player can flank it, which Isla gives as an example of a "good mistake" that lets the player feel smart. — [Game Developer, Isla 2008](https://gamedeveloper.com/game-platforms/in-depth-bungie-on-eight-years-of-i-halo-i-ai)
- Halo 3 leadership case study: "Want to have leaders and followers: Brute and three grunts; Brute Chieftan and brute pack… Leaders provide structure to encounter; Leader death 'breaks' followers." It was implemented with "leader"/"no leader" task filters and a task "broken" state in which NPCs run "broken" behaviors. — [Isla, Halo 3 Objectives slides](https://web.cs.wpi.edu/~rich/courses/imgd4000-d10/lectures/halo3.pdf)
- Tommy Thompson's analysis: "Brute Chieftans dictate the coordination of Covenant squads". From Halo 2 on there are stimulus overrides for spotted enemies, nearby grenades, and "the defeat of nearby commanders". — [Game Developer, Tommy Thompson, "Combat Evolved: The Encounter Design of Halo 3" (2018)](https://www.gamedeveloper.com/design/combat-evolved-the-encounter-design-of-halo-3)
- Jackal roles: shield-bearing line troops; snipers without shields. — [Halopedia, Kig-Yar](https://www.halopedia.org/Kig-Yar)
- Group composition from the Halo 2 lecture: AI "crouch in front of each other", "don't walk into the player's line of fire", and "curing isolation" are listed as local spatial behaviors. — [Isla Halo 2 spatial lecture](https://web.eecs.umich.edu/~sugih/courses/eecs494/fall06/lectures/lecture18-halo2.pdf)

### Inferences
- The role taxonomy that falls out of this is: fodder (Grunt), line infantry that blocks from the front (shield Jackal), ranged harassment (Jackal sniper), leader/elite (Elite, Brute), and heavy "last line of defense" (Hunter pair). In top-down terms: swarmers, frontal-shield blockers that force flanking or arcing grenades, backline snipers with visible laser tells, a leader whose death triggers a visible morale break, and a heavy with a big telegraphed melee and a punish window.
- Top-down has an advantage for the leader-flee mechanic. The whole squad is on screen, so a radial "panic" icon or VO bark plus scattering is far more legible than in first person. Even so, Bungie's lesson is to over-exaggerate it.

### Gaps
- Hunter "bond brother" pairing, Brute berserk/armor-break behavior (Halo 2/3) and Reach's Skirmisher role are well known, but I did not fetch a primary source for them in this pass.

---

## 4. Halo AI design talks and the "objective-based" encounter system

### Takeaway
Across three generations, Bungie kept the same division: designers author strategy (territories, tasks, fallbacks), and AI acts autonomously within them (cover, grenades, dives). Halo 1 used per-encounter attacking/defending territories with retreat conditions. Halo 2 used a behavior tree ("behavior DAG", about 50 behaviors) and designer-built FSMs of encounter state. Halo 3 replaced those FSMs with a declarative, prioritized task tree ("Objectives") that squads "plinko" down into, based on priority, capacity and activation conditions such as "g1 alive >75%".

### Cited Findings
- Talk framing: the title is "The Illusion of Intelligence" not "The Reality of Intelligence"; "tips on how to make the enemies in your game _appear_ to be intelligent." — [GDC 2002 p.2](https://halo.bungie.org/misc/gdc.2002.haloai/talk.html?page=2)
- The goals were set against alternatives. Heavy scripting (Medal of Honor) "feels like a movie, not a game". Squad-command interfaces make the player "a manager instead of a hero". Omniscient enemies (Quake III) feel "like bullying — nobody wants to have a reflex competition with an electron." — [GDC 2002 p.3](https://halo.bungie.org/misc/gdc.2002.haloai/talk.html?page=3)
- Perception: each actor has its own knowledge model with "no cheating! the AI system only has access to the actor's knowledge model". It covers vision, hearing, touch and scripted "ESP". To manage cost, actors track only about 3 friends and 5 enemies. — [GDC 2002 p.10](https://halo.bungie.org/misc/gdc.2002.haloai/talk.html?page=10)
- Making internal state visible: through "language (spoken dialogue… 'wort wort wort' [reversed English for aliens]), different animation postures based on intention (sneaking, running, hiding), and specific animation triggers". "The smartest AI in the world is useless if the player has no way of knowing what it's thinking." — [GDC 2002 p.11](https://halo.bungie.org/misc/gdc.2002.haloai/talk.html?page=11)
- Bungie dropped hidden emotion variables. It started with fuzzy "fear, anger, defensiveness and surprise" variables but removed them as "hard for human players to make a mental picture". "Most thought processes are driven by discrete events and stimuli, which is far more understandable." — [GDC 2002 p.12](https://halo.bungie.org/misc/gdc.2002.haloai/talk.html?page=12)
- "Unpredictable does not mean random… Random factors in behavior are rarely good". "Ideally… the player is the only unpredictable element". Code-driven encounters use "analog" inputs (exact distance, line of sight, health, distance to cover), so small changes become big behavior changes. — [GDC 2002 p.8](https://halo.bungie.org/misc/gdc.2002.haloai/talk.html?page=8)
- Enemies that can be fooled: a simple search pattern ("move forward at a constant rate… don't double-back") and cause-and-effect reactions ("If I throw a grenade into that room, the enemy will run out of the room"). — [GDC 2002 p.7](https://halo.bungie.org/misc/gdc.2002.haloai/talk.html?page=7)
- Budget: about 25 actors in one battle plus several vehicles, with up to 100 Flood infection forms, on a 733 MHz Pentium III, at about 15% CPU for AI. — [GDC 2002 p.9](https://halo.bungie.org/misc/gdc.2002.haloai/talk.html?page=9). Line-of-sight ray casts were about 60% of AI cost. — [GDC 2002 p.22](https://halo.bungie.org/misc/gdc.2002.haloai/talk.html?page=22)
- Firing positions: "designers place points grouped where they want a squad to be located… the designers control the movement of actors through a space solely by assigning them different sets of firing points". Cover looks for points out of the target's line of sight; search looks near the last known location. — [GDC 2002 p.22](https://halo.bungie.org/misc/gdc.2002.haloai/talk.html?page=22)
- Combat dialogue: events from across the AI are prioritized, with rare events ranked higher. The system picks speakers the player can see and events the player likely noticed. Example: a Grunt on a turret kills a Marine, then the Grunt says "kill you, human", the sergeant gives a squad-specific line, and a Marine reacts by killer race or damage type. "Dialogue is only for the player's benefit." — [GDC 2002 p.23](https://halo.bungie.org/misc/gdc.2002.haloai/talk.html?page=23)
- Halo 2 (Isla, GDC 2005): a hierarchical FSM, more specifically a "behavior DAG" with "on the order of 50 different behaviors". The costs of complexity are coherence, transparency and usability. — [Game Developer, "GDC 2005 Proceeding: Handling Complexity in the Halo 2 AI"](https://gamedeveloper.com/programming/gdc-2005-proceeding-handling-complexity-in-the-i-halo-2-i-ai) (via search summary). Isla's 2008 slides summarize the tree as root to hide (cover, grenade), fight (melee, shoot), search (uncover, pursue), idle (sleep), with a "prioritized-list decision scheme" and "self-describing" behaviors. — [Isla, Halo 3 Objectives slides](https://web.cs.wpi.edu/~rich/courses/imgd4000-d10/lectures/halo3.pdf)
- Halo 2 space: AIs get a "playground"; "the designer defines the flow of battle by moving the AI from one playground to another". Places form a shallow hierarchy: Zones (organizational) to Areas ("defines the playground") to firing Positions ("tactical analysis"). — [Isla Halo 2 spatial lecture](https://web.eecs.umich.edu/~sugih/courses/eecs494/fall06/lectures/lecture18-halo2.pdf)
- Halo 3 Objectives:
  - "Encounters are systems… The system reacts in interesting ways / The system collapses in interesting ways". "Designer provides the strategic intelligence; AI acts smart within the confines of the plan."
  - A Halo task bundles territory plus behavior (aggressiveness, rules of engagement, player following). "Changing task moves AI around the encounter space."
  - The Halo 2 "imperative method" gave designers an FSM tool with transitions such as "< 75% alive?". Explicit transitions led to "n² complexity", so it failed for Halo 3's "larger encounters, more characters, more open spaces, more avenues of attack".
  - The Halo 3 "declarative method" lists "tasks that need doing" and "let[s] the system figure out who should perform them". It is a tree of prioritized tasks, each with priority, activation script fragments and capacities. "Pour squads in at the top… filter down to the most important tasks… it's a plinko machine."
  - Example: three generator groups, each with forward (active while generator group alive >75%), fallback (>50%) and laststand subtasks, max 10 per group.
  - Squad-to-task assignment minimizes a cost function H: "don't want to travel far, want to act coordinated, want to balance the tree, want to get near to the player". It uses a greedy algorithm under capacity constraints.
  - Refinements: filters (character type, in or out of vehicle, snipers, "helpful for the 'spice'"), latch on/off, exhaustion by death count or living count, one-time assignment.
  - Downsides: it needed designer training and became "much more complicated as we neared shippable encounter state."
  
  — [Isla, Halo 3 Objectives slides](https://web.cs.wpi.edu/~rich/courses/imgd4000-d10/lectures/halo3.pdf)
- Thompson's summary of the same: combat "starts with the enemy, then shifts toward the player and allies, and ends with the last enemies making a stand". Squads keep a shared "clump" knowledge base for performance. — [Game Developer, Thompson 2018](https://www.gamedeveloper.com/design/combat-evolved-the-encounter-design-of-halo-3)
- Isla's three principles (Develop 2008):
  - Territory exists because recharging shields require a safe zone, which turns encounters into puzzles.
  - Limited knowledge: "Each AI has an internal model of each target, and that model can be wrong". Misperception is "the most interesting form" of good AI mistake.
  - Satisfying enemies: "more fun to kill an enemy that's cunning, formidable, and tactical."
  
  The AI was designed around "primal games": hide and seek, tag, king of the hill. — [Game Developer, Isla 2008](https://gamedeveloper.com/game-platforms/in-depth-bungie-on-eight-years-of-i-halo-i-ai)

### Inferences
- A small team can implement a Halo 3-style "objectives" director cheaply. An encounter would be a list of prioritized tasks (hold front cover, guard leader, flank route, last-stand ring), each with a capacity and an activation condition (alive count or percentage, player position, a leader alive, a timer). Enemies are poured into the highest-priority active tasks, and inside a task each enemy runs its own small behavior tree. This produces the canonical forward, fallback, last-stand collapse with almost no per-encounter scripting.
- Isla's "limited knowledge / hide and seek" principle is weaker in a top-down game, because the player sees the whole arena and cannot easily hide behind a crate from the camera's view. To keep it, show enemy perception explicitly (alert icons, vision cones on snipers, a "lost track" question mark at the last known position), or use fog-of-war or occluding geometry.

### Gaps
- I did not obtain a transcript of Isla's GDC 2005 Halo 2 paper beyond the summary. Halo: Reach-specific AI talks (if any) were not found in this pass.

---

## 5. Halo encounter space design and pacing between encounters

### Takeaway
Bungie built "strategic spaces": interconnected areas so AI and player can both flank, anchored by a "killing zone" (an open area between two positions with good cover) so the battle stays directed rather than chaotic. Battle flow is a collapse from a large aggressive territory to a small defensive cluster. That simple pattern covered about 80% of Halo 1's encounters, and it became the "canonical encounter" in Halo 3 (territory, fallback, last stand, break, finish) plus "spice" (snipers, turrets, dropships). Difficulty was kept consistent, and every encounter offered an easy way and a hard way.

### Cited Findings
- "A battle in a corridor doesn't involve much strategy… An interconnected space allows the AI to flank the Player… [and] allows the Player to flank the AI… One weakness of an interconnected space… is that it tends to be chaotic. So we also needed to establish a Killing Zone: an open area between two positions with good cover. Flanking is still possible… but the battle is much more directed… allows multiple enemies to fight at once without it degenerating into chaos." — [GDC 2002 p.18](https://halo.bungie.org/misc/gdc.2002.haloai/talk.html?page=18)
- Attacking/defending states: "Each group of actors has an aggressive territory… retreat conditions, such as a number of casualties or the position of the Player… transition to a defensive state… By carefully collapsing an encounter from a large aggressive territory to a small defensive cluster we were able to capture the feeling of a dynamic battle… For a large majority of encounters, I'd say around 80%, we didn't need to get any more complicated than this." — [GDC 2002 p.18](https://halo.bungie.org/misc/gdc.2002.haloai/talk.html?page=18)
- The Halo 3 "Canonical Encounter / Two-stage fallback": "Enemies occupy a territory; Pushed to 'fallback' point; Pushed to 'last-stand' point; Player 'breaks' them; Player finishes them off… plus a little 'spice': snipers, turrets, dropships." — [Isla, Halo 3 Objectives slides](https://web.cs.wpi.edu/~rich/courses/imgd4000-d10/lectures/halo3.pdf)
- The easy way and the hard way: "for most encounters in Halo there is the easy way and the hard way. A frustrated Player that engages in a little exploration might find a hidden ramp leading to a catwalk above their enemies, or a player that simply watches an encounter before he attacks might get the chance to throw a grenade into a large group." — [GDC 2002 p.17](https://halo.bungie.org/misc/gdc.2002.haloai/talk.html?page=17)
- Consistency: "If the game goes from easy to hard and back again, players attribute the easy parts to poor AI and the hard parts to evil level designers." — [GDC 2002 p.17](https://halo.bungie.org/misc/gdc.2002.haloai/talk.html?page=17)
- Tougher means smarter: in a playtest with weak enemies, 36% said the game was too easy and only 8% rated the AI "Very Intelligent". After raising enemy HP and damage, 0% said too easy and 43% rated the AI very intelligent. — [GDC 2002 p.16](https://halo.bungie.org/misc/gdc.2002.haloai/talk.html?page=16)
- Engagement distance: "Nothing breaks our AI faster than engaging it from the wrong range. Sniping makes the AI look oblivious… fighting too much from melee range makes the AI look robotic". Bungie tuned weapon and activation ranges to keep the player at the optimal range. — [GDC 2002 p.19](https://halo.bungie.org/misc/gdc.2002.haloai/talk.html?page=19)
- Playtest lessons: "If it isn't totally obvious, it's too subtle". A deliberate perception delay was removed because players read it as a bug. — [GDC 2002 p.19](https://halo.bungie.org/misc/gdc.2002.haloai/talk.html?page=19)
- Halo 2 levels had plenty of cover so players could outmaneuver enemies. Enemies move to squares outside the player's line of sight. — [Game Developer, Isla 2008](https://gamedeveloper.com/game-platforms/in-depth-bungie-on-eight-years-of-i-halo-i-ai)
- Pacing between encounters: missions constantly change context (environment, weapon, vehicle, enemy mix, enemies fighting each other). — [Engadget/Joystiq](https://www.engadget.com/2011-07-14-half-minute-halo-an-interview-with-jaime-griesemer.html)

### Inferences
- A practical arena template for a top-down game: an entry overlook (the "watch before you attack" beat), a killing zone with cover on both sides, two or three flank lanes looping around it, enemy front territory, a fallback line, a last-stand ring around a leader or objective, and optional spice (a sniper perch, a turret, a dropship reinforcement). Add a hidden route as the "easy way" reward for exploration.
- "Tougher equals smarter" and the engagement-range lesson both translate directly. Give enemies enough HP to show their behavior. Tune player weapon ranges and enemy activation radii so fights happen at the range where enemy behavior is visible (in top-down, about half a screen to a screen away), not off-screen sniping.
- Between encounters, change one axis at a time (space, enemy mix, weapon on offer, vehicle or turret, third-party faction) rather than escalating raw numbers.

### Gaps
- Specific Halo CE/Halo 3/Reach mission walkthroughs (for example "The Silent Cartographer" beach landing or Halo 3 "The Covenant" multi-tower structure) were not analyzed from primary sources in this pass.

---

## 6. Destiny strike structure and pacing (The Devils' Lair, The Arms Dealer)

### Takeaway
A Destiny strike is a 3-player, linear series of combat encounters, often with a mini-boss, ending in a boss supported by adds. Strikes sit between story missions and raids in length and difficulty. The beats recur: traversal, a "hack/hold" defense in waves while the Ghost works, a named lieutenant mini-boss, a vehicle or tank set piece, a gate or door, and a boss arena where the boss is immune until a condition is met (adds cleared, a node destroyed, a charge dunked). Bosses step through health-threshold phases (around 2/3 and 1/3) in which they relocate, summon reinforcements or go immune.

### Cited Findings
- Definition: strikes are "a middle ground in PvE content between Story missions and Raids in terms of length and difficulty, and are optimized for a fireteam of three players. Usually, Strikes are composed of a linear series of enemy encounters which may or may not include a mini-boss, culminating in a battle against one or more bosses supported by additional enemies. Some of the newer strikes feature simple puzzle mechanics." — [Destinypedia, Strike](https://www.destinypedia.com/Strike)
- Playlists and repeatability: random strikes in a matchmade playlist. The Nightfall is a weekly high-difficulty strike with modifiers and no matchmaking, rewarding Legendary and Exotic gear. Since The Taken King, strikes can drop strike-specific loot, and consecutive playlist strikes raise the chance of better loot. With The Edge of Fate (2025), "Strikes as an activity type have been largely replaced." — [Destinypedia, Strike](https://www.destinypedia.com/Strike)
- The Devils' Lair (Destiny 1, Level 8, Cosmodrome, 1-3 players). Objectives in order: Enter the Devils' Lair, Fight into the Lair, Take back the Refinery, Hack the Mesh Generator, Secure the Refinery, Infiltrate Devils' Lair, Cut through the Fallen, Find Sepiks Prime, Decimate the Fallen, Destroy Sepiks Prime. — [Destinypedia, The Devils' Lair (strike)](https://www.destinypedia.com/The_Devils%27_Lair_(strike))
- Devils' Lair beats: the Ghost hacks the shield mesh generator while the fireteam survives three waves ("I'll need time… there's more Fallen and Hive on the way"). Naksis, Devil Baron appears in the third wave. Next is a traversal clearing where "a Devil Walker is deployed", a tank set piece. Then comes the lair. Enemies mix Fallen and Hive ("Fallen and Hive. Let's hope we can avoid the crossfire"). Bosses: Naksis, Devil Walker, Sepiks Prime. — [Destinypedia, The Devils' Lair (strike)](https://www.destinypedia.com/The_Devils%27_Lair_(strike))
- Sepiks Prime: "at first invulnerable but immobile; it will drop its shield and start attacking once all Fallen in the area have been killed". It fires Void blasts while "teleporting to fixed positions around the area", summons reinforcements, and drains health from Guardians who get too close. In the Destiny 2 remake, near 2/3 health it teleports to the arena center and summons four Unyielding enemies (the wiki text is truncated at this point). The Rise of Iron "Sepiks Perfected" version adds a SIVA barrier removed by destroying SIVA Nodes, area-denial nodes that apply a debuff, and elemental shields that must be broken with carried Shock/Scorch/Null cannons. — [Destinypedia, Sepiks Prime](https://www.destinypedia.com/Sepiks_Prime)
- The Arms Dealer (Destiny 2, EDZ, Cabal). Original objectives: Overload Bracus Zahn's systems, Secure the area, Force an explosion, Kill Zahn's Lieutenant, Find Zahn, Activate elevator controls, Clear a path, Hack the door, Break through, Defeat Bracus Zahn. Beats include:
  - A console hack that trips an alarm, so reinforcements arrive.
  - Picking up a Solar fuel cell exposed by destroying a tank and carrying it to an exhaust vent to break a barrier, which is a carry objective.
  - Two Goliath Tank fights with Cabal reinforcements.
  - An elevator hack and a door hack.
  
  — [Destinypedia, The Arms Dealer](https://www.destinypedia.com/The_Arms_Dealer)
- Bracus Zahn's fight: he jumps onto a platform and summons Volcanic Scorpius turrets plus Cabal. "After doing some damage to him and killing all other enemies, he'll jump to a second platform and do the same thing," then flies to an airfield, where players must activate a lift and fight more foot soldiers. In the Lightfall rework, at 1/3 health he becomes immune and teleports. The charge needed to drop his shield "will have to be taken from a Shadow Guard Centurion who appears among the reinforcements and must be dunked in a different location." The Nightfall version adds a Tormentor. — [Destinypedia, Bracus Zahn](https://www.destinypedia.com/Bracus_Zahn); [Destinypedia, The Arms Dealer](https://www.destinypedia.com/The_Arms_Dealer)
- General boss ("Ultra") kit: an AoE melee if large, a heavy ranged attack, summoned reinforcements, rapid movement, immunity to crowd-control verbs (blind, suppression, freeze, suspend), and immunity to finishers. "Ultras at the end of activities often have unique attacks, defenses, or mechanics… generally increasing in number the more complex the activity is meant to be." — [Destinypedia, Ultra](https://www.destinypedia.com/Ultra)

### Inferences
- A strike's pacing grammar, reusable as a mission template (inferred from the two examples): (1) traversal with light patrols, (2) "unlock" encounter (hold a point while the Ghost hacks, about 3 waves, a mini-boss in the last wave), (3) traversal plus a set-piece heavy (Walker or tank) in an open arena, (4) gate (door or elevator hack, sometimes alarm-triggered reinforcements), (5) boss arena: boss immune until adds or nodes are cleared, then damage phases broken by threshold events (relocate, summon a wave, go immune, require an objective: carry or dunk), (6) loot. This maps closely onto a top-down mission: corridor, arena, set piece, gate, boss.
- Boss immunity gates ("kill the adds to drop the shield", "dunk the charge") ensure the boss fight uses the whole sandbox rather than being a damage sponge. In a looter they also create the damage window that build optimization ("burst") is tuned around.

### Gaps
- I did not find a Bungie developer talk or blog explaining strike pacing intent (for example, target minutes per strike or encounter counts). The Destiny 2 remake details of Sepiks are cut off in the wiki text.

---

## 7. Destiny combatant role taxonomy and health-bar color language

### Takeaway
Destiny signals threat with health-bar color. In Destiny 2: red is Minor ("adds", fodder), orange is Elite (a segmented bar; the role Majors had in Destiny 1), yellow is Major (mini-boss), and a skull-marked bar is Ultra/Boss. Each rank adds health, damage and defensive tools (absorption shields, dodging, CC immunity). Champions are a special overlay on top of this (section 9).

### Cited Findings
- Minor: "the lowest level enemy combatant of any given species… distinguished by their red health bars and non-unique names… very low health and are seen in larger amounts… often cannon fodder role, they are often also colloquially referred to as 'adds'." In Destiny 1, each faction's minors had two higher ranks marked by an adjective. — [Destinypedia, Minor](https://www.destinypedia.com/Minor)
- Elite (Destiny 2): "take up the role of what D1 Majors had, with the latter becoming akin to mini-bosses… orange health bar, larger than that of an equivalent Minor and segmented in three parts… often carry more powerful weapons, move faster and dodge more frequently." — [Destinypedia, Elite](https://www.destinypedia.com/Elite)
- Major: "yellow health bars and sometimes unique names… more health and attack power… may be equipped with Absorption Shields their base counterparts lack… more alert, and will often strafe sideways to dodge." — [Destinypedia, Major](https://www.destinypedia.com/Major)
- Ultra/Boss: "the most powerful type of enemy… giant yellow bar with a skull next to it in Destiny, or a skull symbol integrated into the bar in Destiny 2… may have health bars displayed on the bottom of the screen". Standard kit: AoE melee, heavy ranged attack, summoning reinforcements, rapid movement, immunity to CC verbs and finishers. — [Destinypedia, Ultra](https://www.destinypedia.com/Ultra)
- Element-colored shields are a defense layer (for example, Knights get an Arc shield on Nightfalls; Captains are "almost always enshrouded within an Absorption Shield"). — [Destinypedia, Knight](https://www.destinypedia.com/Knight); [Destinypedia, Captain](https://www.destinypedia.com/Captain)
- Orb economy by rank in Destiny 1: "Killing a normal enemy yielded one orb, while killing a major enemy yielded four" (in the context of orb-generating perks). — [Destinypedia, Orb of Power](https://www.destinypedia.com/Orb_of_Power)

### Inferences
- For a top-down looter, a four- or five-tier bar language works well: red fodder, orange elite, yellow named mini-boss, skull boss, plus a champion icon overlay. It is instantly readable from above, and it tells the player where to spend burst, abilities and super. Tie rewards to the tier (orbs, ammo or loot chance scale with rank), as Destiny 1 did with 1 versus 4 orbs.
- Destiny's change from D1 to D2 (inserting "Elite" between Minor and Major) shows the value of a mid tier: a tougher line unit that is not a mini-boss. That is the Halo "Elite/Brute" leader slot.

### Gaps
- I found no Bungie source explaining the D1 to D2 rank change. Exact HP multipliers per rank are not public in the sources I read.

---

## 8. Destiny enemy factions and their distinct behaviors (Fallen, Hive, Vex, Cabal, Taken)

### Takeaway
Each faction has a fantasy and a combat signature. Fallen are agile, dodging, teleporting scavengers with shielded Captain leaders. Hive are a melee swarm (Thrall) backed by shield-wall Knights and flying Wizard casters. Vex are relentless machines with odd weak points (abdomen cores), shield-turtling snipers and teleporting flankers. Cabal are heavy, armored, jump-jet infantry with frontal-shield Phalanxes. The Taken are a remix faction: familiar silhouettes with new paracausal abilities "designed to counter Guardian abilities" (blind, immunity beams, splitting, knockback). Each unit also has a "berserk" or "break" state, often triggered by losing its head or dropping to low HP.

### Cited Findings
- Bungie's framing, from art director Christopher Barrett (2013): Fallen are "space pirates, basically… like the bounty hunters of the solar system", nomadic and able to show up anywhere. Cabal are a militaristic empire with heavy armor and big weapons, "big lumbering space rhinos". Vex are endless metal armies that build warp gates; their weak spot is the abdomen, and shooting it releases glowing liquid, borrowed from Halo's Grunt "confetti". Hive are "space zombies" in gothic dungeons who burst into dust and embers. — [Game Informer, "The Enemies of Destiny" (2013)](https://www.gameinformer.com/b/features/archive/2013/12/16/the-enemies-of-destiny.aspx)
- Destiny 2 reworked the races to "behave differently". For example, some can now jump or take cover in new ways (project lead Mark Noseworthy, via GameSpot, as reported by mein-mmo). — [mein-mmo](https://mein-mmo.de/en/destiny-2-drei-neue-gegner,161130) (secondary, read via search summary)
- **Fallen**:
  - Dregs are cannon fodder "fielded in large groups… to catch enemy fire or overwhelm". They carry a shock pistol firing 3-4 round bursts of slow, dodgeable projectiles, a shock dagger for melee, and arcing shock grenades. — [Destinypedia, Dreg](https://www.destinypedia.com/Dreg)
  - Vandals are "very agile, and will dodge from side to side to avoid incoming fire". Their shock rifles fire bursts of slow bolts that "curve around and home-in", avoidable by cover or well-timed strafing. — [Destinypedia, Vandal](https://www.destinypedia.com/Vandal)
  - Captains are squad leaders "almost always enshrouded within an Absorption Shield" and can teleport short distances. Their behavior shifts with squad strength: with squad support, high ground or good cover they strut and lay down suppressive fire, and they change behavior as their squad depletes. — [Destinypedia, Captain](https://www.destinypedia.com/Captain)
- **Hive**:
  - Thrall have no ranged weapon and "run as quickly as possible towards their foe", lunging in large packs. They are used "as a form of cannon fodder employed in wave-tactics to… distract enemies from targeting their more valuable units". — [Destinypedia, Thrall](https://www.destinypedia.com/Thrall)
  - Knights raise a "Wall of Darkness" frontal shield that blocks fire and restores health. They roll to dodge, and at low health go berserk (green aura) and rush for a heavy melee while regenerating. — [Destinypedia, Knight](https://www.destinypedia.com/Knight)
  - Wizards fly overhead casting spells. — [Destinypedia, Wizard](https://www.destinypedia.com/Wizard)
- **Vex**:
  - Goblins are fodder that serve "as a frontal diversion for a stronger Vex unit". They are slow, do not take cover, and can short-teleport. Their weak spot is an abdominal core, which they hide by hunching when threatened. A decapitated Goblin goes "berserk", firing faster and charging into melee. — [Destinypedia, Goblin](https://www.destinypedia.com/Goblin)
  - Hobgoblins are snipers. When attacked they seal themselves in an impenetrable shield that heals them, and burns players who step inside. They use slap grenades "to force players out of cover". — [Destinypedia, Hobgoblin](https://www.destinypedia.com/Hobgoblin)
  - Minotaurs "always charge… teleport erratically while flanking". Shooting the head off disables their teleport and shield but makes them berserk. — [Destinypedia, Minotaur](https://www.destinypedia.com/Minotaur)
- **Cabal**:
  - Legionaries are heavy, durable infantry with jump jets that make them faster than they look. Because they "fight in groups and close to each other, they can be quickly felled by area-of-effect weapons". — [Destinypedia, Legionary](https://www.destinypedia.com/Legionary)
  - In Destiny 1, a Phalanx's shield is immune to damage. The Phalanx advances to melee and shield-bashes, and the counter is shooting the exposed arm to stun it or using splash damage. In Destiny 2, Phalanxes can expand energy shields "to protect multiple Cabal soldiers". — [Destinypedia, Phalanx](https://www.destinypedia.com/Phalanx)
  - Psions serve as "engineers, pilots and fire support". — [Destinypedia, Psion](https://www.destinypedia.com/Psion)
- **Taken**: "Taken versions of enemies have radically different behaviors from their standard counterparts, including new abilities designed to counter Guardian abilities. Groups of Taken can be allied with members of different species." — [Destinypedia, Taken](https://www.destinypedia.com/Taken)
  - Taken Captain: "Darkness Bolt", which is fast, passes through walls, blinds and deafens, "can suppress a Guardian's Super". The Captain rapidly teleports to keep using it from the backline. — [Destinypedia, Taken Captain](https://www.destinypedia.com/Taken_Captain)
  - Taken Goblin: moves from fodder to support. It projects a beam that makes a nearby ally "immune to all damage", sits in the backline, and "can be tricked into defending non-important" targets. — [Destinypedia, Taken Goblin](https://www.destinypedia.com/Taken_Goblin)
  - Taken Psion: splits into a full-health copy and plays the frontline instead of hanging back. Copies take a moment to start moving, which makes them vulnerable to explosives. — [Destinypedia, Taken Psion](https://www.destinypedia.com/Taken_Psion)
  - Taken Phalanx: fires Arc blasts from its shield that "send targets flying", often placed near cliffs. A melee timed with the blast negates the knockback. — [Destinypedia, Taken Phalanx](https://www.destinypedia.com/Taken_Phalanx)
  - Taken Thrall: continuously teleports over each other while swarming, which makes them hard to hit at range. — [Destinypedia, Taken Thrall](https://www.destinypedia.com/Taken_Thrall)

### Inferences
- The Taken model is very efficient for a content-hungry looter. Reuse a faction's rigs and silhouettes, then attach one new rule-breaking ability per unit (shields an ally, splits, blinds, knocks back, teleports while swarming). The player's existing read of the unit plus one new rule gives a fresh encounter at low cost. It is Halo's "racial personality" principle applied as a second layer.
- Destiny repeatedly pairs a fodder unit with a "priority target" support unit (Goblins screening Minotaurs; Taken Goblins shielding Knights; Thrall distracting from Wizards). For top-down, that pairing (kill the support first, or the heavy is invulnerable) is one of the clearest target-priority puzzles available.
- Many Destiny units have a damage-state transformation (headless Goblin or Minotaur berserk, low-HP Knight rage). That is Halo's "breaking point" in reverse: the enemy gets more dangerous, signalling "finish me now".

### Gaps
- I found no Bungie primary talk on Destiny combatant AI architecture or faction behavior design. Behavior specifics come from Destinypedia. Scorn and Dread (newer factions) were not covered.

---

## 9. Champions (Barrier, Overload, Unstoppable) as build-check mechanics

### Takeaway
Champions (introduced in Shadowkeep, 2019) are mini-bosses with one of three counter-typed abilities. The matching "anti-champion" effect stuns them and suppresses the ability, and the right counters must be brought into high-difficulty content. They turn loadout choice into a pre-mission puzzle. Over time Bungie moved counters from seasonal-artifact armor mods toward intrinsic weapon traits and subclass verbs, making the check broader and less tied to a narrow item set.

### Cited Findings
- Barrier Champions: at one-third health, they raise a reflective dome that heals most lost health, and they fire faster inside it. Anti-Barrier effects break the shield. — [Destinypedia, Champion](https://www.destinypedia.com/Champion)
- Overload Champions: they heal quickly even under sustained fire and use abilities more often. Anti-Overload requires sustained "disruption" fire. Slow, Jolt and Suppression qualify. — [Destinypedia, Champion](https://www.destinypedia.com/Champion)
- Unstoppable Champions: they take heavily reduced damage, cannot be staggered or stunned, and are aggressive at close range, but cannot regenerate. Anti-Unstoppable (Shatter, Suspend, Blind, Ignition) is the only way to stagger them and remove the damage reduction. — [Destinypedia, Champion](https://www.destinypedia.com/Champion)
- Hitting a Champion with its matching effect stuns it and alerts nearby players. It briefly stops moving and cannot use its Champion ability until its red growths return. — [Destinypedia, Champion](https://www.destinypedia.com/Champion)
- Where they appear: guaranteed in Heroic or higher content (Nightfalls, Legend/Master Lost Sectors, raids from Garden of Salvation onward, seasonal activities). They rarely appear elsewhere. Counters evolved from seasonal-artifact armor mods to "Monument of Triumph" changes (anti-champion effects trigger by damaging the champion type with appropriate weapons, plus intrinsic weapon traits), with subclass verbs as a fallback. Stasis freeze briefly counted against all three types until Barrier Champions could break freeze. — [Destinypedia, Champion](https://www.destinypedia.com/Champion)
- Bungie's GDC 2022 talk "1000 Hours of Difficulty: How 'Destiny' Builds Systemic Challenge" (Alan Blaine) reportedly names seven "stressors" designers dial: time is power, thumbskill, battlefield awareness, communication, buildcraft, planning, and social. Champions and modifiers act mainly on buildcraft and planning (that last part is my inference). — [MassivelyOP GDC 2022 coverage](https://massivelyop.com/2022/03/29/gdc-2022-learning-from-the-seven-game-stressors-in-destiny-2/) (read only via search summary; the page returned 403 to fetch)

### Inferences
- For a top-down looter, three champion-style counters can map onto weapon properties the player already reads: "pierce/shield-break" for a barrier dome, "sustained hits/status" for a regenerator, and "heavy stagger" for a damage-reducing juggernaut. Show the required counter on the health bar and in the mission briefing, so it is a planning check, not a gotcha. Destiny's history suggests letting multiple sources apply the counter (weapon archetype, element status, ability), or champions become an "equip the one mod" chore.
- Champions work best at higher difficulties. Bungie confined guaranteed Champions to Heroic-plus content, so base content stays build-agnostic.

### Gaps
- I could not fetch the GDC 2022 talk itself or a full write-up, so the stressor list is secondhand. I found no Bungie statement of Champion design intent.

---

## 10. Abilities (grenade, melee, super) and the cooldown/orb economy

### Takeaway
Destiny layers three independent ability clocks (grenade, melee, super, plus a class ability) on top of guns. Each clock recharges passively over time and is accelerated by play: kills, precision kills, damage dealt, and picking up Orbs of Power that allies' supers and actions generate. Armor stats modify cooldowns. This makes "ability uptime" a build axis and encourages a kill to orb to super loop.

### Cited Findings
- The Super meter fills "slowly but gradually… over time (cooldown reduced with a higher Super stat on armor)", from defeating combatants, landing precision final blows, picking up Orbs of Power, and dealing damage. Some effects and mods spend part of the Super meter for benefits. Enemies can impede supers (Void suppression; the Taken Captain's Darkness Bolt). — [Destinypedia, Super](https://www.destinypedia.com/Super)
- Orbs of Power (formerly Orbs of Light) "recharge a player's Super meter, and are released whenever an ally uses a Super". Their use can be extended through armor mods. They have physics and "will be moved by explosions and roll down inclines", and are picked up by walking over them. — [Destinypedia, Orb of Power](https://www.destinypedia.com/Orb_of_Power)
- "Grenade cooldowns are modified by Discipline" (Discipline was the grenade-cooldown stat in the Destiny 2 armor stat system before 2025). Grenades are further modified by Aspects, Fragments and Exotics. For example, the Whisper of Shards Fragment speeds grenade recharge when shattering Stasis crystals. — [Destinypedia, Grenade](https://www.destinypedia.com/Grenade)
- Public-event rally flags in Destiny 2 "instantly recharge all of their abilities, including their Super, refill all ammunition". This is a pacing reset before an event. — [Destinypedia, Public Event](https://www.destinypedia.com/Public_Event)

### Inferences
- For a top-down looter, the Destiny structure transfers almost directly. Use three cooldown abilities with distinct roles (grenade = area control, melee = close-range burst or self-sustain, super = a room-clearing panic button) plus a pickup currency (orbs) dropped by kills, scaled by enemy tier, so killing tougher enemies feeds the super. Gear perks that convert actions into cooldown ("kills with X refund grenade energy") are where build identity forms.
- Rally points that refill abilities before a set piece (like public-event flags) are a cheap way to let players spend freely during a big fight without punishing them for using abilities on the approach.

### Gaps
- I did not retrieve exact base cooldown values or Bungie's stated rationale for cooldown tuning (for example, the 2017 launch criticism of slow cooldowns and later changes), or details of the 2025 Armor 3.0 stat rename beyond the Super-page mention.

---

## 11. Loot chase (exotics, random rolls, perks that change play) and public events

### Takeaway
Destiny's loot loop rests on two pillars. Exotics are build-defining, one-weapon and one-armor-slot items with unique play-changing perks. Legendaries have random perk rolls that make duplicate drops meaningful. Destiny 2 launched with fixed rolls, which made drops "static and pre-determined"; Forsaken (2018) restored random rolls. Public events provide a drop-in, timed, shared-world encounter format with tiered ratings and optional "heroic" escalations unlocked by hidden objectives.

### Cited Findings
- Exotics are "the highest Rarity tier… powerful and unique weapons, armor… distinct appearances and abilities". "Only one Exotic weapon and one Exotic armor can ever be equipped at any time." Destiny 2 exotics are augmented with Exotic Catalysts. Sources include quests, dungeons, raids and Nightfalls. — [Destinypedia, Exotic](https://www.destinypedia.com/Exotic)
- Destiny 2 Year 1 removed random perk rolls, and the response was divided. — [GamesRadar](https://gamesradar.com/destiny-2s-getting-rid-of-random-perk-rolls-for-loot-and-the-response-is-divided) (via search summary). Forsaken restored random rolls (mainly on new weapons; exotics kept fixed perks). Coverage framed it as fixing loot that was "static and pre-determined", where duplicates felt pointless ("Oh great, another identical Midnight Coup"). — [Shacknews](https://shacknews.com/article/106603/destiny-2-forsaken-brings-back-random-rolls-which-can-be-broken-down-for-weapon-mods); [mein-mmo](https://mein-mmo.de/en/destiny-2-forsaken-random-rolls,258634) (via search summary)
- Bungie later acknowledged a code issue that made "some random perk combinations harder to earn", showing how sensitive players are to perk-roll fairness. — [Windows Central](https://www.windowscentral.com/gaming/destiny-2-players-may-have-just-found-a-wild-perk-weighting-bug); [GamesRadar](https://gamesradar.com/games/destiny/destiny-2-faces-what-could-be-one-of-the-mmos-ugliest-bugs-ever-as-bungie-investigates-a-potential-issue-that-may-have-given-players-rigged-loot-for-months) (via search summary)
- Strikes drop strike-specific loot (for example, The Devils' Lair, The Summoning Pits gave a Devil's Dawn sniper and Hunter gauntlets), and playing consecutive playlist strikes increases the chance of better loot. — [Destinypedia, Strike](https://www.destinypedia.com/Strike)
- Public events, Destiny 1: types included defeating extraction crews in three waves before time runs out, defending a Warsat while the Ghost scans (faster with more Guardians nearby), destroying a Fallen Walker, eliminating a high-HP target before it reaches a checkpoint, and preventing Vex sacrifices. Bronze/Silver/Gold ratings depend on completion versus timer. There are also "the enemy is moving against each other" faction-infighting moments. — [Destinypedia, Public Event](https://www.destinypedia.com/Public_Event)
- Public events, Destiny 2: they are announced 5 minutes ahead with a map icon, and a rally flag refills abilities and ammo. Many have a heroic version triggered by a hidden condition. For example, Cryo-Pod Escape goes heroic by throwing orbs at the released boss to freeze it. Player-started "Protocols" such as Escalation Protocol use 7 escalating waves (kill Hive, close shadowrifts, kill more, kill a boss) with a weekly-rotating final boss. Blind Well uses Taken gas to force players into different areas. — [Destinypedia, Public Event](https://www.destinypedia.com/Public_Event)

### Inferences
- For a top-down looter: (1) keep a "one exotic weapon + one exotic armor" constraint so exotics define the build rather than stack; (2) random perk rolls on legendaries give every duplicate a chance to matter; (3) target perks that change verbs (on-kill effects, ability refunds, status application) over flat stat bumps; (4) make roll weighting transparent, since players notice skew.
- Public events offer a template for optional mid-mission side encounters in a hub or open zone. Use a timed objective, wave structure and a boss, a medal tier for speed, and a hidden "heroic" trigger that rewards players who learn the mechanic.

### Gaps
- I did not retrieve Bungie's own statements (TWAB or ViDoc) explaining the random-roll reversal, or any designer talk on exotic design philosophy.

---

## 12. What transfers to a top-down twin-stick / action-looter perspective

### Takeaway
Almost all of Halo's encounter philosophy and Destiny's mission and loot structure transfer. The main adaptations are for camera omniscience (the player sees more, so hide-and-seek and surprise need explicit perception cues) and for reading range and verticality on a flat plane. Most of this section is inference, labeled as such.

### Cited Findings (anchors for the inferences below)
- Designers own the 3-minute scope (territories, tasks, fallbacks); AI owns the 30-second scope (cover, dives, grenades). — [GDC 2002 p.5](https://halo.bungie.org/misc/gdc.2002.haloai/talk.html?page=5)
- The killing zone plus interconnected flank routes, and the collapse from an aggressive territory to a defensive cluster, covered about 80% of encounters. — [GDC 2002 p.18](https://halo.bungie.org/misc/gdc.2002.haloai/talk.html?page=18)
- Subtlety fails: exaggerate the leader-death flee. — [GDC 2002 p.19](https://halo.bungie.org/misc/gdc.2002.haloai/talk.html?page=19)
- Declarative task tree with priority, capacity and activation conditions ("plinko"). — [Isla, Halo 3 Objectives](https://web.cs.wpi.edu/~rich/courses/imgd4000-d10/lectures/halo3.pdf)
- Strike grammar: linear encounters, mini-boss, boss with adds. — [Destinypedia, Strike](https://www.destinypedia.com/Strike)
- Boss immunity gates and threshold phases. — [Destinypedia, Sepiks Prime](https://www.destinypedia.com/Sepiks_Prime); [Destinypedia, Bracus Zahn](https://www.destinypedia.com/Bracus_Zahn)
- Health-bar color taxonomy. — [Destinypedia, Elite](https://www.destinypedia.com/Elite)
- Champion counter-typing. — [Destinypedia, Champion](https://www.destinypedia.com/Champion)

### Inferences
1. **Encounter director**: implement Halo 3-style prioritized tasks (front, flank, fallback, last-stand, guard-leader, sniper perch, turret) with capacities and triggers (alive % below 75 or 50, leader dead, player crossed a line). Within tasks, give each archetype a short behavior list (cover/hide, fight, grenade, melee, search/pursue). This yields Halo's collapse pacing with little scripting.
2. **Racial personalities as caricatures**: one dominant trait per archetype (coward fodder, aggressive leader, shield-wall blocker, flanking teleporter, sniper that turtles), with a distinct first impression staged at introduction (Hunters debut "as the last line of defense" with music).
3. **Breaking points and berserk states**: a morale break on leader death (fodder scatters and stops shooting, a big exaggerated icon or VO bark) and a berserk on low HP or decapitation for elites. Both are readable top-down because the whole group is on screen.
4. **Perception made visible**: because the top-down camera shows the whole room, use alert states (unaware, suspicious, alerted, lost track), sniper laser tells, and "last known position" markers to restore Halo's hide-and-seek and stealth-melee openers.
5. **Arena layout**: an entry overlook, a central killing zone, cover clusters on both sides, two flank loops, a fallback line, a last-stand ring, and one "easy way" secret route. Use height sparingly (top-down reads elevation poorly), so prefer clear ledges or catwalks with readable edges.
6. **Strike-like mission template**: traversal, hold-the-point "hack" with 3 waves and a lieutenant, an open-arena heavy set piece, a gate with alarm reinforcements, then a boss with an immunity gate (clear adds, carry or dunk a charge) and 2-3 health-threshold phases that relocate the boss, summon adds, or demand a mechanic.
7. **Threat-color language**: red fodder, orange elite, yellow named, skull boss, plus champion icons. Scale orb and loot drops with tier.
8. **Champion build-checks** at higher difficulties only, with counters available from multiple sources and shown in the briefing.
9. **Ability economy**: grenade, melee and super on separate clocks, refilled by kills, precision and orbs. Gear perks convert actions into cooldown. Rally points refill everything before set pieces.
10. **Loot**: one exotic weapon plus one exotic armor slot, exotics that change verbs, random-rolled legendaries so duplicates matter, and activity-specific loot tables so each mission has a reason to be replayed.
11. **Difficulty**: keep it consistent within a mission, make enemies tough enough that their behavior is visible ("tougher AI = smarter AI": 8% vs 43% "very intelligent" in Bungie's playtest), and tune engagement range so fights happen at the distance where AI behavior reads best, which in top-down is on screen and mid-range.

### Gaps
- No source directly discusses adapting Halo or Destiny encounter design to a top-down camera. All points in this section are reasoned inferences.
