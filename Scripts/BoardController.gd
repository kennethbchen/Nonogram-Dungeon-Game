"""
Acts as an interface to the game boards to other nodes
Nonogram board -> player input area for nonogram
Solution board -> nonogram solution
World board -> player character world 
"""
extends Node

onready var board_generator = $BoardGenerator

export(NodePath) var viewport_container_path; onready var viewport_container = get_node(viewport_container_path) as Node

# Tilemap that represents the nonogram board
# Correctly marked tiles on the board will hide to reveal the WorldTileMap
export(NodePath) onready var nonogram_tile_map = $"../Tilemaps/NonogramTileMap" as TileMap

# Tilemap that represents the solution of the nonogram board
# with proper coloring or marking out
export(NodePath) onready var solution_tile_map = $"../Tilemaps/SolutionTileMap" as TileMap

export(NodePath) onready var world_tile_map = $"../Tilemaps/WorldTileMap" as TileMap

export(NodePath) onready var entities_node = $"../Entities"
export(NodePath) onready var enemies_node = $"../Enemies"

export(NodePath) var camera_path; onready var camera = get_node(camera_path) as Node

var root

var columns = Util.max_floor_columns
var rows = Util.max_floor_rows

var tile_size = 0

signal hint_changed(new_hint)

func _ready():
	tile_size = board_generator.tile_size
	root = get_tree().root
	
# Generates the nonogram board and solution
# The World layer of the board is within the world_tilemap itself
func init_board():
	var data = board_generator.generate_board()
	pass
	
	
func set_tile(tilemap_coord, tileset_index):
	nonogram_tile_map.set_cellv(tilemap_coord, tileset_index)
	
# Based on the tile coords and mouse input, make a mark on the nonogram tilemap
# If direct replace is enabled, then 
func handle_tile_input(nonogram_tile_map_coords, button_index):
	
	# Don't try to change a tile that is not in the board
	if not is_in_board(nonogram_tile_map_coords):
		return
	
	var tile = -1
	match (button_index):
		BUTTON_RIGHT:
			tile = Util.nono_cross
		BUTTON_LEFT:
			tile = Util.nono_color
	
	# If the solution map matches the tile input, then that input is correct
	var correct_input = solution_tile_map.get_cellv(nonogram_tile_map_coords) == tile
	
	# If the nonogram map has no tile, then the tile was already marked correctly
	var already_correct = nonogram_tile_map.get_cellv(nonogram_tile_map_coords) == -1
	
	# Whether or not the tile and the input are the same correct value or same incorrect value
	var same_correct = correct_input and already_correct
	var same_incorrect = nonogram_tile_map.get_cellv(nonogram_tile_map_coords) == tile
	
	
	# Compare this action with solution tile map to see if it's a correct one
	if correct_input and not already_correct:
		
		# If it is correct, then the tile is removed to reveal the tilemaps underneath it
		nonogram_tile_map.set_cellv(nonogram_tile_map_coords, -1)
		
	elif same_correct or same_incorrect:

		nonogram_tile_map.set_cellv(nonogram_tile_map_coords, Util.nono_blank)

	else:
		# Set the tile
		nonogram_tile_map.set_cellv(nonogram_tile_map_coords, tile)


func set_dungeon_board_visibility(visible):
	if visible:
		world_tile_map.show()
		entities_node.show()
		enemies_node.show()
	else:
		world_tile_map.hide()
		entities_node.hide()
		enemies_node.hide()

# Gets a nonogram_tile_map coordinate and returns whether or not that is in the board
func is_in_board(tilemap_coord):
	# If the coordinate is within the bounds of the number of columns and rows, then it is in bounds
	if tilemap_coord[0] >= 0 and tilemap_coord[0] < columns:
		if tilemap_coord[1] >= 0 and tilemap_coord[1] < rows :
			return true
	return false

# Takes in a tilemap coordinate and returns if it is a valid more or not
func is_valid_move(tilemap_coord: Vector2):
	if world_tile_map.get_cellv(tilemap_coord) >= 0:
		return false
	
	if not is_in_board(tilemap_coord):
		return false
		
	return true

# Compares the nonogram board and if the tile is blank, that means that it is correct
func is_correct_mark(tilemap_coord: Vector2):
	if not is_in_board(tilemap_coord):
		return false
	
	if nonogram_tile_map.get_cellv(tilemap_coord) == -1:
		return true
	else:
		return false

