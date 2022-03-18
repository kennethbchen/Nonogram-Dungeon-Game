extends Node2D

onready var player = $Player

onready var board_controller = $BoardController

onready var effect_tilemap = $Tilemaps/EffectTileMap

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
	
	# Check for L / R Mouse Click for nonogram input
	if event is InputEventMouseButton and event.pressed and board_controller.is_in_board(selected_tile):

		# If there is a left or right mouse click in board, process it
		if event.button_index == BUTTON_LEFT or event.button_index == BUTTON_RIGHT:
			if player.use_energy(1):
				board_controller.handle_tile_input(selected_tile, event.button_index)
			
	# Handle mouse hovering visual
	if event is InputEventMouseMotion and board_controller.is_in_board(board_controller.get_selected_tile()):
		if hovered_tile != board_controller.get_selected_tile():
			effect_tilemap.set_cellv(hovered_tile, -1)
			hovered_tile = board_controller.get_selected_tile()
			effect_tilemap.set_cellv(hovered_tile, Util.nono_cursor)
	elif not board_controller.is_in_board(board_controller.get_selected_tile()):
		effect_tilemap.set_cellv(hovered_tile, -1)
		hovered_tile = Vector2(-1, -1)
		
			
			
func _process(_delta):
	
	# Detect player input for character movement
	var move_dir = Vector2.ZERO
	if Input.is_action_just_pressed("move_up"):
		move_dir = UP
	if Input.is_action_just_pressed("move_down"):
		move_dir = DOWN
	if Input.is_action_just_pressed("move_right"):
		move_dir = RIGHT
	if Input.is_action_just_pressed("move_left"):
		move_dir = LEFT
		
	if Input.is_action_just_pressed("ui_accept"):
		player.take_damage(1)
	
	if move_dir != Vector2.ZERO:
		player.try_move(move_dir)
		
