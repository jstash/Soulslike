extends CharacterBody2D

signal died(pos: Vector2, souls_value: int)

# ─── Stats ──────────────────────────────────────────────────────────────────
var max_hp: int = 60
var hp: int = 60
var move_speed: float = 45.0
var attack_damage: int = 12
var attack_range: float = 20.0
var souls_value: int = 20
var aggro_range: float = 80.0
var deaggro_range: float = 130.0
var knockback_resist: float = 0.5

# ─── AI state ───────────────────────────────────────────────────────────────
enum AIState { PATROL, CHASE, ATTACK, STAGGER, DEAD }
var ai_state: AIState = AIState.PATROL

var player: Node2D = null
var patrol_origin: Vector2 = Vector2.ZERO
var patrol_dir: int = 1
var patrol_timer: float = 0.0
const PATROL_DIST: float = 40.0
const PATROL_WAIT: float = 1.5

var attack_cd: float = 0.0
var attack_cd_max: float = 1.8
var attack_timer: float = 0.0
var attack_duration: float = 0.40
var is_attacking: bool = false

var stagger_timer: float = 0.0

# ─── Hurt flash ─────────────────────────────────────────────────────────────
var hurt_flash: float = 0.0

# ─── Facing ─────────────────────────────────────────────────────────────────
var facing: int = 1

# ─── Physics ────────────────────────────────────────────────────────────────
const GRAVITY: float = 900.0

# ─── Animation ──────────────────────────────────────────────────────────────
var anim_timer: float = 0.0
var anim_frame: int = 0

# ─── Nodes ──────────────────────────────────────────────────────────────────
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/Shape

func _ready() -> void:
	add_to_group("enemies")
	patrol_origin = global_position
	attack_shape.disabled = true
	attack_area.body_entered.connect(_on_attack_hit)
	_on_ready_extra()

func _on_ready_extra() -> void:
	pass

func _physics_process(delta: float) -> void:
	if ai_state == AIState.DEAD:
		return

	_handle_gravity(delta)
	_update_ai(delta)
	move_and_slide()
	_animate(delta)
	hurt_flash = max(0.0, hurt_flash - delta * 4.0)
	attack_cd = max(0.0, attack_cd - delta)
	queue_redraw()

func _handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		velocity.y = min(velocity.y, 600.0)
	else:
		if velocity.y > 0.0:
			velocity.y = 0.0

func _update_ai(delta: float) -> void:
	# Find player
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
			if dist < attack_range:
				_start_attack()
			else:
				_chase_player()

		AIState.ATTACK:
			attack_timer -= delta
			velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
			if attack_timer <= 0.0:
				is_attacking = false
				attack_shape.disabled = true
				ai_state = AIState.CHASE

		AIState.STAGGER:
			stagger_timer -= delta
			velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
			if stagger_timer <= 0.0:
				ai_state = AIState.CHASE

func _do_patrol(delta: float) -> void:
	if patrol_timer > 0.0:
		patrol_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
		return

	velocity.x = patrol_dir * move_speed * 0.6
	facing = patrol_dir

	var dist_from_origin := global_position.x - patrol_origin.x
	if abs(dist_from_origin) > PATROL_DIST:
		patrol_dir *= -1
		patrol_timer = PATROL_WAIT

func _chase_player() -> void:
	if not player:
		return
	var dir := signf(player.global_position.x - global_position.x)
	velocity.x = dir * move_speed
	facing = int(dir)

func _start_attack() -> void:
	if attack_cd > 0.0:
		return
	ai_state = AIState.ATTACK
	attack_timer = attack_duration
	attack_cd = attack_cd_max
	is_attacking = true
	velocity.x = 0.0

	# Enable hitbox
	attack_shape.shape.size = Vector2(attack_range, 14.0)
	attack_area.position = Vector2(facing * attack_range * 0.5, -4.0)
	attack_shape.disabled = false

	# Subclasses can override for special attacks
	_on_attack_started()

func _on_attack_started() -> void:
	pass

func _on_attack_hit(body: Node) -> void:
	if not is_attacking:
		return
	if body.has_method("take_damage"):
		var kb := Vector2(facing * 90.0, -80.0)
		body.take_damage(attack_damage, kb)
	attack_shape.disabled = true
	is_attacking = false

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if ai_state == AIState.DEAD:
		return

	hp -= amount
	hurt_flash = 1.0

	velocity += knockback * knockback_resist

	if hp <= 0:
		_die()
		return

	stagger_timer = 0.30
	ai_state = AIState.STAGGER

func _die() -> void:
	ai_state = AIState.DEAD
	attack_shape.disabled = true
	velocity = Vector2.ZERO
	remove_from_group("enemies")
	GameManager.add_souls(souls_value)
	emit_signal("died", global_position, souls_value)
	_on_death_extra()
	queue_redraw()
	await get_tree().create_timer(0.8).timeout
	queue_free()

func _on_death_extra() -> void:
	pass

func _animate(_delta: float) -> void:
	pass

func _draw() -> void:
	pass