# Returns the position of the closest tile that the mouse is pointing at
# This doesn't think about whether or not a tile is visible in the camera and returns it anyways
func get_selected_tile():

	# It appears that getting the mouse position relative to a 
	# non-root viewport does not work if the root viewport is scaled up or down
	# These don't work:
	
	# 1: get_viewport().get_mouse_position()
	# (This would have gotten the mouse's x and y position ranging from 0 to the sizes of the window)
	# For example, if the viewport is 200 x 200 px, the mouse position would be from 0 to 200 in both dimensions
	
	# 2: nonogram_tile_map.get_[local/global]_mouse_position() 
	# (The original solution. Gets the mouse's position as if it was an object in the world relative to nonogram tilemap)
	
	# Trying to use both methods and some combination of scaling 
	# their output based on the scale of the window never appeared to work
	
	# What DOES work regardless of scale is the root viewport's get_mouse_position()
	# which is the equivalent of get_viewport().get_mouse_position() except for the root viewport and also it works
	
	# So, use the mouse position relative to the root transform, and transform that coordinate space
	# so that it is the equivalent of method #2 mentioned above
	
	# The selected tile is dependent on where the camera is pointing
	# pos without the offset value is the position of the mouse relative to the viewport_container's position
	# offset shifts this position to the correct world position based on the camera
	
	var offset = Vector2(camera.get_grid_pos().x * Util.tile_size * Util.room_columns, camera.get_grid_pos().y * Util.tile_size * Util.room_rows)
	var pos = ((root.get_mouse_position() - viewport_container.rect_position)) + offset
	
	# Use the world position and calculate what nonogram tile corresponds to that position in tile space
	return nonogram_tile_map.world_to_map(pos)

func get_nono_tile(tilemap_coord: Vector2):
	return nonogram_tile_map.get_cellv(tilemap_coord)

func get_solution_tile(tilemap_coord: Vector2):
	return solution_tile_map.get_cellv(tilemap_coord)

# Converts world space to tilemap space
func world_to_board(pos: Vector2):
	return nonogram_tile_map.world_to_map(pos)
	
func board_to_world(pos: Vector2):
	return nonogram_tile_map.map_to_world(pos)

# Takes a room position and generates an array that contains the nonogram hints for that room
# Room coordinates are 0-indexed and start from the top left room as (0,0)
# The returned array is an array[2][x] of strings where:
# In array[0], x is the hints of the columns (top of board) and
# In array[1], x is the hints of the rows (left of board)
# Each individual cell (array[a][b]) is the full hint as a string that should be displayed
func _generate_hint(room_position: Vector2):
	
	# Starting positions in tilemap space
	var start_col = room_position.x * Util.room_columns
	var start_row = room_position.y * Util.room_rows
	
	var end_col = start_col + Util.room_columns
	var end_row = start_row + Util.room_rows
	
	#print( str([start_col, start_row]) + " " + str([end_col, end_row]))
	
	var output = []
	
	# The solution line holds the column / row solutions before it is put into output
	var solution_line = []
	
	# The size of the current continuous line of squares
	var line_count = 0
	
	# The text that is displayed as the actual hint for each given continuous line of squares
	var line_text = ""
	
	# Generate the hints for the columns (top)
	# Go column by column
	solution_line = []
	for col in range(start_col, end_col):
		
		
		# Reset vars for new column
		line_count = 0
		line_text = ""
		
		for row in range(start_row, end_row):
			
			var position = Vector2(col, row)
			
			if solution_tile_map.get_cellv(position) == Util.nono_color:
				# If a 1 is found, record it
				line_count += 1
			elif solution_tile_map.get_cellv(position) == Util.nono_cross and line_count > 0:
				# If a 0 is found and we were already counting a sequence of 1's,
				# record and terminate that sequence
			
				if line_text != "":
					# Don't add a leading new line for the first number
					line_text += "\n"
					
				# Record and terminate sequence
				line_text += str(line_count) 
				line_count = 0
		
		# Process the value of line_count at the end of a column
		if line_count > 0:
			# If there is a line count left over, then add it to the row text
			
			if line_text != "":
				# Only add a leading newline if there was already something in the row text
				line_text += "\n"
			
			line_text += str(line_count)
			
		elif line_count == 0 and line_text == "":
			# if there was no 1's in that entire row, add a zero to the row text
			line_text += "0"
		
		solution_line.append(line_text)
	
	output.append(solution_line)
	
	solution_line = []
	# Generate the hints for the rows (left side)
	# Go row by row
	for row in range(start_row, end_row):
		# Reset vars for new row
		line_count = 0
		line_text = ""
		for col in range(start_col, end_col):
			
			var position = Vector2(col, row)
			
			
			if solution_tile_map.get_cellv(position) == Util.nono_color:
				# If a 1 is found
				line_count += 1
			elif solution_tile_map.get_cellv(position) == Util.nono_cross and line_count > 0:
				# If a 0 is found and we were already counting a sequence of 1's,
				# terminate and record that sequence
			
				if line_text != "":
					# Don't add a leading space for the first number
					line_text += "   "
					
				# Add the current sequence to the row and reset count
				line_text += str(line_count) 
				line_count = 0
		
		
		# Process the end of a column
		if line_count > 0:
			# At the end of a row, if there is a line count left over, then add it to the row text
			if line_text != "":
				# Only add a leading space if there was already something in the row text
				line_text += "   "
			line_text += str(line_count)
		elif line_count == 0 and line_text == "":
			# if there was no 1's in that row, add a zero to the row text
			line_text += "0"
		
		solution_line.append(line_text)
		
	output.append(solution_line)
	
	return output

func _on_camera_changed(new_position):
	var hint = _generate_hint(new_position) 
	
	emit_signal("hint_changed", hint)
