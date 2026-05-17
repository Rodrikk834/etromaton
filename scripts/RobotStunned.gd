extends State

@export var hitbox : Area2D
@export var duration := 3.0
@export var enemy : CharacterBody2D
@export var NavigationAgent : NavigationAgent2D
@export var animated_sprite : AnimatedSprite2D

var timer

func Enter():
	animated_sprite.play("stun")
	print("robot stun")
	timer = duration
	enemy.velocity = Vector2.ZERO
	NavigationAgent.target_position = enemy.global_position
	hitbox.monitoring = false

func Exit():
	hitbox.monitoring = true
	
func Physics_Update(_delta: float):
	timer -= _delta
	
	enemy.velocity = Vector2.ZERO
	enemy.move_and_slide()
	
	if timer <= 0:
		Transitioned.emit(self, "RobotIdle") 
		
