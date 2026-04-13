extends "res://scripts/enemy_base.gd"

# High Priest – boss enemy with two phases

const ROBE1   := Color8(60, 10, 10)
const ROBE2   := Color8(120, 20, 20)
const TRIM    := Color8(200, 160, 40)
const GLOW1   := Color(1.0, 0.2, 0.2)
const GLOW2   := Color(0.8, 0.0, 1.0)

signal phase_changed(phase: int)
signal boss_died

var phase: int = 1
var phase2_threshold: float = 0.45   # switch at 45% HP

var bolt_scene: PackedScene
var skeleton_scene: PackedScene

var summon_cd: float = 0.0
var bolt_burst_cd: float = 0.0
var is_casting: bool = false
var cast_timer: float = 0.0
var ritual_timer: float = 0.0   # short invincibility during ritual cast

# Ground slam
var slam_timer: float = 0.0
var slam_cd: float = 0.0
var slam_wave_active: bool = false

# Big aoe indicator
var aoe_warning: bool = false
var aoe_timer: float = 0.0
const AOE_RADIUS: float = 50.0

func _on_ready_extra() -> void:
	max_hp         = 350
	hp             = max_hp
	move_speed     = 38.0
	attack_damage  = 20
	attack_range   = 28.0
	attack_cd_max  = 2.0
	souls_value    = 300
	aggro_range    = 300.0   # auto-aggro entire arena
	knockback_resist = 0.1

	bolt_scene     = load("res://scenes/projectile.tscn")
	skeleton_scene = load("res://scenes/enemies/skeleton.tscn")

# ─── Phase check ─────────────────────────────────────────────────────────
func _check_phase() -> void:
	if phase == 1 and float(hp) / float(max_hp) <= phase2_threshold:
		phase = 2
		emit_signal("phase_changed", 2)
		# Trigger dramatic ritual
		_start_ritual()
		# Boost stats
		move_speed = 55.0
		attack_damage = 28
		attack_cd_max = 1.4
		summon_cd = 0.0
		bolt_burst_cd = 0.0

var boss_invincible: bool = false

func _start_ritual() -> void:
	ritual_timer = 2.0
	boss_invincible = true   # brief invincibility during ritual roar

# ─── Override AI ─────────────────────────────────────────────────────────
func _update_ai(delta: float) -> void:
	summon_cd     = max(0.0, summon_cd - delta)
	bolt_burst_cd = max(0.0, bolt_burst_cd - delta)
	slam_cd       = max(0.0, slam_cd - delta)

	if ritual_timer > 0.0:
		ritual_timer -= delta
		if ritual_timer <= 0.0:
			boss_invincible = false
		return

	if aoe_warning:
		aoe_timer -= delta
		if aoe_timer <= 0.0:
			aoe_warning = false
			_do_aoe_blast()

	if is_casting:
		cast_timer -= delta
		if cast_timer <= 0.0:
			is_casting = false
			_fire_bolt_burst()

	if slam_timer > 0.0:
		slam_timer -= delta
		return

	if not player:
		player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	var dist := global_position.distance_to(player.global_position)
	_check_phase()

	match ai_state:
		AIState.PATROL, AIState.CHASE:
			if dist < attack_range:
				_start_attack()
			elif dist < attack_range * 3.0 and bolt_burst_cd <= 0.0:
				_start_cast()
			elif phase == 2 and slam_cd <= 0.0 and dist < 60.0:
				_start_aoe_warning()
			elif phase == 2 and summon_cd <= 0.0:
				_do_summon_wave()
			elif dist > 10.0:
				_chase_player()
			ai_state = AIState.CHASE

		AIState.ATTACK:
			attack_timer -= delta
			velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
			if attack_timer <= 0.0:
				attack_shape.disabled = true
				is_attacking = false
				ai_state = AIState.CHASE

		AIState.STAGGER:
			stagger_timer -= delta
			velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
			if stagger_timer <= 0.0:
				ai_state = AIState.CHASE

func _start_cast() -> void:
	bolt_burst_cd = 3.5 if phase == 1 else 2.2
	is_casting = true
	cast_timer = 0.5
	velocity.x = 0.0

func _fire_bolt_burst() -> void:
	if not bolt_scene or not player:
		return
	var count := 3 if phase == 1 else 5
	var spawn_pos := global_position + Vector2(0, -12)
	var base_dir := (player.global_position + Vector2(0, -8) - spawn_pos).normalized()
	for i in range(count):
		var spread := deg_to_rad((i - count / 2) * 12.0)
		var dir := base_dir.rotated(spread)
		var dmg := 15 if phase == 1 else 20
		var p := bolt_scene.instantiate()
		get_parent().add_child(p)
		p.global_position = spawn_pos
		p.setup_enemy_bolt(dmg, Color(0.9, 0.1, 0.1), dir)

func _do_summon_wave() -> void:
	if not skeleton_scene:
		return
	summon_cd = 7.0
	var count := 2 if phase == 1 else 3
	for i in range(count):
		var skel := skeleton_scene.instantiate()
		get_parent().add_child(skel)
		skel.global_position = global_position + Vector2(randf_range(-30, 30), 0)

