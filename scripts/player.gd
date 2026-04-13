extends CharacterBody2D

signal hp_changed(hp: int, max_hp: int)
signal stamina_changed(stamina: float, max_stamina: float)
signal souls_changed(souls: int)
signal flasks_changed(flasks: int, max_flasks: int)
signal player_died

# ─── Stats (loaded from GameManager) ───────────────────────────────────────
var max_hp: int = 100
var hp: int = 100
var max_stamina: float = 100.0
var stamina: float = 100.0
var move_speed: float = 100.0
var jump_force: float = -310.0
var damage_reduction: float = 0.0
var attack_damage: int = 20
var attack_range: float = 30.0
var attack_cost: float = 20.0
var dodge_cost: float = 25.0
var special_damage: int = 40
var special_cost: float = 50.0
var special_range: float = 40.0
var special_knockback: float = 80.0

var player_class: int = 0
var class_color1: Color = Color.WHITE
var class_color2: Color = Color.GRAY

# ─── Souls carried ─────────────────────────────────────────────────────────
var carried_souls: int = 0

# ─── State machine ─────────────────────────────────────────────────────────
enum State { IDLE, RUN, JUMP, FALL, ATTACK, SPECIAL, DODGE, HURT, DEAD }
var state: State = State.IDLE

# ─── Combat ────────────────────────────────────────────────────────────────
var attack_timer: float = 0.0
var attack_duration: float = 0.30
var attack_cd: float = 0.0
var attack_cd_max: float = 0.45

var special_timer: float = 0.0
var special_duration: float = 0.40
var special_cd: float = 0.0
var special_cd_max: float = 1.4

# ─── Dodge ──────────────────────────────────────────────────────────────────
var dodge_timer: float = 0.0
var dodge_duration: float = 0.32
var dodge_cd: float = 0.0
var dodge_cd_max: float = 0.70
var dodge_dir: float = 1.0
const DODGE_SPEED: float = 230.0

# ─── Hurt / invincibility ──────────────────────────────────────────────────
var hurt_timer: float = 0.0
var hurt_duration: float = 0.50
var invincible: bool = false

# ─── Stamina regen ─────────────────────────────────────────────────────────
var stamina_regen_rate: float = 32.0
var stamina_regen_delay: float = 1.0
var stamina_regen_timer: float = 0.0

# ─── Jump ──────────────────────────────────────────────────────────────────
var coyote_timer: float = 0.0
var jump_buffer: float = 0.0
const COYOTE_TIME: float = 0.12
const JUMP_BUFFER: float = 0.10
var has_double_jump: bool = false
var double_jump_used: bool = false

# ─── Facing ────────────────────────────────────────────────────────────────
var facing: int = 1   # 1 = right, -1 = left

# ─── Animation ─────────────────────────────────────────────────────────────
var anim_timer: float = 0.0
var anim_frame: int = 0
var walk_anim_speed: float = 0.12

# ─── Flask ─────────────────────────────────────────────────────────────────
const FLASK_HEAL: int = 40
var flask_cd: float = 0.0

# ─── Physics ───────────────────────────────────────────────────────────────
const GRAVITY: float = 900.0

# ─── Lost-soul marker (for display) ────────────────────────────────────────
var lost_soul_marker: Node2D = null

# ─── Nodes ─────────────────────────────────────────────────────────────────
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/Shape
@onready var hurt_area: Area2D = $HurtArea

