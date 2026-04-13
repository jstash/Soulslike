extends Node2D
# Draws the visual representation of the level world

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	_draw_background()
	_draw_terrain()
	_draw_boss_arena()
	_draw_decorations()

func _draw_background() -> void:
	# Sky
	draw_rect(Rect2(-50, -200, 1100, 500), Color8(12, 8, 20))

	# Moon
	draw_circle(Vector2(900, -60), 20.0, Color(0.75, 0.75, 0.65, 0.2))
	draw_circle(Vector2(900, -60), 16.0, Color(0.82, 0.82, 0.72))
	draw_circle(Vector2(896, -63), 14.0, Color8(12, 8, 20))  # crescent

	# Stars (static seed)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	for i in range(60):
		var sx := rng.randf_range(-50, 1050)
		var sy := rng.randf_range(-200, 200)
		var t := Time.get_ticks_msec() * 0.001
		var bri := 0.4 + sin(t * rng.randf_range(0.3, 1.5) + i) * 0.4
		draw_rect(Rect2(sx, sy, 1, 1), Color(1, 1, 1, bri))

	# Distant ruin silhouettes
	_draw_ruins()

func _draw_ruins() -> void:
	var ruin_pts := PackedVector2Array([
		Vector2(-50, 285), Vector2(-50, 240), Vector2(20, 240), Vector2(20, 220),
		Vector2(30, 220), Vector2(30, 210), Vector2(40, 210), Vector2(40, 220),
		Vector2(60, 220), Vector2(60, 200), Vector2(70, 200), Vector2(70, 220),
		Vector2(90, 220), Vector2(90, 205), Vector2(95, 205), Vector2(95, 220),
		Vector2(120, 220), Vector2(120, 240), Vector2(160, 240), Vector2(160, 285),
	])
	draw_polygon(ruin_pts, PackedColorArray([Color8(18, 12, 28)]))

func _draw_terrain() -> void:
	# Main floor (stone tiles effect)
	var floor_y := 284.0
	var floor_h := 30.0
	var floor_w := 600.0

	# Base stone
	draw_rect(Rect2(0, floor_y, floor_w, floor_h), Color8(45, 38, 52))

	# Stone tile lines (horizontal)
	for y in range(0, 3):
		draw_line(Vector2(0, floor_y + y * 10), Vector2(floor_w, floor_y + y * 10), Color8(30, 25, 38), 1.0)
	# Stone tile lines (vertical, staggered)
	for x in range(0, 61):
		var tile_x := x * 10.0
		var offset_y := (10.0 if (x % 2 == 0) else 0.0)
		draw_line(Vector2(tile_x, floor_y + offset_y), Vector2(tile_x, floor_y + 20), Color8(30, 25, 38), 1.0)

	# Top edge highlight
	draw_line(Vector2(0, floor_y), Vector2(floor_w, floor_y), Color8(80, 70, 90), 1.0)
	draw_line(Vector2(0, floor_y + 1), Vector2(floor_w, floor_y + 1), Color8(60, 52, 70), 1.0)

	# Platforms (floating stone blocks)
	_draw_platform(110, 251, 60)   # Platform 1
	_draw_platform(215, 226, 50)   # Platform 2
	_draw_platform(320, 211, 40)   # Platform 3
	_draw_platform(410, 246, 60)   # Platform 4
	_draw_platform(505, 226, 50)   # Platform 5

	# Walls
	_draw_wall(-4, 170, 8, 120)
	_draw_wall(596, 170, 8, 120)

func _draw_platform(x: float, y: float, w: float) -> void:
	draw_rect(Rect2(x, y, w, 8), Color8(50, 42, 58))
	draw_line(Vector2(x, y), Vector2(x + w, y), Color8(85, 75, 95), 1.0)
	draw_line(Vector2(x, y + 1), Vector2(x + w, y + 1), Color8(65, 58, 75), 1.0)
	# Bottom shadow
	draw_rect(Rect2(x, y + 7, w, 3), Color8(28, 22, 35))
	# Tile joints on platform
	for i in range(1, int(w / 10)):
		draw_line(Vector2(x + i * 10, y), Vector2(x + i * 10, y + 8), Color8(35, 28, 42), 1.0)

func _draw_wall(x: float, y: float, w: float, h: float) -> void:
	draw_rect(Rect2(x, y, w, h), Color8(40, 32, 48))
	for i in range(0, int(h / 12) + 1):
		draw_line(Vector2(x, y + i * 12), Vector2(x + w, y + i * 12), Color8(28, 22, 36), 1.0)

