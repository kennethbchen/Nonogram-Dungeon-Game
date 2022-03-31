extends Area2D

class_name Interactable

# If the interactable item affect the character's stats, these are used
# Positive for add, negative for subtract
export(int) var health_change = 0
export(int) var energy_change = 0

# If the interacting character should still be allowed to move upon interacting
# This is for things like traps which the player steps on and takes damage
export(bool) var allow_movement = false

# If the interactable item should delete itself upon a character interacting with it
export(bool) var delete_self = false

# Signal that is fired when the interactable object is going to be delted
# For informing pathfinding that the current position is a valid path node
signal tile_free(entity)

func interact_with(character: Character):
	if health_change != 0:
		character.change_health(health_change)
		
	if energy_change != 0:
		character.change_energy(energy_change)
	
	if delete_self:
		delete_self()
	
	# Returns an array of data for the character to use
	# [0] if health changed
	# [1] if energy changed
	# [2] if the character is allowed to move to the tile
	return [health_change != 0, energy_change != 0, allow_movement]
	
func delete_self():
	emit_signal("tile_free", self)
	queue_free()
