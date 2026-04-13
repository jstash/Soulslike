extends CanvasLayer

@onready var hp_bar: ProgressBar         = $Bars/HPBar
@onready var stamina_bar: ProgressBar    = $Bars/StaminaBar
@onready var souls_label: Label          = $SoulsPanel/SoulsLabel
@onready var flask_label: Label          = $FlaskPanel/FlaskLabel
@onready var class_label: Label          = $Bars/ClassLabel
@onready var boss_panel: Control         = $BossPanel
@onready var boss_bar: ProgressBar       = $BossPanel/BossBar
@onready var boss_name_label: Label      = $BossPanel/BossName
@onready var death_overlay: Control      = $DeathOverlay
@onready var message_label: Label        = $MessageLabel

var message_timer: float = 0.0

func _ready() -> void:
	var d := GameManager.get_class_data()
	class_label.text = d.name.to_upper()
	hp_bar.max_value = 1.0
	hp_bar.value = 1.0
	stamina_bar.max_value = 1.0
	stamina_bar.value = 1.0
	souls_label.text = "SOULS  %d" % GameManager.souls
	flask_label.text = "FLASK  %d" % GameManager.flask_uses
	boss_panel.visible = false
	death_overlay.visible = false
	message_label.modulate.a = 0.0

func _process(delta: float) -> void:
	if message_timer > 0.0:
		message_timer -= delta
		if message_timer <= 0.0:
			message_label.modulate.a = 0.0
		else:
			message_label.modulate.a = min(1.0, message_timer * 2.0)

# ─── Player signal handlers ─────────────────────────────────────────────
func on_hp_changed(hp: int, max_hp: int) -> void:
	hp_bar.value = float(hp) / float(max_hp)

func on_stamina_changed(stamina: float, max_stamina: float) -> void:
	stamina_bar.value = stamina / max_stamina

func on_souls_changed(souls: int) -> void:
	souls_label.text = "SOULS  %d" % souls

func on_flasks_changed(flasks: int, _max_flasks: int) -> void:
	flask_label.text = "FLASK  %d" % flasks

func on_player_died() -> void:
	death_overlay.visible = true
	show_message("YOU DIED")

# ─── Boss ───────────────────────────────────────────────────────────────
func show_boss(boss_name: String) -> void:
	boss_panel.visible = true
	boss_name_label.text = boss_name.to_upper()
	boss_bar.value = 1.0

func update_boss_hp(hp: int, max_hp: int) -> void:
	boss_bar.value = float(hp) / float(max_hp)

func hide_boss() -> void:
	boss_panel.visible = false

# ─── Messages ───────────────────────────────────────────────────────────
func show_message(text: String, duration: float = 3.0) -> void:
	message_label.text = text
	message_label.modulate.a = 1.0
	message_timer = duration
