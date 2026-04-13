extends Control

var selected: int = 0
var previews: Array = []

@onready var name_label: Label       = $PanelCenter/VBox/ClassName
@onready var desc_label: Label       = $PanelCenter/VBox/Desc
@onready var left_btn: Button        = $PanelCenter/VBox/Nav/LeftBtn
@onready var right_btn: Button       = $PanelCenter/VBox/Nav/RightBtn
@onready var confirm_btn: Button     = $PanelCenter/VBox/ConfirmBtn
@onready var preview_node: Node2D    = $PanelCenter/VBox/PreviewArea/SubViewport/PreviewNode
@onready var stats_label: Label      = $PanelCenter/VBox/Stats

func _ready() -> void:
	left_btn.pressed.connect(_go_left)
	right_btn.pressed.connect(_go_right)
	confirm_btn.pressed.connect(_confirm)
	selected = GameManager.chosen_class
	_update_display()
	confirm_btn.grab_focus()

func _go_left() -> void:
	selected = (selected - 1 + 3) % 3
	GameManager.chosen_class = selected
	_update_display()

func _go_right() -> void:
	selected = (selected + 1) % 3
	GameManager.chosen_class = selected
	_update_display()

func _confirm() -> void:
	GameManager.chosen_class = selected
	GameManager.last_checkpoint_pos = Vector2(80, 270)
	GameManager.flask_uses = GameManager.max_flask_uses
	GameManager.souls = 0
	GameManager.lost_souls = 0
	get_tree().change_scene_to_file("res://scenes/level_1.tscn")

func _update_display() -> void:
	var d: Dictionary = GameManager.CLASS_DATA[selected]
	name_label.text = d.name
	desc_label.text = d.description

	stats_label.text = (
		"HP      %d\nSTAMINA %d\nSPEED   %d" % [d.max_hp, int(d.max_stamina), int(d.speed)]
	)

	if preview_node:
		preview_node.queue_redraw()

func _process(_delta: float) -> void:
	if preview_node:
		preview_node.queue_redraw()

	# Keyboard navigation
	if Input.is_action_just_pressed("move_left"):
		_go_left()
	elif Input.is_action_just_pressed("move_right"):
		_go_right()