func _draw_boss_arena() -> void:
	# Boss arena floor
	var bx := 620.0
	var by := 284.0
	draw_rect(Rect2(bx, by, 380, 30), Color8(38, 20, 30))

	# Tile pattern (ritual stones – darker, more ornate)
	for x in range(0, 38):
		var tx := bx + x * 10.0
		var odd := x % 2 == 0
		for y in range(0, 3):
			var ty := by + y * 10.0
			draw_line(Vector2(tx, by + (10.0 if odd else 0.0)), Vector2(tx, by + 20), Color8(25, 12, 20), 1.0)
		draw_line(Vector2(bx, by + x * 0.8), Vector2(bx + 380, by + x * 0.8), Color8(25, 12, 20), 1.0)

	draw_line(Vector2(bx, by), Vector2(bx + 380, by), Color8(80, 40, 60), 1.0)
	draw_line(Vector2(bx, by + 1), Vector2(bx + 380, by + 1), Color8(60, 28, 45), 1.0)

	# Ritual circle on the floor
	var cx := bx + 185.0
	var cy := by + 2.0
	_draw_ritual_circle(cx, cy)

	# Boss right wall
	_draw_wall(992, 160, 8, 130)

func _draw_ritual_circle(cx: float, cy: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	# Outer ring
	var pts_outer := PackedVector2Array()
	for i in range(32):
		var a := TAU * i / 32.0
		pts_outer.append(Vector2(cx + cos(a) * 55.0, cy + sin(a) * 10.0))
	draw_polyline(pts_outer + PackedVector2Array([pts_outer[0]]), Color(0.5, 0.1, 0.6, 0.4 + sin(t) * 0.15), 1.0)

	# Inner ring
	var pts_inner := PackedVector2Array()
	for i in range(32):
		var a := TAU * i / 32.0
		pts_inner.append(Vector2(cx + cos(a) * 35.0, cy + sin(a) * 6.5))
	draw_polyline(pts_inner + PackedVector2Array([pts_inner[0]]), Color(0.6, 0.1, 0.7, 0.35 + sin(t * 1.3) * 0.15), 1.0)

	# Pentagram lines
	for i in range(5):
		var a1 := TAU * i / 5.0 - PI / 2.0
		var a2 := TAU * ((i + 2) % 5) / 5.0 - PI / 2.0
		draw_line(
			Vector2(cx + cos(a1) * 35.0, cy + sin(a1) * 6.5),
			Vector2(cx + cos(a2) * 35.0, cy + sin(a2) * 6.5),
			Color(0.55, 0.05, 0.65, 0.3), 1.0
		)

func _draw_decorations() -> void:
	# Torches on walls
	_draw_torch(30, 245)
	_draw_torch(565, 245)
	_draw_torch(640, 245)
	_draw_torch(980, 245)

	# Skulls / bones scattered
	_draw_skull(195, 281)
	_draw_skull(320, 281)
	_draw_skull(490, 281)
	_draw_skull(720, 281)
	_draw_skull(860, 281)

	# Gravestones
	_draw_gravestone(100, 285)
	_draw_gravestone(455, 285)
	_draw_gravestone(580, 285)

func _draw_torch(x: float, y: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	draw_rect(Rect2(x - 1, y, 2, 10), Color8(120, 90, 50))
	var flicker := sin(t * 5.0 + x) * 1.5
	draw_circle(Vector2(x, y - 1 - flicker), 3.5 + flicker * 0.3, Color(1.0, 0.7, 0.2, 0.8))
	draw_circle(Vector2(x, y - 1 - flicker), 7.0, Color(1.0, 0.6, 0.1, 0.12))

func _draw_skull(x: float, y: float) -> void:
	draw_rect(Rect2(x, y - 3, 5, 4), Color8(200, 190, 165))
	draw_rect(Rect2(x + 1, y - 2, 1, 1), Color8(20, 15, 25))
	draw_rect(Rect2(x + 3, y - 2, 1, 1), Color8(20, 15, 25))

func _draw_gravestone(x: float, y: float) -> void:
	draw_rect(Rect2(x - 4, y - 12, 8, 12), Color8(55, 45, 65))
	draw_rect(Rect2(x - 3, y - 17, 6, 6), Color8(55, 45, 65))
	draw_rect(Rect2(x - 2, y - 6, 4, 1), Color8(40, 33, 50))
	draw_rect(Rect2(x - 7, y - 1, 14, 2), Color8(40, 33, 50))
