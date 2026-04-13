extends Node2D
# Animated background for main menu and class select

var scroll_x: float = 0.0

func _process(delta: float) -> void:
	scroll_x += delta * 8.0
	queue_redraw()

func _draw() -> void:
	var vp := get_viewport_rect().size
	var t := Time.get_ticks_msec() * 0.001

	# Sky gradient (dark, foreboding)
	draw_rect(Rect2(0, 0, vp.x, vp.y * 0.6), Color8(10, 5, 18))
	draw_rect(Rect2(0, vp.y * 0.35, vp.x, vp.y * 0.3), Color8(20, 8, 30))

	# Moon
	var moon_x := vp.x * 0.75
	var moon_y := vp.y * 0.18
	draw_circle(Vector2(moon_x, moon_y), 18.0, Color(0.7, 0.7, 0.6, 0.15))
	draw_circle(Vector2(moon_x, moon_y), 14.0, Color(0.85, 0.85, 0.75))
	draw_circle(Vector2(moon_x - 3, moon_y - 3), 12.0, Color8(10, 5, 18))  # crescent cut

	# Stars
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in range(40):
		var sx := rng.randf_range(0, vp.x)
		var sy := rng.randf_range(0, vp.y * 0.5)
		var brightness := 0.5 + sin(t * rng.randf_range(0.5, 2.0) + i) * 0.5
		draw_rect(Rect2(sx, sy, 1, 1), Color(1, 1, 1, brightness))

	# Distant silhouette (castle ruins)
	var castle_pts := PackedVector2Array([
		Vector2(0, vp.y * 0.55),
		Vector2(vp.x * 0.05, vp.y * 0.55),
		Vector2(vp.x * 0.05, vp.y * 0.4),
		Vector2(vp.x * 0.07, vp.y * 0.4),
		Vector2(vp.x * 0.07, vp.y * 0.35),
		Vector2(vp.x * 0.09, vp.y * 0.35),
		Vector2(vp.x * 0.09, vp.y * 0.4),
		Vector2(vp.x * 0.12, vp.y * 0.4),
		Vector2(vp.x * 0.12, vp.y * 0.32),
		Vector2(vp.x * 0.14, vp.y * 0.32),
		Vector2(vp.x * 0.14, vp.y * 0.4),
		Vector2(vp.x * 0.18, vp.y * 0.4),
		Vector2(vp.x * 0.18, vp.y * 0.55),
		Vector2(vp.x * 0.35, vp.y * 0.55),
		Vector2(vp.x * 0.35, vp.y * 0.38),
		Vector2(vp.x * 0.42, vp.y * 0.38),
		Vector2(vp.x * 0.42, vp.y * 0.55),
		Vector2(vp.x, vp.y * 0.55),
		Vector2(vp.x, vp.y),
		Vector2(0, vp.y),
	])
	draw_polygon(castle_pts, PackedColorArray([Color8(15, 10, 25)]))

	# Ground
	draw_rect(Rect2(0, vp.y * 0.55, vp.x, vp.y * 0.45), Color8(18, 12, 28))

	# Scrolling gravestones
	for i in range(8):
		var gx := fmod(i * 42.0 + scroll_x * 0.3, vp.x + 20.0) - 10.0
		var gy := vp.y * 0.56
		draw_rect(Rect2(gx - 4, gy, 8, 12), Color8(30, 22, 40))
		draw_rect(Rect2(gx - 3, gy - 5, 6, 6), Color8(30, 22, 40))
		draw_rect(Rect2(gx - 5, gy + 1, 10, 2), Color8(25, 18, 35))

	# Candle flickering
	for i in range(5):
		var cx := vp.x * (0.1 + i * 0.2)
		var cy := vp.y * 0.54
		var flicker := sin(t * (3.0 + i * 0.7) + i * 1.3) * 1.5
		draw_rect(Rect2(cx - 1, cy - 6, 2, 6), Color8(160, 130, 80))
		draw_circle(Vector2(cx, cy - 7 - flicker), 2.5 + flicker * 0.3, Color(1.0, 0.8, 0.3, 0.8))
		draw_circle(Vector2(cx, cy - 7 - flicker), 6.0, Color(1.0, 0.7, 0.2, 0.12))
