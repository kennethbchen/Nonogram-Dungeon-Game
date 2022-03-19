extends Character

class_name Player

# Energy is used when the nonogram board is being modified by the player
var max_energy = 70
var energy = max_energy

# For UI Elements
signal energy_changed(value, max_value)

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

func _handle_collision(direction: Vector2, collider):
	if collider.is_in_group("enemy"):
		attack_character(collider)
		bump_tween(direction)
	elif collider is Stairs:
		collider.interact_with(self)
		move_tween(direction)
	elif collider is Trap:
		collider.interact_with(self)
		move_tween(direction)
	elif collider is Interactable:
		collider.interact_with(self)
		bump_tween(direction)
	else:
		bump_tween(direction)
		
