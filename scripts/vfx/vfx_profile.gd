class_name VfxProfile
extends Resource
## Tuning for one effect, kept out of the scene so weapons and enemies can share
## a scene but look different (a rifle's muzzle vs an SMG's, amber vs lime ichor).

@export var color := Color(1, 1, 1)
## Overall brightness / opacity multiplier for the effect's parts.
@export_range(0.0, 4.0) var intensity := 1.0
@export var scale := 1.0
## Particle count multiplier (on top of the graphics quality setting).
@export_range(0.0, 2.0) var particle_mult := 1.0
## Light pop (0 energy = none).
@export var light_energy := 0.0
@export var light_range := 6.0
@export var light_color := Color(1, 0.8, 0.5)
## Camera and hitstop response, if any.
@export var feedback: CameraFeedback
