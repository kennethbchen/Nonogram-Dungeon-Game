
extends Character

class_name Player

# Energy is used when the nonogram board is being modified by the player
var max_energy = 100
var energy = max_energy

var found_stairs = false

# For UI Elements
signal energy_changed(value, max_value)

# To indicate the stairs have been found
signal stairs_found()

# Signal that is fired when the player's turn is over
signal player_turn_over()

# Called when the node enters the scene tree for the first time.
func _ready():
	max_health = 10
	health = max_health
	
	# The player does not need a health bar
	remove_child(get_node("HealthBar"))
	
	# Update UI Elements
	emit_signal("health_changed", max_health, max_health)
	emit_signal("energy_changed", max_energy, max_energy)

# Reduces health and fires signal
func take_damage(damage):
	.take_damage(damage)
	
	if health == 0:
		print("ded")

# Returns true if the energy is able to be used (and is subsequently used)
# Else false
func use_energy(cost):
	if cost <= energy:
		energy = max(0, energy - cost)
		emit_signal("energy_changed", energy, max_energy)
		return true
	else:
		return false
		
# Animation for moving
func move_tween(dir):
	tween.interpolate_callback(self, 1.0/move_speed, "_tween_callback")
	.move_tween(dir)

# Animation for failing to move
func bump_tween(dir):
	tween.interpolate_callback(self, 1.0/move_speed, "_tween_callback")
	.bump_tween(dir)

func try_move(direction: Vector2):
	.try_move(direction)
	
	pass

# When the tween movement is over, the player's turn is over
# The callback is used so the enemies will only movea after the player's animation has finished
func _tween_callback():
	
	if found_stairs:
		found_stairs = false
		emit_signal("stairs_found")
		emit_signal("player_turn_over")
		return
	
	# The player has done an action in the world
	# The player's turn has ended
	emit_signal("player_turn_over")
	pass

# Returns true on successful move, else false
func _handle_collision(direction: Vector2, collider):
	if collider.is_in_group("enemy"):
		attack_character(collider)
		bump_tween(direction)
		return false
	elif collider is Stairs:
		collider.interact_with(self)
		move_tween(direction)
		return false
	elif collider is Trap:
		collider.interact_with(self)
		move_tween(direction)
		return true
	elif collider is Interactable:
		collider.interact_with(self)
		bump_tween(direction)
		return false
	else:
		bump_tween(direction)
		return false

func stairs_found():
	found_stairs = true
