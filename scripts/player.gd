extends CharacterBody2D

@export var move_speed: float = 250.0
@export var bullet_scene: PackedScene

var nearby_item = null
var can_shoot = false

func _physics_process(_delta):
	var direction := Input.get_vector("move_left", "move_right","move_up","move_down")
	
	velocity = direction * move_speed
	move_and_slide()
	
	look_at(get_global_mouse_position())
	
	if Input.is_action_just_pressed("interact"):
		interact()
	
	if Input.is_action_just_pressed("shoot") and can_shoot:
		shoot()


func interact() -> void:
	if nearby_item != null:
		if nearby_item.has_method("pickup"):
			nearby_item.pickup(self)

func unlock_shooting():
	can_shoot = true

func shoot():
	var ray = bullet_scene.instantiate()
	get_parent().add_child(ray)
	ray.global_position = $ShootPos.global_position
	ray.global_rotation = $ShootPos.global_rotation


func _on_pick_up_area_area_entered(area: Area2D) -> void:
	if area.has_method("pickup"):
		nearby_item = area


func _on_pick_up_area_area_exited(area: Area2D) -> void:
	if area == nearby_item:
		nearby_item = null
