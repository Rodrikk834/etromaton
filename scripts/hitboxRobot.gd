extends Area2D

@export var damage := 1
@export var cooldown := 2
var can_damage := true

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if !can_damage:
		return
		
	if body.is_in_group("player"):
		can_damage = false
		body.take_damage(damage)
		await get_tree().create_timer(cooldown).timeout
		can_damage = true
