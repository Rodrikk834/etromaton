extends State

@export var hitbox : Area2D
@export var duration := 20.0
@export var enemy : CharacterBody2D
@export var NavigationAgent : NavigationAgent2D

var timer

func Enter():
	timer = duration
	enemy.velocity = Vector2(0.0, 0.0)
	NavigationAgent.target_position = enemy.global_position
	hitbox.monitoring = false

func Exit():
	hitbox.monitoring = true
	
func Physics_Update(_delta: float):
	timer -= _delta
	if timer <= 0:
		Transitioned.emit(self, "RobotIdle") 
		
