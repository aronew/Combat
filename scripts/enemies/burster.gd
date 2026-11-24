class_name Burster
extends Enemy
## Bloated runner with a volatile sac. Gets close, swells for a moment, then
## blows up, hurting EVERYTHING nearby, other bugs included. Killing it also
## sets it off (after a tiny delay so chains ripple), so shoot it inside a crowd.

@export_group("Burst")
@export var trigger_range := 1.8
@export var fuse_time := 0.55
@export var blast_radius := 3.4
@export var blast_enemy_damage := 75.0
@export var blast_player_damage := 20.0
@export var blast_knockback := 13.0

var _fuse := -1.0


func _on_spawned() -> void:
	_fuse = -1.0


func _attack_tick(player: Player, _delta: float) -> void:
	if _fuse >= 0.0:
		return
	var d := Vector2(player.global_position.x - global_position.x, player.global_position.z - global_position.z)
	if d.length() < trigger_range * _tier_scale:
		_fuse = fuse_time
		play_anim_oneshot(&"swell")
		Audio.play_at(&"burster_swell", global_position, 0.0, 1.0 / _tier_scale)


func _custom_tick(delta: float) -> bool:
	if _fuse < 0.0 or state != State.CHASE:
		return false
	_fuse -= delta
	var k := 1.0 - _fuse / fuse_time
	visual.scale = Vector3.ONE * _tier_scale * (1.0 + 0.4 * k)
	_set_flash(fmod(k * 7.0, 1.0) > 0.5)
	_settle(delta)
	if _fuse <= 0.0:
		_detonate()
	return true


func _detonate() -> void:
	var pos := global_position + Vector3.UP * 0.4
	Audio.play_at(&"burster_pop", pos)
	Game.explode(pos, blast_radius * _tier_scale, blast_enemy_damage * damage_mult, blast_player_damage * damage_mult,
			blast_knockback, self, 2.2 * _tier_scale)
	_die(Vector3.ZERO, &"self")


func _on_death(_direction: Vector3, kind: StringName) -> void:
	if kind == &"self":
		return
	Audio.play_at(&"burster_pop", global_position)
	Game.delayed_explode(0.12, global_position + Vector3.UP * 0.4, blast_radius * _tier_scale,
			blast_enemy_damage * damage_mult, blast_player_damage * damage_mult, blast_knockback, null, 2.2 * _tier_scale)
