@tool
extends WorldEnvironment
## Builds the dark teal-fog look from the concept art. Every knob is exported and
## applies live in the editor. The thick fog in the void itself is a FogVolume
## created by the Arena (see Arena > Void).

@export_group("Background & ambient")
@export var background_color := Color("0b2b2a"):
	set(v): background_color = v; _apply()
@export var ambient_color := Color("3f8f8a"):
	set(v): ambient_color = v; _apply()
@export_range(0.0, 2.0) var ambient_energy := 0.45:
	set(v): ambient_energy = v; _apply()

@export_group("Depth fog")
@export var fog_enabled := true:
	set(v): fog_enabled = v; _apply()
@export var fog_color := Color("1f6f69"):
	set(v): fog_color = v; _apply()
@export_range(0.0, 0.1, 0.0005) var fog_density := 0.006:
	set(v): fog_density = v; _apply()
## Fog thickens below this height, filling the void under the platform.
@export var fog_height := -3.0:
	set(v): fog_height = v; _apply()
@export_range(0.0, 2.0) var fog_height_density := 0.12:
	set(v): fog_height_density = v; _apply()

@export_group("Volumetric fog")
@export var volumetric_enabled := true:
	set(v): volumetric_enabled = v; _apply()
@export_range(0.0, 0.2, 0.001) var volumetric_density := 0.006:
	set(v): volumetric_density = v; _apply()
@export var volumetric_albedo := Color("9fe8e0"):
	set(v): volumetric_albedo = v; _apply()
@export var volumetric_emission := Color("082a28"):
	set(v): volumetric_emission = v; _apply()
@export_range(0.0, 4.0) var volumetric_emission_energy := 1.0:
	set(v): volumetric_emission_energy = v; _apply()
@export var volumetric_length := 140.0:
	set(v): volumetric_length = v; _apply()

@export_group("Glow")
@export var glow_enabled := true:
	set(v): glow_enabled = v; _apply()
@export_range(0.0, 8.0) var glow_intensity := 1.0:
	set(v): glow_intensity = v; _apply()
@export_range(0.0, 2.0) var glow_strength := 1.0:
	set(v): glow_strength = v; _apply()
@export_range(0.0, 1.0) var glow_bloom := 0.05:
	set(v): glow_bloom = v; _apply()
@export_range(0.0, 4.0) var glow_hdr_threshold := 1.0:
	set(v): glow_hdr_threshold = v; _apply()

@export_group("Tonemap & grading")
@export_range(0.1, 4.0) var exposure := 1.0:
	set(v): exposure = v; _apply()
@export_range(0.5, 2.0) var saturation := 1.15:
	set(v): saturation = v; _apply()
@export_range(0.5, 2.0) var contrast := 1.08:
	set(v): contrast = v; _apply()
@export var ssao_enabled := true:
	set(v): ssao_enabled = v; _apply()


func _ready() -> void:
	_apply()


func _apply() -> void:
	if environment == null:
		environment = Environment.new()
	var e := environment
	e.background_mode = Environment.BG_COLOR
	e.background_color = background_color
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = ambient_color
	e.ambient_light_energy = ambient_energy

	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_exposure = exposure
	e.tonemap_white = 6.0

	e.fog_enabled = fog_enabled
	e.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	e.fog_light_color = fog_color
	e.fog_light_energy = 1.0
	e.fog_density = fog_density
	e.fog_sky_affect = 1.0
	e.fog_height = fog_height
	e.fog_height_density = fog_height_density
	e.fog_aerial_perspective = 0.0

	e.volumetric_fog_enabled = volumetric_enabled
	e.volumetric_fog_density = volumetric_density
	e.volumetric_fog_albedo = volumetric_albedo
	e.volumetric_fog_emission = volumetric_emission
	e.volumetric_fog_emission_energy = volumetric_emission_energy
	e.volumetric_fog_length = volumetric_length
	e.volumetric_fog_detail_spread = 1.5
	e.volumetric_fog_ambient_inject = 0.3
	e.volumetric_fog_anisotropy = 0.3

	e.glow_enabled = glow_enabled
	e.glow_intensity = glow_intensity
	e.glow_strength = glow_strength
	e.glow_bloom = glow_bloom
	e.glow_hdr_threshold = glow_hdr_threshold
	e.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	for i in 7:
		e.set_glow_level(i, 1.0 if i in [1, 2, 3, 4] else 0.0)

	e.ssao_enabled = ssao_enabled
	e.ssao_radius = 1.2
	e.ssao_intensity = 1.6

	e.adjustment_enabled = true
	e.adjustment_saturation = saturation
	e.adjustment_contrast = contrast
	e.adjustment_brightness = 1.0
