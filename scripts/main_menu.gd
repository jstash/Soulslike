extends Control

@onready var title_label: Label    = $VBox/Title
@onready var start_btn: Button     = $VBox/StartBtn
@onready var quit_btn: Button      = $VBox/QuitBtn
@onready var bg_draw: Node2D       = $Background

func _ready() -> void:
	start_btn.pressed.connect(_on_start)
	quit_btn.pressed.connect(_on_quit)
	start_btn.grab_focus()

func _on_start() -> void:
	get_tree().change_scene_to_file("res://scenes/class_select.tscn")

func _on_quit() -> void:
	get_tree().quit()

func _process(_delta: float) -> void:
	if bg_draw:
		bg_draw.queue_redraw()
