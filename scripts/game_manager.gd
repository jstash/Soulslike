extends Node

# Player class selection
var chosen_class: int = 0  # 0=Knight, 1=Pyromancer, 2=Assassin

# Persistent state
var souls: int = 0
var lost_souls: int = 0
var lost_souls_position: Vector2 = Vector2.ZERO
var last_checkpoint_scene: String = "res://scenes/level_1.tscn"
var last_checkpoint_pos: Vector2 = Vector2(80, 300)
var flask_uses: int = 3
var max_flask_uses: int = 3
var checkpoint_id: int = 0  # which checkpoint was last activated
var last_checkpoint_id: int = 0

const CLASS_DATA = {
	0: {
		"name": "Knight",
		"max_hp": 150,
		"max_stamina": 120.0,
		"speed": 82.0,
		"jump_force": -310.0,
		"damage_reduction": 0.30,
		"attack_damage": 22,
		"attack_range": 32.0,
		"attack_cost": 20.0,
		"dodge_cost": 28.0,
		"special_name": "Shield Bash",
		"special_damage": 35,
		"special_cost": 40.0,
		"special_range": 28.0,
		"special_knockback": 120.0,
		"description": "Stalwart guardian with sword and shield.\nHigh defense, powerful strikes.\n\nSpecial [X]: Shield Bash\nA stunning blow that staggers foes.\n\nDodge [C]   Flask [Q]",
		"color1": Color8(160, 160, 185),
		"color2": Color8(205, 205, 225),
	},
	1: {
		"name": "Pyromancer",
		"max_hp": 100,
		"max_stamina": 100.0,
		"speed": 95.0,
		"jump_force": -310.0,
		"damage_reduction": 0.10,
		"attack_damage": 20,
		"attack_range": 90.0,
		"attack_cost": 15.0,
		"dodge_cost": 22.0,
		"special_name": "Fire Wave",
		"special_damage": 50,
		"special_cost": 55.0,
		"special_range": 110.0,
		"special_knockback": 60.0,
		"description": "Master of dark flame and sorcery.\nRanged fire bolts scorch enemies.\n\nSpecial [X]: Fire Wave\nA sweeping wave of flame hits all\nenemies ahead.\n\nDodge [C]   Flask [Q]",
		"color1": Color8(200, 75, 20),
		"color2": Color8(240, 135, 45),
	},
	2: {
		"name": "Assassin",
		"max_hp": 80,
		"max_stamina": 150.0,
		"speed": 135.0,
		"jump_force": -330.0,
		"damage_reduction": 0.0,
		"attack_damage": 16,
		"attack_range": 26.0,
		"attack_cost": 10.0,
		"dodge_cost": 14.0,
		"special_name": "Shadow Strike",
		"special_damage": 65,
		"special_cost": 38.0,
		"special_range": 70.0,
		"special_knockback": 40.0,
		"description": "Swift shadow that strikes from darkness.\nFast attacks, deadly precision.\n\nSpecial [X]: Shadow Strike\nTeleport to nearest enemy and\ndeliver a devastating backstab.\n\nDodge [C]   Flask [Q]",
		"color1": Color8(50, 50, 80),
		"color2": Color8(85, 85, 115),
	}
}

func get_class_data() -> Dictionary:
	return CLASS_DATA[chosen_class]

func add_souls(amount: int):
	souls += amount

func try_recover_lost_souls(player_pos: Vector2) -> bool:
	if lost_souls > 0 and player_pos.distance_to(lost_souls_position) < 24.0:
		souls += lost_souls
		lost_souls = 0
		lost_souls_position = Vector2.ZERO
		return true
	return false

func on_player_death(player_pos: Vector2, carried_souls: int):
	lost_souls += carried_souls
	lost_souls_position = player_pos

func set_checkpoint(pos: Vector2, scene_path: String, id: int):
	last_checkpoint_pos = pos
	last_checkpoint_scene = scene_path
	last_checkpoint_id = id
	flask_uses = max_flask_uses

func respawn():
	flask_uses = max_flask_uses
	get_tree().change_scene_to_file(last_checkpoint_scene)
