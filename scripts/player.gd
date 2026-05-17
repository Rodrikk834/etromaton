extends CharacterBody2D

@export var move_speed: float = 100
@export var bullet_scene: PackedScene
@export var lives := 3
@onready var footsteps = $FootstepsP

var spawn_position: Vector2


var nearby_item = null
var can_shoot = false

func _ready():
	spawn_position = global_position

func take_damage(amount := 1):
	lives -= amount
	print("Vidas: ", lives)

	global_position = spawn_position
	velocity = Vector2.ZERO

	if lives <= 0:
		print("Game Over")

func _physics_process(_delta):
	var direction := Input.get_vector("move_left", "move_right","move_up","move_down")
	
	velocity = direction * move_speed
	move_and_slide()
	if velocity.length() > 0:
		if !footsteps.playing:
			footsteps.play()
	else:
		footsteps.stop()
	
	look_at(get_global_mouse_position())
	
	if Input.is_action_just_pressed("interact"):
		interact()
	
	if Input.is_action_just_pressed("shoot") and can_shoot:
		shoot()


func interact() -> void:
	if nearby_item != null:
		if nearby_item.has_method("pickup"):
			nearby_item.pickup(self)
		elif nearby_item.has_method("interact"):
			nearby_item.interact(self)

func unlock_shooting():
	can_shoot = true

func shoot():
	var ray = bullet_scene.instantiate()
	get_parent().add_child(ray)
	ray.global_position = $ShootPos.global_position
	ray.global_rotation = $ShootPos.global_rotation


func _on_pick_up_area_area_entered(area: Area2D) -> void:
	if area.has_method("pickup") or area.has_method("interact"):
		nearby_item = area


func _on_pick_up_area_area_exited(area: Area2D) -> void:
	if area == nearby_item:
		nearby_item = null
		