func _start_aoe_warning() -> void:
	aoe_warning = true
	aoe_timer = 1.2
	slam_cd = 5.0

func _do_aoe_blast() -> void:
	slam_wave_active = true
	await get_tree().create_timer(0.1).timeout
	slam_wave_active = false
	# Damage player if in range
	if player and global_position.distance_to(player.global_position) < AOE_RADIUS:
		player.take_damage(30, Vector2(sign(player.global_position.x - global_position.x) * 200, -150))

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if boss_invincible:
		return
	super.take_damage(amount, knockback)

func _on_death_extra() -> void:
	emit_signal("boss_died")

# ─── Drawing ─────────────────────────────────────────────────────────────
func _animate(delta: float) -> void:
	anim_timer += delta
	if anim_timer > 0.14:
		anim_timer = 0.0
		anim_frame = (anim_frame + 1) % 4

func _draw() -> void:
	if ai_state == AIState.DEAD:
		draw_rect(Rect2(-10, 2, 20, 7), ROBE1)
		return

	var flash := hurt_flash > 0.3
	var rc: Color = Color.WHITE if flash else (ROBE2 if phase == 2 else ROBE1)
	var tc := Color.WHITE if flash else TRIM
	var glow_c := GLOW2 if phase == 2 else GLOW1
	var t := Time.get_ticks_msec() * 0.005
	var orb_r := 5.0 + sin(t) * 2.0

	_draw_ellipse(Vector2(0, 10), Vector2(9, 3.5), Color(0, 0, 0, 0.4))

	if aoe_warning:
		_draw_ring(AOE_RADIUS, Color(glow_c.r, glow_c.g, glow_c.b, 0.5 + sin(t * 6.0) * 0.4))

	if phase == 2:
		for i in range(8):
			var a := TAU * i / 8.0 + t
			var r := 14.0 + sin(t * 2.0 + i) * 3.0
			draw_circle(Vector2(cos(a) * r, -10 + sin(a) * r * 0.4), 2.0, Color(glow_c.r, glow_c.g, glow_c.b, 0.3))

	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))

	draw_rect(Rect2(-5, -22, 10, 20), rc)
	draw_rect(Rect2(-6, -6,  12, 4),  rc)
	draw_rect(Rect2(-6, -7,  12, 2),  tc)
	draw_rect(Rect2(-5, -24, 10, 3),  tc)
	draw_rect(Rect2(-4, -30, 8,  9),  rc)
	draw_rect(Rect2(-3, -32, 6,  3),  tc)
	draw_rect(Rect2(0,  -34, 1,  3),  tc)
	draw_rect(Rect2(-2, -33, 1,  2),  tc)
	draw_rect(Rect2(2,  -33, 1,  2),  tc)
	var eye_bright := 0.9 + sin(t * 4.0) * 0.1
	draw_rect(Rect2(-2, -28, 2, 2), Color(glow_c.r, glow_c.g, glow_c.b, eye_bright))
	draw_rect(Rect2(1,  -28, 2, 2), Color(glow_c.r, glow_c.g, glow_c.b, eye_bright))
	# Staff (right side)
	draw_rect(Rect2(6, -34, 2, 24), tc)
	draw_rect(Rect2(5, -38, 4, 5), Color8(220, 210, 180))
	draw_rect(Rect2(6, -37, 1, 1), Color(0.9, 0.1, 0.1))
	draw_rect(Rect2(7, -37, 1, 1), Color(0.9, 0.1, 0.1))
	draw_circle(Vector2(7, -40), orb_r, Color(glow_c.r, glow_c.g, glow_c.b, 0.6 + sin(t * 2.0) * 0.3))
	if is_casting:
		draw_circle(Vector2(7, -40), orb_r + 6.0, Color(glow_c.r, glow_c.g, glow_c.b, 0.3))

	draw_set_transform(Vector2.ZERO)

	if ritual_timer > 0.0:
		_draw_ring(20.0, Color(glow_c.r, glow_c.g, glow_c.b, 0.5 + sin(t * 8.0) * 0.4))

	_draw_boss_hp_bar()

func _draw_boss_hp_bar() -> void:
	# Drawn by HUD instead, but draw a small one above for local feedback
	var bar_w := 24
	draw_rect(Rect2(-bar_w/2, -43, bar_w, 3), Color(0.1, 0.0, 0.0, 0.9))
	draw_rect(Rect2(-bar_w/2, -43, int(bar_w * float(hp) / float(max_hp)), 3), GLOW2 if phase == 2 else GLOW1)

func _draw_ring(radius: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(32):
		var a := TAU * i / 32.0
		pts.append(Vector2(cos(a) * radius, sin(a) * radius * 0.4 + 0))
	draw_polyline(pts + PackedVector2Array([pts[0]]), color, 1.5)

func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(12):
		var a := TAU * i / 12.0
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	draw_polygon(pts, PackedColorArray([color]))
