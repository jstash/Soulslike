extends "res://scripts/enemy_base.gd"

# Skeleton – fast, fragile melee enemy summoned by the Necromancer

const BONE_COLOR  := Color8(220, 210, 185)
const JOINT_COLOR := Color8(180, 170, 145)
const EYE_COLOR   := Color(0.8, 0.1, 0.1)

func _on_ready_extra() -> void:
	max_hp       = 32
	hp           = max_hp
	move_speed   = 60.0
	attack_damage = 9
	attack_range  = 18.0
	attack_cd_max = 1.1
	souls_value   = 15
	aggro_range   = 110.0
	knockback_resist = 0.2

func _animate(delta: float) -> void:
	anim_timer += delta
	if anim_timer > 0.10:
		anim_timer = 0.0
		anim_frame = (anim_frame + 1) % 4

func _draw() -> void:
	if ai_state == AIState.DEAD:
		draw_rect(Rect2(-5, 2, 10, 3), BONE_COLOR)
		draw_rect(Rect2(-3, 4, 6, 2), JOINT_COLOR)
		return

	var flash := hurt_flash > 0.3
	var bc := Color.WHITE if flash else BONE_COLOR
	var jc := Color.WHITE if flash else JOINT_COLOR
	var la := anim_frame % 4
	var l1y := -4 + (2 if la == 1 else 0)
	var l2y := -4 + (2 if la == 3 else 0)
	var eye_c := Color(1, 0.5, 0) if (ai_state == AIState.ATTACK and not flash) else EYE_COLOR

	_draw_ellipse(Vector2(0, 8), Vector2(5, 2), Color(0, 0, 0, 0.25))

	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))
	draw_rect(Rect2(-2, l1y, 2, 6), bc)
	draw_rect(Rect2(0,  l2y, 2, 6), bc)
	draw_rect(Rect2(-2, l1y + 3, 2, 1), jc)
	draw_rect(Rect2(0,  l2y + 3, 2, 1), jc)
	draw_rect(Rect2(-2, -13, 5, 9), bc)
	for i in range(3):
		draw_rect(Rect2(-3, -12 + i * 3, 1, 2), jc)
		draw_rect(Rect2(3,  -12 + i * 3, 1, 2), jc)
	draw_rect(Rect2(-2, -19, 5, 7), bc)
	draw_rect(Rect2(-1, -17, 1, 2), eye_c)
	draw_rect(Rect2(2,  -17, 1, 2), eye_c)
	draw_rect(Rect2(-2, -13, 5, 1), jc)
	if ai_state == AIState.ATTACK:
		draw_rect(Rect2(3, -21, 1, 12), bc)
		draw_rect(Rect2(2, -21, 3, 2),  jc)
	else:
		draw_rect(Rect2(3, -16, 1, 8), bc)
	draw_set_transform(Vector2.ZERO)

	_draw_hp_bar()

func _draw_hp_bar() -> void:
	var bar_w := 14
	draw_rect(Rect2(-bar_w/2, -23, bar_w, 2), Color(0.05, 0, 0, 0.8))
	draw_rect(Rect2(-bar_w/2, -23, int(bar_w * float(hp) / float(max_hp)), 2), Color(0.9, 0.6, 0.1))

func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(12):
		var a := TAU * i / 12.0
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	draw_polygon(pts, PackedColorArray([color]))
