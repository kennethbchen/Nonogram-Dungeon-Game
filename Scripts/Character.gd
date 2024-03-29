"""
Handles all properties and function of characters in the game world
"""

extends Node2D

class_name Character

onready var board_controller = $"../../BoardController"

# Raycast 2D used for character collision
onready var ray = $RayCast2D

onready var sound_eff_controller = $SoundEffectPlayer

# Tween used for movement animation
onready var tween = $Tween
export var move_speed = 15

signal health_changed(value, max_value)

# Stats
export(int) var max_health = 4
export(int) var health = max_health

export(int) var attack = 1

export(Array, Resource) var attack_sounds = []
export(Array, Resource) var hurt_sounds = []

func _ready():
	emit_signal("health_changed", max_health, max_health)
	pass

func take_damage(damage):
	change_health(abs(damage) * -1)

func heal(heal_amount):
	change_health(abs(heal_amount))

func change_health(change_amount):
	if change_amount > 0:
		# Positive change, heal
		health = min(max_health, health + change_amount)
	elif change_amount < 0:
		# Negative change, take damage
		health = max(0, health + (change_amount))
		sound_eff_controller.play_rand(hurt_sounds)
	else:
		return

	emit_signal("health_changed", health, max_health)

# Used when a character is attempting to move
# Returns true on successful movement, else false
func try_move(direction: Vector2):
	
	# Don't move if already in moving animation
	if tween.is_active():
		return false
		
	ray.cast_to = direction * Util.tile_size
	ray.force_raycast_update()
	
	
	if(!ray.is_colliding()):
		# Move
		move_tween(direction)
		return true
	else:
		# Collision handle collision
		return _handle_collision(direction, ray.get_collider())
		

# Handle a collision for try_move
# Returns true on successful move, else false
func _handle_collision(direction: Vector2, collider: Object):
	pass

func attack_character(character: Character):
	sound_eff_controller.play_rand(attack_sounds)
	character.take_damage(attack)

# Animation for moving
func move_tween(dir):
	tween.interpolate_property(self, "position",
		position, position + dir * Util.tile_size,
		1.0/move_speed, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.start()
	
# Animation for failing to move
func bump_tween(dir):
	var old_pos = position
	var new_pos = position + dir * Util.tile_size / 4
	tween.interpolate_property(self, "position", position, new_pos,
		1.0/move_speed, Tween.TRANS_BACK, Tween.EASE_IN_OUT)
	tween.interpolate_property(self, "position",
		position, old_pos,
		1.0/move_speed, Tween.TRANS_SINE, Tween.EASE_IN_OUT, .15)
	tween.start()
