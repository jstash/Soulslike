extends Area2D

var damage: int = 15
var speed: float = 140.0
var direction: Vector2 = Vector2.RIGHT
var proj_color: Color = Color(1.0, 0.5, 0.1)
var is_enemy_proj: bool = false
var lifetime: float = 3.0
var hit_player: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

# Called for player projectiles (Pyromancer attack/special)
func setup(facing_dir: int, dmg: int, color: Color, vel_override: Vector2 = Vector2.ZERO) -> void:
	damage = dmg
	proj_color = color
	is_enemy_proj = false
	direction = vel_override if vel_override != Vector2.ZERO else Vector2(facing_dir, 0.0)
	direction = direction.normalized()

# Called for enemy projectiles
func setup_enemy_bolt(dmg: int, color: Color, dir: Vector2) -> void:
	damage = dmg
	proj_color = color
	is_enemy_proj = true
	direction = dir.normalized()
	speed = 100.0

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if is_enemy_proj:
		if body.has_method("take_damage") and body.is_in_group("player"):
			body.take_damage(damage, direction * 100.0)
			queue_free()
	else:
		if body.has_method("take_damage") and body.is_in_group("enemies"):
			body.take_damage(damage, direction * 80.0)
			queue_free()
		elif body is StaticBody2D:
			queue_free()

func _on_area_entered(area: Area2D) -> void:
	pass

func _draw() -> void:
	var size := Vector2(5.0, 4.0)
	# Core
	draw_rect(Rect2(-size.x * 0.5, -size.y * 0.5, size.x, size.y), proj_color)
	# Inner bright
	draw_rect(Rect2(-2, -1.5, 3, 3), Color(1, 1, 1, 0.6))
	# Trail
	var t := Time.get_ticks_msec() * 0.01
	for i in range(3):
		var trail_pos := -direction * (i + 1) * 4.0
		draw_circle(trail_pos, 1.5 - i * 0.4, Color(proj_color.r, proj_color.g, proj_color.b, 0.4 - i * 0.12))
