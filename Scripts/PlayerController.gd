
extends Character

class_name Player

# Energy is used when the nonogram board is being modified by the player
var max_energy = 160
var energy = max_energy

var found_stairs = false

# For UI Elements
signal energy_changed(value, max_value)

# To indicate the stairs have been found
signal stairs_found()

# Signal that is fired when the player's turn is over
signal player_turn_over()

# Sound Effects
signal player_footstep()
signal player_attack()
signal player_door()
signal player_trap()
signal player_health()
signal player_energy()
signal player_hurt()

signal player_death()

# Called when the node enters the scene tree for the first time.
func _ready():
	max_health = 10
	init()
	
	# The player does not need a health bar
	get_node("HealthBar").queue_free()
	
	

func init():
	
	health = max_health
	energy = max_energy
	
	# Update UI Elements
	emit_signal("health_changed", max_health, max_health)
	emit_signal("energy_changed", max_energy, max_energy)

# Reduces health and fires signal
func take_damage(damage):
	.take_damage(damage)
	
	emit_signal("player_hurt")
	if health == 0:
		emit_signal("player_death")

# Returns true if the energy is able to be used (and is subsequently used)
# Else false
func use_energy(cost):
	if cost <= energy:
		energy = max(0, energy - cost)
		emit_signal("energy_changed", energy, max_energy)
		return true
	else:
		return false

func restore_energy(amount):
	energy = min(max_energy, energy + amount)
	emit_signal("energy_changed", energy, max_energy)

# Animation for moving
func move_tween(dir):
	tween.interpolate_callback(self, 1.0/move_speed, "_tween_callback")
	.move_tween(dir)

# Animation for failing to move
func bump_tween(dir):
	tween.interpolate_callback(self, 1.0/move_speed, "_tween_callback")
	.bump_tween(dir)

func try_move(direction: Vector2):
	var result = .try_move(direction)
	if result:
		emit_signal("player_footstep")
	return result

# When the tween movement is over, the player's turn is over
# The callback is used so the enemies will only movea after the player's animation has finished
func _tween_callback():
	
	if found_stairs:
		found_stairs = false
		emit_signal("stairs_found")
	
	# The player has done an action in the world
	# The player's turn has ended
	emit_signal("player_turn_over")

# Returns true on successful move, else false
func _handle_collision(direction: Vector2, collider):
	if collider.is_in_group("enemy"):
		attack_character(collider)
		bump_tween(direction)
		emit_signal("player_attack")
		return false
	elif collider is Stairs:
		collider.interact_with(self)
		emit_signal("stairs_found")
		
		return false
	elif collider is Trap:
		collider.interact_with(self)
		move_tween(direction)
		emit_signal("player_trap")
		return true
	elif collider is Interactable:
		collider.interact_with(self)
		bump_tween(direction)
		
		if collider is Door:
			emit_signal("player_door")
		elif collider is Apple:
			emit_signal("player_health")
		elif collider is Potion:
			emit_signal("player_energy")
		return false
	else:
		bump_tween(direction)
		return false
