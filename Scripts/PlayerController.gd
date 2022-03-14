extends "res://Scripts/Character.gd"

# Energy is used when the nonogram board is being modified by the player
var max_energy = 70
var energy = max_energy

# For UI Elements
signal health_changed(value, max_value)
signal energy_changed(value, max_value)

# Called when the node enters the scene tree for the first time.
func _ready():
	# Update UI Elements
	emit_signal("health_changed", max_health, max_health)
	emit_signal("energy_changed", max_energy, max_energy)

# Reduces health and fires signal
func take_damage(damage):
	.take_damage(damage)
	
	emit_signal("health_changed", health, max_health)
	
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

