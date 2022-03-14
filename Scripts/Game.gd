extends Node2D

onready var player = $Player

onready var board_controller = $BoardController

# Raycast 2D used for player collision
onready var ray = $Player/RayCast2D

onready var effect_tilemap = $Tilemaps/EffectTileMap

onready var tween = $Player/Tween

export var move_speed = 15

var hovered_tile = Vector2(-1, -1)

# Directions for movement
const RIGHT = Vector2.RIGHT
const LEFT = Vector2.LEFT
const UP = Vector2.UP
const DOWN = Vector2.DOWN

# Called when the node enters the scene tree for the first time.
func _ready():
	board_controller.generateBoard()

func _input(event):
	# Get the selected tile in nonogram_tile_map space
	var selected_tile = board_controller.get_selected_tile()
	
	# Check for L / R Mouse Click
	if event is InputEventMouseButton and event.pressed and board_controller.is_in_board(selected_tile):

		# If there is a left or right mouse click in board, process it
		if event.button_index == BUTTON_LEFT or event.button_index == BUTTON_RIGHT:
			board_controller.handle_tile_input(selected_tile, event.button_index)
			
			
	if event is InputEventMouseMotion and board_controller.is_in_board(board_controller.get_selected_tile()):
		if hovered_tile != board_controller.get_selected_tile():
			effect_tilemap.set_cellv(hovered_tile, -1)
			hovered_tile = board_controller.get_selected_tile()
			effect_tilemap.set_cellv(hovered_tile, 5)
	else:
		effect_tilemap.set_cellv(hovered_tile, -1)
		hovered_tile = Vector2(-1, -1)
		
			
			
func _process(_delta):
	
	if tween.is_active():
		return
	
	# Detect player movement
	var move_dir = Vector2.ZERO
	if Input.is_action_just_pressed("move_up"):
		move_dir = UP
	if Input.is_action_just_pressed("move_down"):
		move_dir = DOWN
	if Input.is_action_just_pressed("move_right"):
		move_dir = RIGHT
	if Input.is_action_just_pressed("move_left"):
		move_dir = LEFT
	
	if move_dir != Vector2.ZERO:
		move(move_dir)
		

func move(dir):
	
	# Don't move in a direction that is outside the board
	if not board_controller.is_in_board(board_controller.world_to_board(player.position + dir * board_controller.tile_size)):
		bump_tween(dir)
		return
	
	# Check for any collisions
	ray.cast_to = dir * board_controller.tile_size
	ray.force_raycast_update()
	
	if !ray.is_colliding():
		# Only move if there is no collision
		move_tween(dir)
	else:
		bump_tween(dir)
		
	
func move_tween(dir):
	tween.interpolate_property(player, "position",
		player.position, player.position + dir * board_controller.tile_size,
		1.0/move_speed, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.start()
	
func bump_tween(dir):
	var old_pos = player.position
	var new_pos = player.position + dir * board_controller.tile_size / 4
	tween.interpolate_property(player, "position",
		player.position, new_pos,
		1.0/move_speed, Tween.TRANS_BACK, Tween.EASE_IN_OUT)
	tween.interpolate_property(player, "position",
		player.position, old_pos,
		1.0/move_speed, Tween.TRANS_SINE, Tween.EASE_IN_OUT, .15)
	tween.start()
