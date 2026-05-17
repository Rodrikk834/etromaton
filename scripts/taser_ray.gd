extends Area2D

@export var lifetime: float = 0.5
@export var stun_state_name: String = "RobotStun"
func _ready():
	body_entered.connect(_on_body_entered)
	
	await get_tree().create_timer(lifetime).timeout
	queue_free()
	
func _on_body_entered(body):
	print("Taser tocó a: ", body.name)

	if body.is_in_group("Robot"):
		var state_machine = body.get_node_or_null("StateMachine")
		
		if state_machine:
			print("yessss")
			state_machine.change_state(stun_state_name)
