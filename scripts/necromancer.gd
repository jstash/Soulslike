extends "res://scripts/enemy_base.gd"

# Necromancer – ranged enemy that shoots cursed bolts and summons skeletons

const ROBE_COLOR  := Color8(30, 30, 60)
const TRIM_COLOR  := Color8(100, 60, 150)
const GLOW_COLOR  := Color(0.5, 0.2, 1.0)

var bolt_scene: PackedScene
var skeleton_scene: PackedScene

var summon_cd: float = 0.0
const SUMMON_CD_MAX: float = 8.0
var max_summons: int = 2
var active_summons: int = 0

# Preferred fighting distance – stay back
const PREFERRED_DIST: float = 70.0

var cast_timer: float = 0.0
var is_casting: bool = false

func _on_ready_extra() -> void:
	max_hp      = 80
	hp          = max_hp
	move_speed  = 35.0
	attack_damage = 15
	attack_range  = 85.0       # bolt range
	attack_cd_max = 2.2
	souls_value   = 60
	aggro_range   = 100.0
	knockback_resist = 0.3

	bolt_scene = load("res://scenes/projectile.tscn")
	skeleton_scene = load("res://scenes/enemies/skeleton.tscn")

func _on_attack_started() -> void:
	is_casting = true
	cast_timer = attack_duration

func _update_ai(delta: float) -> void:
	summon_cd = max(0.0, summon_cd - delta)
	if is_casting:
		cast_timer -= delta
		if cast_timer <= 0.0:
			is_casting = false
			_fire_bolt()

	# Override base chase to keep distance
	if not player:
		player = get_tree().get_first_node_in_group("player")

	match ai_state:
		AIState.PATROL:
			_do_patrol(delta)
			if player and global_position.distance_to(player.global_position) < aggro_range:
				ai_state = AIState.CHASE

		AIState.CHASE:
			if not player:
				ai_state = AIState.PATROL
				return
			var dist := global_position.distance_to(player.global_position)
			if dist > deaggro_range:
				ai_state = AIState.PATROL
				return

			# Try to summon
			if summon_cd <= 0.0 and active_summons < max_summons:
				_summon_skeleton()

			if dist < PREFERRED_DIST * 0.6:
				# Too close – back away
				var dir := signf(global_position.x - player.global_position.x)
				velocity.x = dir * move_speed * 0.8
				facing = -dir
			elif dist < attack_range:
				_start_attack()
				velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
			else:
				_chase_player()

		AIState.ATTACK:
			attack_timer -= delta
			velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
			if attack_timer <= 0.0:
				is_casting = false
				attack_shape.disabled = true
				ai_state = AIState.CHASE

		AIState.STAGGER:
			stagger_timer -= delta
			velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
			if stagger_timer <= 0.0:
				ai_state = AIState.CHASE

func _fire_bolt() -> void:
	if not bolt_scene or not player:
		return
	var spawn_pos := global_position + Vector2(0, -10)
	var dir := (player.global_position + Vector2(0, -8) - spawn_pos).normalized()
	var p := bolt_scene.instantiate()
	get_parent().add_child(p)
	p.global_position = spawn_pos
	p.setup_enemy_bolt(attack_damage, Color(0.5, 0.1, 0.9), dir)

func _summon_skeleton() -> void:
	if not skeleton_scene:
		return
	summon_cd = SUMMON_CD_MAX
	var skel := skeleton_scene.instantiate()
	get_parent().add_child(skel)
	skel.global_position = global_position + Vector2(randf_range(-20, 20), 0)
	skel.died.connect(func(_pos, _souls): active_summons -= 1)
	active_summons += 1

func _on_death_extra() -> void:
	is_casting = false

func _animate(delta: float) -> void:
	anim_timer += delta
	if anim_timer > 0.18:
		anim_timer = 0.0
		anim_frame = (anim_frame + 1) % 4

func _draw() -> void:
	if ai_state == AIState.DEAD:
		draw_rect(Rect2(-7, 2, 14, 5), ROBE_COLOR)
		return

	var flash := hurt_flash > 0.3
	var rc := Color.WHITE if flash else ROBE_COLOR
	var tc := Color.WHITE if flash else TRIM_COLOR
	var t := Time.get_ticks_msec() * 0.006

	_draw_ellipse(Vector2(0, 8), Vector2(6, 2.5), Color(0, 0, 0, 0.3))

	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))
	draw_rect(Rect2(-3, -16, 6, 14), rc)
	draw_rect(Rect2(-4, -4,  8, 2),  tc)
	draw_rect(Rect2(-3, -22, 6, 7),  rc)
	draw_rect(Rect2(-2, -23, 4, 2),  tc)
	draw_rect(Rect2(-1, -20, 1, 2), Color(0.6, 0.3, 0.9, 0.9))
	draw_rect(Rect2(1,  -20, 1, 2), Color(0.6, 0.3, 0.9, 0.9))
	# Staff (right/forward side)
	draw_rect(Rect2(5, -24, 1, 18), tc)
	var orb_glow := 0.7 + sin(t) * 0.3
	draw_circle(Vector2(5, -24), 3.5, Color(GLOW_COLOR.r, GLOW_COLOR.g, GLOW_COLOR.b, orb_glow))
	if is_casting:
		draw_circle(Vector2(5, -24), 6.0 + sin(t * 3.0) * 2.0, Color(0.8, 0.4, 1.0, 0.4))
	draw_set_transform(Vector2.ZERO)

	_draw_hp_bar()

func _draw_hp_bar() -> void:
	var bar_w := 16
	draw_rect(Rect2(-bar_w/2, -27, bar_w, 2), Color(0.1, 0.0, 0.1, 0.8))
	draw_rect(Rect2(-bar_w/2, -27, int(bar_w * float(hp) / float(max_hp)), 2), Color(0.6, 0.1, 0.8))

func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(12):
		var a := TAU * i / 12.0
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	draw_polygon(pts, PackedColorArray([color]))
