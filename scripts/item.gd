extends Area2D
class_name Item

var id : int

func pickup(player):
	player.unlock_shooting()
	queue_free()
