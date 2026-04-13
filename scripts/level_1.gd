extends Node2D

@onready var hud: CanvasLayer       = $HUD
@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var boss_trigger: Area2D   = $BossArena/BossTrigger
@onready var high_priest: CharacterBody2D = $BossArena/HighPriest
@onready var boss_door: StaticBody2D      = $BossArena/BossDoor
@onready var cam: Camera2D                = $Camera2D
@onready var world_draw: Node2D           = $WorldDraw

var player: CharacterBody2D = null
var boss_active: bool = false
var boss_fight_started: bool = false

const PLAYER_SCENE := preload("res://scenes/player.tscn")

func _ready() -> void:
	# Spawn player
	player = PLAYER_SCENE.instantiate()
	add_child(player)
	player.add_to_group("player")
	player.global_position = GameManager.last_checkpoint_pos

	# Attach camera to player
	cam.reparent(player)
	cam.position = Vector2.ZERO

	# Connect HUD signals
	player.hp_changed.connect(hud.on_hp_changed)
	player.stamina_changed.connect(hud.on_stamina_changed)
	player.souls_changed.connect(hud.on_souls_changed)
	player.flasks_changed.connect(hud.on_flasks_changed)
	player.player_died.connect(hud.on_player_died)

	# Boss setup
	boss_door.visible = false
	if boss_trigger:
		boss_trigger.body_entered.connect(_on_boss_trigger)
	if high_priest:
		high_priest.phase_changed.connect(_on_boss_phase_changed)
		high_priest.boss_died.connect(_on_boss_died)

	hud.show_message("THE ASHEN COVENANT", 3.0)

func _process(_delta: float) -> void:
	if boss_active and is_instance_valid(high_priest):
		hud.update_boss_hp(high_priest.hp, high_priest.max_hp)
	elif boss_active:
		hud.hide_boss()
		boss_active = false

func _on_boss_trigger(body: Node) -> void:
	if body.is_in_group("player") and not boss_fight_started:
		boss_fight_started = true
		boss_active = true
		hud.show_boss("HIGH PRIEST MALACHAR")
		boss_door.visible = true

func _on_boss_phase_changed(phase: int) -> void:
	if phase == 2:
		hud.show_message("PHASE II", 3.0)

func _on_boss_died() -> void:
	boss_active = false
	hud.hide_boss()
	boss_door.visible = false
	hud.show_message("ENEMY FELLED", 4.0)
	await get_tree().create_timer(3.0).timeout
	hud.show_message("VICTORY\nThe cult is broken.", 5.0)
