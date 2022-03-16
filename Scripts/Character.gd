extends Node2D

class_name Character

onready var board_controller = $"../BoardController"

# Raycast 2D used for character collision
onready var ray = $RayCast2D

# Tween used for movement animation
onready var tween = $Tween
export var move_speed = 15

signal health_changed(value, max_value)

# Stats
var max_health = 50
var health = max_health

var attack = 5

func _ready():
	emit_signal("health_changed", max_health, max_health)
	pass

func take_damage(damage):
	health = max(0, health - abs(damage))
	emit_signal("health_changed", health, max_health)
	
	if health == 0:
		queue_free()
	
func try_move(direction: Vector2):
	
	# Don't move if already in moving animation
	if tween.is_active():
		return
		
	ray.cast_to = direction * board_controller.tile_size
	ray.force_raycast_update()
	
	
	if !board_controller.is_in_board( \
		board_controller.world_to_board(position + direction * board_controller.tile_size)):
		# Don't move outside the board
		bump_tween(direction)
	elif(!ray.is_colliding()):
		# Move
		move_tween(direction)
	else:
		# Collision handle collision
		_handle_collision(direction, ray.get_collider())

# Handle a collision for try_move
func _handle_collision(direction: Vector2, collider: Object):
	pass

func attack_character(character: Character):
	character.take_damage(attack)

# Animation for moving
func move_tween(dir):
	tween.interpolate_property(self, "position",
		position, position + dir * board_controller.tile_size,
		1.0/move_speed, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.start()
	
# Animation for failing to move
func bump_tween(dir):
	var old_pos = position
	var new_pos = position + dir * board_controller.tile_size / 4
	tween.interpolate_property(self, "position", position, new_pos,
		1.0/move_speed, Tween.TRANS_BACK, Tween.EASE_IN_OUT)
	tween.interpolate_property(self, "position",
		position, old_pos,
		1.0/move_speed, Tween.TRANS_SINE, Tween.EASE_IN_OUT, .15)
	tween.start()