func _ready() -> void:
	add_to_group("player")
	var d := GameManager.get_class_data()
	player_class   = GameManager.chosen_class
	max_hp         = d.max_hp
	hp             = max_hp
	max_stamina    = d.max_stamina
	stamina        = max_stamina
	move_speed     = d.speed
	jump_force     = d.jump_force
	damage_reduction = d.damage_reduction
	attack_damage  = d.attack_damage
	attack_range   = d.attack_range
	attack_cost    = d.attack_cost
	dodge_cost     = d.dodge_cost
	special_damage = d.special_damage
	special_cost   = d.special_cost
	special_range  = d.special_range
	special_knockback = d.special_knockback
	class_color1   = d.color1
	class_color2   = d.color2

	# Assassin gets double jump
	if player_class == 2:
		has_double_jump = true

	attack_shape.disabled = true
	attack_area.body_entered.connect(_on_attack_hit)
	attack_area.area_entered.connect(_on_attack_area)

	global_position = GameManager.last_checkpoint_pos
	carried_souls = 0

	# Spawn lost-soul marker if souls were lost
	if GameManager.lost_souls > 0:
		_spawn_lost_soul_marker()

	emit_signal("hp_changed", hp, max_hp)
	emit_signal("stamina_changed", stamina, max_stamina)
	emit_signal("souls_changed", GameManager.souls)
	emit_signal("flasks_changed", GameManager.flask_uses, GameManager.max_flask_uses)

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	_handle_gravity(delta)
	_handle_timers(delta)
	_handle_stamina_regen(delta)
	_handle_input(delta)
	_handle_lost_souls()
	move_and_slide()
	_update_animation(delta)
	queue_redraw()

# ─── Gravity ───────────────────────────────────────────────────────────────
func _handle_gravity(delta: float) -> void:
	if is_on_floor():
		coyote_timer = COYOTE_TIME
		double_jump_used = false
		if velocity.y > 0:
			velocity.y = 0
	else:
		coyote_timer = max(0.0, coyote_timer - delta)
		velocity.y += GRAVITY * delta
		velocity.y = min(velocity.y, 600.0)

# ─── Timers (attack/special/dodge/hurt) ────────────────────────────────────
func _handle_timers(delta: float) -> void:
	attack_cd  = max(0.0, attack_cd - delta)
	special_cd = max(0.0, special_cd - delta)
	dodge_cd   = max(0.0, dodge_cd - delta)
	flask_cd   = max(0.0, flask_cd - delta)
	jump_buffer = max(0.0, jump_buffer - delta)

	if state == State.ATTACK:
		attack_timer -= delta
		if attack_timer <= 0.0:
			attack_shape.disabled = true
			_set_state(State.IDLE)

	if state == State.SPECIAL:
		special_timer -= delta
		if special_timer <= 0.0:
			attack_shape.disabled = true
			_set_state(State.IDLE)

	if state == State.DODGE:
		dodge_timer -= delta
		velocity.x = dodge_dir * DODGE_SPEED
		if dodge_timer <= 0.0:
			invincible = false
			_set_state(State.IDLE)

	if state == State.HURT:
		hurt_timer -= delta
		if hurt_timer <= 0.0:
			invincible = false
			_set_state(State.IDLE)

# ─── Stamina regen ─────────────────────────────────────────────────────────
func _handle_stamina_regen(delta: float) -> void:
	if stamina_regen_timer > 0.0:
		stamina_regen_timer -= delta
	else:
		if stamina < max_stamina:
			stamina = min(max_stamina, stamina + stamina_regen_rate * delta)
			emit_signal("stamina_changed", stamina, max_stamina)

# ─── Input ─────────────────────────────────────────────────────────────────
func _handle_input(delta: float) -> void:
	if state in [State.ATTACK, State.SPECIAL, State.HURT, State.DEAD]:
		# Allow jump buffer during attacks
		if Input.is_action_just_pressed("jump"):
			jump_buffer = JUMP_BUFFER
		return

	var dir := Input.get_axis("move_left", "move_right")

	# Dodge takes over movement
	if state == State.DODGE:
		if Input.is_action_just_pressed("jump"):
			jump_buffer = JUMP_BUFFER
		return

	# Horizontal movement
	if dir != 0.0:
		velocity.x = dir * move_speed
		facing = int(sign(dir))
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 8.0 * delta)

	# Jump
	if Input.is_action_just_pressed("jump"):
		jump_buffer = JUMP_BUFFER

	if jump_buffer > 0.0 and (coyote_timer > 0.0 or (has_double_jump and not double_jump_used and not is_on_floor())):
		if not is_on_floor() and has_double_jump:
			double_jump_used = true
		velocity.y = jump_force
		coyote_timer = 0.0
		jump_buffer = 0.0

	# Attack
	if Input.is_action_just_pressed("attack") and attack_cd <= 0.0 and stamina >= attack_cost:
		_do_attack()

	# Special
	elif Input.is_action_just_pressed("special") and special_cd <= 0.0 and stamina >= special_cost:
		_do_special()

	# Dodge
	elif Input.is_action_just_pressed("dodge") and dodge_cd <= 0.0 and stamina >= dodge_cost:
		_do_dodge(dir)

	# Flask
	elif Input.is_action_just_pressed("use_flask") and GameManager.flask_uses > 0 and flask_cd <= 0.0 and hp < max_hp:
		_use_flask()

	# Update state based on movement
	if state not in [State.ATTACK, State.SPECIAL, State.DODGE, State.HURT]:
		if is_on_floor():
			_set_state(State.RUN if abs(velocity.x) > 4.0 else State.IDLE)
		else:
			_set_state(State.FALL if velocity.y > 0.0 else State.JUMP)

