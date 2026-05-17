extends Area2D

func pickup(player):
	player.unlock_shooting()
	queue_free()
