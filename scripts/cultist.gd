extends "res://scripts/enemy_base.gd"

# Cultist – basic melee enemy with a ritual blade

const ROBE_COLOR   := Color8(80, 20, 20)
const HOOD_COLOR   := Color8(50, 10, 10)
const BLADE_COLOR  := Color8(120, 200, 180)
const SKIN_COLOR   := Color8(200, 170, 130)

func _on_ready_extra() -> void:
	max_hp      = 55
	hp          = max_hp
	move_speed  = 42.0
	attack_damage = 12
	attack_range  = 22.0
	attack_cd_max = 1.6
	souls_value   = 25
	aggro_range   = 85.0

func _animate(delta: float) -> void:
	anim_timer += delta
	if anim_timer > 0.14:
		anim_timer = 0.0
		anim_frame = (anim_frame + 1) % 4

func _draw() -> void:
	if ai_state == AIState.DEAD:
		draw_rect(Rect2(-8, 2, 16, 5), ROBE_COLOR)
		return

	var flash := hurt_flash > 0.3
	_draw_ellipse(Vector2(0, 8), Vector2(6, 2.5), Color(0, 0, 0, 0.3))

	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))
	var robe_c := Color.WHITE if flash else ROBE_COLOR
	var hood_c := Color.WHITE if flash else HOOD_COLOR
	draw_rect(Rect2(-3, -14, 6, 12), robe_c)
	draw_rect(Rect2(-3, -20, 6, 7), hood_c)
	draw_rect(Rect2(-1, -17, 1, 1), Color(1.0, 0.2, 0.2))
	draw_rect(Rect2(1,  -17, 1, 1), Color(1.0, 0.2, 0.2))
	if ai_state == AIState.ATTACK:
		draw_rect(Rect2(4, -20, 2, 14), Color.WHITE if flash else BLADE_COLOR)
		draw_rect(Rect2(3, -21, 4, 3), Color8(180, 150, 80))
	else:
		draw_rect(Rect2(4, -15, 2, 9), Color.WHITE if flash else BLADE_COLOR)
	draw_set_transform(Vector2.ZERO)

	_draw_hp_bar()

func _draw_hp_bar() -> void:
	var bar_w := 16
	var bx := -bar_w / 2
	var by := -23
	draw_rect(Rect2(bx, by, bar_w, 2), Color(0.1, 0.0, 0.0, 0.8))
	var fill_w := int(bar_w * float(hp) / float(max_hp))
	draw_rect(Rect2(bx, by, fill_w, 2), Color(0.8, 0.1, 0.1))

func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(12):
		var a := TAU * i / 12.0
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	draw_polygon(pts, PackedColorArray([color]))
