extends Node2D

onready var board_controller = $"../BoardController"

# Raycast 2D used for character collision
onready var ray = $RayCast2D

# Tween used for movement animation
onready var tween = $Tween
export var move_speed = 15

# Stats
var max_health = 15
var health = max_health

func _ready():
	pass

func take_damage(damage):
	health = max(0, health - abs(damage))
	
func try_move(direction: Vector2):
	
	if tween.is_active():
		return
		
	if board_controller.is_valid_move(board_controller.world_to_board(position) + direction):
		move_tween(direction)
	else:
		bump_tween(direction)

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