# ─── Lost souls recovery ────────────────────────────────────────────────────
func _handle_lost_souls() -> void:
	if GameManager.lost_souls > 0:
		if global_position.distance_to(GameManager.lost_souls_position) < 20.0:
			GameManager.souls += GameManager.lost_souls
			GameManager.lost_souls = 0
			GameManager.lost_souls_position = Vector2.ZERO
			emit_signal("souls_changed", GameManager.souls)
			if lost_soul_marker:
				lost_soul_marker.queue_free()
				lost_soul_marker = null

# ─── Combat actions ────────────────────────────────────────────────────────
func _do_attack() -> void:
	_spend_stamina(attack_cost)
	attack_cd = attack_cd_max
	attack_timer = attack_duration

	# Position attack hitbox
	attack_shape.shape.size = Vector2(attack_range, 18.0)
	attack_area.position = Vector2(facing * (attack_range * 0.5 + 4.0), -4.0)
	attack_shape.disabled = false

	velocity.x = 0.0
	_set_state(State.ATTACK)

func _do_special() -> void:
	match player_class:
		0: # Knight – Shield Bash
			_spend_stamina(special_cost)
			special_cd = special_cd_max
			special_timer = special_duration
			attack_shape.shape.size = Vector2(special_range, 20.0)
			attack_area.position = Vector2(facing * (special_range * 0.5 + 4.0), -4.0)
			attack_shape.disabled = false
			velocity.x = facing * 60.0
			_set_state(State.SPECIAL)

		1: # Pyromancer – Fire Wave (projectile spray)
			_spend_stamina(special_cost)
			special_cd = special_cd_max
			special_timer = special_duration
			_spawn_fire_wave()
			_set_state(State.SPECIAL)

		2: # Assassin – Shadow Strike (dash + teleport to nearest enemy)
			var nearest := _find_nearest_enemy(special_range)
			if nearest:
				_spend_stamina(special_cost)
				special_cd = special_cd_max
				special_timer = 0.20
				global_position = nearest.global_position + Vector2(-facing * 10.0, 0.0)
				attack_shape.shape.size = Vector2(22.0, 18.0)
				attack_area.position = Vector2(facing * 14.0, -4.0)
				attack_shape.disabled = false
				_set_state(State.SPECIAL)

func _do_dodge(dir: float) -> void:
	_spend_stamina(dodge_cost)
	dodge_cd = dodge_cd_max
	dodge_timer = dodge_duration
	dodge_dir = facing if dir == 0.0 else sign(dir)
	invincible = true
	velocity.y = min(velocity.y, 0.0)
	_set_state(State.DODGE)

func _use_flask() -> void:
	GameManager.flask_uses -= 1
	flask_cd = 0.8
	hp = min(max_hp, hp + FLASK_HEAL)
	emit_signal("hp_changed", hp, max_hp)
	emit_signal("flasks_changed", GameManager.flask_uses, GameManager.max_flask_uses)

func _spend_stamina(amount: float) -> void:
	stamina = max(0.0, stamina - amount)
	stamina_regen_timer = stamina_regen_delay
	emit_signal("stamina_changed", stamina, max_stamina)

