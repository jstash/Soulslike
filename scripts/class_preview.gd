extends Node2D
# Draws an animated preview of the selected class in the class-select screen

var anim_timer: float = 0.0
var anim_frame: int = 0

func _process(delta: float) -> void:
	anim_timer += delta
	if anim_timer > 0.15:
		anim_timer = 0.0
		anim_frame = (anim_frame + 1) % 4
	queue_redraw()

func _draw() -> void:
	var sel := GameManager.chosen_class
	var d: Dictionary = GameManager.CLASS_DATA[sel]
	var c1: Color = d.color1
	var c2: Color = d.color2
	var t := Time.get_ticks_msec() * 0.005

	match sel:
		0: _draw_knight(c1, c2, t)
		1: _draw_pyromancer(c1, c2, t)
		2: _draw_assassin(c1, c2, t)

func _draw_knight(c1: Color, c2: Color, t: float) -> void:
	# Shadow
	_draw_ellipse(Vector2(0, 24), Vector2(14, 5), Color(0, 0, 0, 0.3))
	# Legs
	var bob := sin(t * 3.0) * 1.0
	_px(-8, 10 + bob, 7, 14, c2)
	_px(1,  10 - bob, 7, 14, c2)
	# Body / armor
	_px(-8, -8, 16, 20, c1)
	# Pauldrons
	_px(-11, -8, 4, 6, c2)
	_px(7, -8, 4, 6, c2)
	# Shield
	_px(-14, -6, 6, 18, Color8(100, 70, 30))
	_px(-13, -5, 4, 16, Color8(180, 140, 50))
	_px(-11, -1, 2, 8, Color(1, 0.9, 0.3))  # boss
	# Sword (raised slightly)
	var sword_bob := sin(t * 2.0) * 2.0
	_px(8, -20 + sword_bob, 4, 22, c2)
	_px(5, -21 + sword_bob, 10, 5, Color8(180, 140, 50))
	# Helmet
	_px(-8, -22, 16, 15, c1)
	_px(-6, -24, 12, 4, c2)
	_px(-5, -18, 10, 3, Color(0.9, 0.8, 0.3))   # visor
	# Eye slit glow
	draw_rect(Rect2(-4, -19, 8, 1), Color(0.9, 0.85, 0.4, 0.7))

func _draw_pyromancer(c1: Color, c2: Color, t: float) -> void:
	_draw_ellipse(Vector2(0, 24), Vector2(12, 4), Color(0, 0, 0, 0.3))
	# Robe
	_px(-8, -4, 16, 30, c1)
	_px(-10, 4, 20, 10, c1)
	# Arms
	_px(-13, -6, 5, 16, c1)
	_px(8, -6, 5, 16, c1)
	# Hood
	_px(-7, -22, 14, 20, c2)
	_px(-5, -24, 10, 5, c2)
	_px(-3, -26, 6, 4, c2)
	# Dark face under hood
	_px(-5, -20, 10, 14, Color8(15, 10, 20))
	# Glowing eyes
	draw_rect(Rect2(-3, -17, 2, 3), Color(1.0, 0.4, 0.1, 0.9))
	draw_rect(Rect2(1, -17, 2, 3), Color(1.0, 0.4, 0.1, 0.9))
	# Fire orb (left hand)
	var orb_r := 7.0 + sin(t * 4.0) * 2.0
	draw_circle(Vector2(-18, 4), orb_r, Color(1.0, 0.5, 0.1, 0.8))
	draw_circle(Vector2(-18, 4), orb_r * 0.6, Color(1.0, 0.9, 0.5, 0.9))
	# Flame particles
	for i in range(5):
		var a := t * 2.0 + i * TAU / 5.0
		var r := orb_r + 3.0
		draw_circle(Vector2(-18 + cos(a) * r, 4 + sin(a) * r * 0.5), 1.5, Color(1.0, 0.3, 0.0, 0.5))

func _draw_assassin(c1: Color, c2: Color, t: float) -> void:
	_draw_ellipse(Vector2(0, 24), Vector2(10, 4), Color(0, 0, 0, 0.3))
	# Legs
	var run := sin(t * 4.0) * 3.0
	_px(-6, 10 + run, 5, 14, c2)
	_px(1, 10 - run, 5, 14, c2)
	# Body
	_px(-5, -8, 10, 20, c1)
	# Cloak
	_px(-10, -10, 4, 24, Color(c2.r * 0.7, c2.g * 0.7, c2.b * 0.7, 0.8))
	_px(6,  -10, 4, 24, Color(c2.r * 0.7, c2.g * 0.7, c2.b * 0.7, 0.8))
	# Head / mask
	_px(-5, -22, 10, 15, c1)
	_px(-4, -23, 8, 3, c2)
	_px(-3, -19, 6, 3, Color8(10, 10, 20))    # mask
	# Eyes
	draw_rect(Rect2(-2, -18, 1, 2), Color(0.6, 0.8, 1.0, 0.9))
	draw_rect(Rect2(1, -18, 1, 2), Color(0.6, 0.8, 1.0, 0.9))
	# Daggers
	var dagger_bob := sin(t * 3.0) * 1.0
	_px(8, -12 + dagger_bob, 2, 14, Color8(200, 200, 215))
	_px(-10, -10 - dagger_bob, 2, 12, Color8(200, 200, 215))

func _px(x: int, y: int, w: int, h: int, c: Color) -> void:
	draw_rect(Rect2(x, y, w, h), c)

func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(16):
		var a := TAU * i / 16.0
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	draw_polygon(pts, PackedColorArray([color]))
