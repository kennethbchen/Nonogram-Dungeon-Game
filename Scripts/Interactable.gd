extends Area2D

class_name Interactable

# Signal that is fired when the interactable object is going to be delted
# For informing pathfinding that the current position is a valid path node
signal tile_free(entity)

func interact_with(character: Character):
	pass
	
func delete_self():
	emit_signal("tile_free", self)
	queue_free()