# ─── Damage ────────────────────────────────────────────────────────────────
func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if invincible or state == State.DEAD:
		return

	var final_dmg := int(amount * (1.0 - damage_reduction))
	hp -= final_dmg
	hp = max(0, hp)
	emit_signal("hp_changed", hp, max_hp)

	if hp <= 0:
		_die()
		return

	velocity = knockback
	hurt_timer = hurt_duration
	invincible = true
	stamina_regen_timer = stamina_regen_delay
	_set_state(State.HURT)

func _die() -> void:
	_set_state(State.DEAD)
	invincible = true
	velocity = Vector2.ZERO
	GameManager.on_player_death(global_position, GameManager.souls)
	GameManager.souls = 0
	emit_signal("souls_changed", 0)
	emit_signal("player_died")
	# Brief delay then respawn
	await get_tree().create_timer(2.0).timeout
	GameManager.respawn()

# ─── Hit callbacks ─────────────────────────────────────────────────────────
func _on_attack_hit(body: Node) -> void:
	if body == self:
		return
	if body.has_method("take_damage"):
		var dmg := special_damage if state == State.SPECIAL else attack_damage
		var kb_dir := Vector2(facing, -0.3).normalized()
		var kb_strength := special_knockback if state == State.SPECIAL else 80.0
		body.take_damage(dmg, kb_dir * kb_strength)

func _on_attack_area(area: Area2D) -> void:
	var body := area.get_parent()
	if body.has_method("take_damage"):
		var dmg := special_damage if state == State.SPECIAL else attack_damage
		var kb_dir := Vector2(facing, -0.3).normalized()
		body.take_damage(dmg, kb_dir * 80.0)

# ─── Projectile / Fire wave ────────────────────────────────────────────────
func _spawn_fire_wave() -> void:
	var proj_scene := load("res://scenes/projectile.tscn") as PackedScene
	if not proj_scene:
		return
	for i in range(3):
		var p := proj_scene.instantiate()
		get_parent().add_child(p)
		p.global_position = global_position + Vector2(0, -8)
		p.setup(facing, special_damage, Color(1.0, 0.5, 0.1), Vector2(1.0 + i * 0.4, 0.0).rotated(deg_to_rad(randf_range(-10, 10))))

# ─── Assassin helpers ──────────────────────────────────────────────────────
func _find_nearest_enemy(range_check: float) -> Node2D:
	var best: Node2D = null
	var best_dist: float = range_check
	for body in get_tree().get_nodes_in_group("enemies"):
		var d := global_position.distance_to(body.global_position)
		if d < best_dist:
			best_dist = d
			best = body
	return best

# ─── Lost soul marker ──────────────────────────────────────────────────────
func _spawn_lost_soul_marker() -> void:
	lost_soul_marker = Node2D.new()
	get_parent().call_deferred("add_child", lost_soul_marker)
	lost_soul_marker.global_position = GameManager.lost_souls_position

# ─── State ─────────────────────────────────────────────────────────────────
func _set_state(new_state: State) -> void:
	state = new_state
	anim_frame = 0
	anim_timer = 0.0

# ─── Animation ─────────────────────────────────────────────────────────────
func _update_animation(delta: float) -> void:
	if state == State.RUN:
		anim_timer += delta
		if anim_timer >= walk_anim_speed:
			anim_timer = 0.0
			anim_frame = (anim_frame + 1) % 4

# ─── Drawing (pixel art) ───────────────────────────────────────────────────
func _draw() -> void:
	# Shadow
	_draw_ellipse(Vector2(0, 8), Vector2(7, 3), Color(0, 0, 0, 0.3))

	# Set facing transform (flip around x=0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))

	match player_class:
		0: _draw_knight()
		1: _draw_pyromancer()
		2: _draw_assassin()

	draw_set_transform(Vector2.ZERO)  # reset transform

	# Overlays (drawn without flip)
	if state == State.HURT:
		draw_rect(Rect2(-8, -16, 16, 20), Color(1, 1, 1, 0.35))
	if state == State.DEAD:
		draw_rect(Rect2(-8, -16, 16, 20), Color(0.4, 0, 0, 0.5))
	if state == State.DODGE:
		draw_rect(Rect2(-8, -16, 16, 20), Color(0.5, 0.8, 1.0, 0.22))

	# Lost-soul orb
	if GameManager.lost_souls > 0 and is_instance_valid(lost_soul_marker):
		var local_pos := to_local(lost_soul_marker.global_position)
		var pulse := 0.65 + sin(Time.get_ticks_msec() * 0.005) * 0.3
		draw_circle(local_pos, 3.0, Color(0.4, 0.8, 1.0, pulse))


