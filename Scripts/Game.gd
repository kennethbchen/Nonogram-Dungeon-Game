extends Node2D

onready var player = $Player

onready var board_controller = $BoardController

onready var effect_tilemap = $Tilemaps/EffectTileMap

onready var enemies_node = $Enemies

var hovered_tile = Vector2(-1, -1)

# Directions for movement
const RIGHT = Vector2.RIGHT
const LEFT = Vector2.LEFT
const UP = Vector2.UP
const DOWN = Vector2.DOWN

# Mouse Dragging
var drag = false
var drag_origin = Vector2.ZERO
var drag_button = -1
var visited_tiles = []

# Called when the node enters the scene tree for the first time.
func _ready():
	
	_create_board()
	
	# Hook into the player's signals
	player.connect("player_turn_over", self, "_on_player_turn_over")
	player.connect("stairs_found", self, "_on_stairs_found")
	
func _create_board():
	board_controller.init_board()
	

func _input(event):
	# Get the selected tile in nonogram_tile_map space
	var selected_tile = board_controller.get_selected_tile()
	
	# Check for L / R Mouse Click for nonogram input
	if event is InputEventMouseButton and event.pressed and board_controller.is_in_board(selected_tile):
		drag = true
		drag_button = event.button_index
		drag_origin = board_controller.get_selected_tile()
		visited_tiles.append(board_controller.get_selected_tile())
		print(drag)
		
		# If there is a left or right mouse click in board, process it
		if event.button_index == BUTTON_LEFT or event.button_index == BUTTON_RIGHT:
			if player.use_energy(1):
				board_controller.handle_tile_input(selected_tile, event.button_index)
	
	# If the mouse was released, reset all dragging-related variables
	if event is InputEventMouseButton and not event.pressed:
		drag = false
		drag_origin = Vector2.ZERO
		drag_button = -1
		visited_tiles = []
	
	# Handle mouse dragging input
	if event is InputEventMouseMotion and drag and board_controller.is_in_board(board_controller.get_selected_tile()):
		var tile_coords = board_controller.get_selected_tile()
		
		# If the mouse is being dragged onto a tile that is new, process it
		if not visited_tiles.has(tile_coords):
			var tile = -1
			match drag_button:
				BUTTON_LEFT:
					tile = Util.nono_color
				BUTTON_RIGHT:
					tile = Util.nono_cross
					
			
			if board_controller.get_nono_tile(tile_coords) != tile and player.use_energy(1):
				visited_tiles.append(tile_coords)
				board_controller.handle_tile_input(board_controller.get_selected_tile(), drag_button)
				
	
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
		_create_board()
		
	if move_dir != Vector2.ZERO:
		player.try_move(move_dir)
		

func _on_player_turn_over():
	# The player's turn is over, so let all enemies at
	for enemy in get_tree().get_nodes_in_group("enemy"):
		enemy.act()

func _on_stairs_found():
	player.restore_energy(35)
	_create_board()
