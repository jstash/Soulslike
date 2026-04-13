extends Area2D

@export var checkpoint_id: int = 0
@export var heal_player: bool = true

var activated: bool = false
var player_nearby: bool = false
var interact_prompt: bool = false

signal activated_checkpoint

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Check if already activated this run
	if GameManager.last_checkpoint_id == checkpoint_id:
		activated = true

func _process(_delta: float) -> void:
	if player_nearby and Input.is_action_just_pressed("interact"):
		_activate()
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_nearby = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_nearby = false

func _activate() -> void:
	activated = true
	GameManager.set_checkpoint(global_position + Vector2(0, 20), get_tree().current_scene.scene_file_path, checkpoint_id)
	emit_signal("activated_checkpoint")

	if heal_player:
		var p := get_tree().get_first_node_in_group("player")
		if p:
			p.hp = p.max_hp
			p.stamina = p.max_stamina
			p.hp_changed.emit(p.hp, p.max_hp)
			p.stamina_changed.emit(p.stamina, p.max_stamina)
			p.flasks_changed.emit(GameManager.flask_uses, GameManager.max_flask_uses)

func _draw() -> void:
	var t := Time.get_ticks_msec() * 0.004
	var lit := activated or player_nearby

	# Base / altar
	draw_rect(Rect2(-8, 4, 16, 6), Color8(80, 60, 40))
	draw_rect(Rect2(-6, 2, 12, 4), Color8(100, 80, 55))
	draw_rect(Rect2(-4, 0, 8, 3), Color8(120, 90, 60))

	# Brazier bowl
	draw_rect(Rect2(-5, -3, 10, 4), Color8(70, 55, 35))
	draw_rect(Rect2(-4, -4, 8, 2), Color8(90, 70, 45))

	if lit:
		# Flame (animated)
		var flicker := sin(t * 5.0) * 2.0
		# Outer flame
		var flame_pts := PackedVector2Array([
			Vector2(-4, -4),
			Vector2(-5 + flicker * 0.3, -10),
			Vector2(-2, -14 - flicker),
			Vector2(0, -16 - flicker * 0.5),
			Vector2(2, -14 - flicker),
			Vector2(5 - flicker * 0.3, -10),
			Vector2(4, -4),
		])
		draw_polygon(flame_pts, PackedColorArray([Color(0.9, 0.5, 0.1, 0.8)]))
		# Inner flame
		var inner := PackedVector2Array([
			Vector2(-2, -4),
			Vector2(-2, -9),
			Vector2(0, -13 - flicker * 0.5),
			Vector2(2, -9),
			Vector2(2, -4),
		])
		draw_polygon(inner, PackedColorArray([Color(1.0, 0.9, 0.5, 0.9)]))
		# Glow
		draw_circle(Vector2(0, -8), 10.0 + flicker, Color(1.0, 0.7, 0.2, 0.15))
	else:
		# Unlit – ash pile
		draw_rect(Rect2(-3, -5, 6, 2), Color8(60, 55, 50))

	# Interact prompt
	if player_nearby and not activated:
		draw_rect(Rect2(-10, -22, 20, 8), Color(0, 0, 0, 0.6))
		# "E" key hint – just a white rect for now (no font in _draw)
		draw_rect(Rect2(-4, -20, 8, 5), Color(0.9, 0.8, 0.3, 0.9))