# All drawing functions below assume facing RIGHT (x > 0 = forward)
# The draw_set_transform flip handles left-facing automatically.

func _draw_knight() -> void:
	var c1 := class_color1
	var c2 := class_color2
	# Legs (animated walk)
	var la := anim_frame % 4
	_px(-3, -4 + (2 if la == 1 else 0), 3, 6, c2)
	_px(0,  -4 + (2 if la == 3 else 0), 3, 6, c2)
	# Body armor
	_px(-3, -14, 6, 10, c1)
	# Shield (left/back)
	_px(-6, -13, 3, 9, Color(0.5, 0.3, 0.2))
	_px(-6, -12, 3, 7, Color(0.8, 0.6, 0.2))
	# Helmet
	_px(-3, -18, 6, 5, c1)
	_px(-2, -19, 4, 2, Color(0.9, 0.8, 0.3))
	# Sword (right/front)
	if state in [State.ATTACK, State.SPECIAL]:
		_px(4, -20, 2, 15, Color(0.85, 0.85, 0.9))
		_px(3, -21, 4, 3, Color(0.75, 0.62, 0.30))
	else:
		_px(4, -14, 2, 10, Color(0.75, 0.75, 0.85))

func _draw_pyromancer() -> void:
	var c1 := class_color1
	var c2 := class_color2
	_px(-3, -14, 6, 12, c1)    # robe
	_px(-3, -19, 6, 6,  c2)    # hood
	_px(-2, -21, 4, 3, Color(0, 0, 0, 0.8))  # dark inside hood
	_px(-5, -13, 2, 7,  c1)    # left arm
	_px(3,  -13, 2, 7,  c1)    # right arm
	var t := Time.get_ticks_msec() * 0.008
	var fire_r := 4.0 + sin(t) * 1.0
	if state in [State.ATTACK, State.SPECIAL]:
		draw_circle(Vector2(6, -8), fire_r + 2.5, Color(1.0, 0.55, 0.08, 0.9))
		draw_circle(Vector2(6, -8), fire_r, Color(1.0, 0.9, 0.5, 0.9))
	else:
		draw_circle(Vector2(6, -8), fire_r, Color(1.0, 0.5, 0.1, 0.7))

func _draw_assassin() -> void:
	var c1 := class_color1
	var c2 := class_color2
	var la := anim_frame % 4
	_px(-2, -4 + (2 if la == 1 else 0), 2, 6, c2)
	_px(0,  -4 + (2 if la == 3 else 0), 2, 6, c2)
	_px(-2, -14, 5, 10, c1)           # body
	_px(-5, -16, 2, 14, Color(c2.r * 0.7, c2.g * 0.7, c2.b * 0.7))  # back cloak
	_px(3,  -16, 2, 14, Color(c2.r * 0.7, c2.g * 0.7, c2.b * 0.7))  # front cloak
	_px(-2, -19, 5, 6, c1)            # head
	_px(-1, -20, 3, 2, Color(0.08, 0.08, 0.18))  # mask
	if state in [State.ATTACK, State.SPECIAL]:
		_px(4,  -17, 1, 8, Color(0.8, 0.8, 0.9))
		_px(-5, -15, 1, 6, Color(0.8, 0.8, 0.9))
	else:
		_px(4, -14, 1, 6, Color(0.7, 0.7, 0.8))

func _px(x: int, y: int, w: int, h: int, c: Color) -> void:
	draw_rect(Rect2(x, y, w, h), c)

func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(16):
		var a := TAU * i / 16.0
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	draw_polygon(pts, PackedColorArray([color]))
