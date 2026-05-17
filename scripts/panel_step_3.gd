extends Node2D

@export var button_finish: Button
@export var game_manager: Node2D

func _ready() -> void:
	button_finish.pressed.connect(_on_button_finish_pressed)

func _on_button_finish_pressed() -> void:
	# salir del canvas
	visible = false
