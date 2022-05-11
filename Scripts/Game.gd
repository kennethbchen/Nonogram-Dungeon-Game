extends Node2D

onready var player = $Player

onready var board_controller = $BoardController

onready var effect_tilemap = $Tilemaps/EffectTileMap

onready var enemies_node = $Enemies

onready var death_popup = $"UI/DeathPopup"

onready var cursor = $Cursor

var hovered_tile = Vector2(-1, -1)

# Directions for movement
const RIGHT = Vector2.RIGHT
const LEFT = Vector2.LEFT
const UP = Vector2.UP
const DOWN = Vector2.DOWN

# Mouse Dragging
var drag_origin = Vector2.ZERO
var drag_end = Vector2.ZERO
var drag_button = -1
var visited_tiles = []

var click_origin = Vector2(-1,-1)
var click_button = -1
var cancel_mouse = false
var drag = false

var dungeon_floor = 1

signal floor_changed(dungeon_floor)

var dead = false

var energy_cost = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	
	emit_signal("floor_changed", dungeon_floor)
	_create_board()
	
func _create_board():
	board_controller.init_board()
	

func _input(event):
	
	# Don't accept any inputs if dead
	if dead:
		return
	
	# Get the selected tile in nonogram_tile_map space based on mouse position
	var selected_tile = board_controller.get_selected_tile()
	var in_board = board_controller.is_in_board(selected_tile)
	
	# Register click press
	if event is InputEventMouseButton and event.pressed:
		
		# Don't do anything for clicks outside the board
		if not in_board:
			return
		
		
		if click_button == -1:
			click_origin = selected_tile
			click_button = event.button_index
		else:
			# If click button isn't -1, then another mouse button is being held down
			# so reset mouse state and cancel action
			cursor.enable_cursor()
			cursor.set_position(board_controller.get_selected_tile())
			_reset_mouse_state()
		
	
	# Register click relese
	if event is InputEventMouseButton and not event.pressed:
		
		# Don't do anything for clicks outside the board
		if not in_board:
			return
		
		# If the mouse was released in the same place it was clicked
		if selected_tile == click_origin:
			
			# If it's not a drag, then modify that singular tile

			# Don't modify tile if player can't pay energy cost
			if not player.use_energy(energy_cost):
				return
					
			board_controller.handle_tile_input(selected_tile, event.button_index)

			
		elif drag:
			# If it is a drag, then modify multiple tiles
			var diff = selected_tile - click_origin
			
			var from = -1
			var to = -1
			
			# The index of the new tile sprite that is going to be set
			var new_tile = -1
			match (click_button):
				BUTTON_LEFT:
					new_tile = Util.nono_color
				BUTTON_RIGHT:
					new_tile = Util.nono_cross
			
			if abs(diff.x) > abs(diff.y):
				# Horizontal
				
				if click_origin.x < selected_tile.x:
					from = click_origin.x
					to = selected_tile.x
				else:
					from = selected_tile.x
					to = click_origin.x

				
				for col in range(from, to + 1):
					var new_pos = Vector2(col, click_origin.y)
					
					# If the tile is already the color that is going to be set
					# or the tile is correct and the color that is going to be set
					# ignore the tile
					if board_controller.get_nono_tile(new_pos) == new_tile or \
						board_controller.is_correct_mark(new_pos) and board_controller.get_solution_tile(new_pos) == new_tile:
						continue
						
					if player.use_energy(energy_cost):
						board_controller.handle_tile_input(new_pos, click_button)
				
			else:
				# Vertical
				
				if click_origin.y < selected_tile.y:
					from = click_origin.y
					to = selected_tile.y
				else:
					from = selected_tile.y
					to = click_origin.y
					
				for row in range(from, to + 1):
					var new_pos = Vector2(click_origin.x, row)
					
					# If the tile is already the color that is going to be set
					# or the tile is correct and is the color that is going to be set
					# ignore the tile
					if board_controller.get_nono_tile(new_pos) == new_tile or \
						board_controller.is_correct_mark(new_pos) and board_controller.get_solution_tile(new_pos) == new_tile:
						continue
					
					if player.use_energy(energy_cost):
						board_controller.handle_tile_input(new_pos, click_button)
					
				
					
		_reset_mouse_state()
	
	# Register mouse move
	if event is InputEventMouseMotion:
		
		if not in_board:
			_reset_mouse_state()
		
			# If the mouse was clicked (and not released yet) and moved to a different tile, that is a drag
		if click_button != -1 and selected_tile != click_origin:
			drag = true
		elif selected_tile == click_origin:
			# If the mouse is returned back to the drag origin, then it is no longer a drag
			drag = false
	
	# Handle mouse hovering visual
	if event is InputEventMouseMotion:
		
		if in_board:
			
			if not drag:
				# Not dragging, normal cursor state
				cursor.enable_cursor()
				cursor.set_position(board_controller.get_selected_tile())
			else:
				# Dragging, multi select state
				cursor.disable_cursor()
				cursor.set_multi(click_origin, selected_tile)
		else:
			# Out of board, disable cursor
			cursor.disable_cursor()
			cursor.disable_multi()
		
		
	
func _reset_mouse_state():
	click_origin = Vector2(-1,-1)
	click_button = -1
	drag = false

func _process(_delta):
	
	# Don't accept any inputs if dead
	if dead:
		return
		
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
		_on_stairs_found()
		#_on_player_death()
		pass
	
	if Input.is_action_just_pressed("hide_dungeon"):
		board_controller.set_dungeon_board_visibility(false)
	elif Input.is_action_just_released("hide_dungeon"):
		board_controller.set_dungeon_board_visibility(true)
	
	
	if move_dir != Vector2.ZERO:
		player.try_move(move_dir)
		

func _on_player_turn_over():
	# The player's turn is over, so let all enemies at
	for enemy in get_tree().get_nodes_in_group("enemy"):
		enemy.act()

func _on_stairs_found():
	player.restore_energy(35)
	_create_board()
	dungeon_floor += 1
	emit_signal("floor_changed", dungeon_floor)

func _on_player_death():
	dead = true
	death_popup.show()
	
func _on_retry_button():
	if dead:
		_create_board()
		death_popup.hide()
		dead = false
		player.init()
		dungeon_floor = 1
		emit_signal("floor_changed", dungeon_floor)
	
