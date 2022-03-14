extends Node

# Handles all aspects of the game board

# Tilemap that represents the nonagram board
# Correctly marked tiles on the board will hide to reveal the WorldTileMap
onready var nonagram_tile_map = $"../Tilemaps/NonagramTileMap"

# Tilemap that represents the solution of the nonagram board
# with proper coloring or marking out
onready var solution_tile_map = $"../Tilemaps/SolutionTileMap"

onready var world_tile_map = $"../Tilemaps/WorldTileMap"

onready var hint_font = load("res://Font/Font.tres")

# Maps tile type names to tile ID in Tileset
var tiles = {
	"Blank": 0,
	"Crossed": 1,
	"Colored": 2,
}

var tile_size = 16

# The solution to the current board
# It's assumed that the solution is at least rectangular, if not square
var solution = [
	[0, 1, 0, 1, 0, 1],
	[1, 1, 1, 1, 1, 0],
	[1, 1, 1, 1, 1, 0],
	[1, 1, 0, 1, 1, 1],
	[0, 0, 0, 0, 0, 0],
	[1, 1, 0, 1, 1, 1],
	[0, 0, 0, 0, 0, 0]
]

# The hints of the current board that are displayed
var hint

var columns = 0
var rows = 0

func generateBoard():
	# Generate the hint to display based on the solution of the board
	hint = _generate_hint(solution)
	
	columns = solution[0].size()
	rows = solution.size()
	
	# Generate NonogramTileMap tiles based on board dimensions
	for col in columns:
		
		for row in rows:
			
			# Create hints for rows (left side of board)
			if col == 0:
				var label = Label.new();
				
				# Do some horrible math to generate label for left side of board
				label.set_size(Vector2(64, 0))
				label.set_position(nonagram_tile_map.get_global_position() - Vector2(66, -nonagram_tile_map.map_to_world(Vector2(0,row))[1]))
				label.add_font_override("font", hint_font)
				label.align = HALIGN_RIGHT
				label.valign = VALIGN_BOTTOM
				
				# hint[1] is the hints for the left side
				label.text = str(hint[1][row])
				add_child(label)
			
			# Create hints for columns (top of board)
			if row == 0:
				# Do some horrible math to generate label for top of board
				var label = Label.new();
				
				# Do some horrible math to generate label for left side of board
				label.set_size(Vector2(16, 64))
				label.set_position(nonagram_tile_map.get_global_position() - Vector2(-nonagram_tile_map.map_to_world(Vector2(col, 0))[0], 64))
				label.add_font_override("font", hint_font)
				label.align = HALIGN_CENTER
				label.valign = VALIGN_BOTTOM
				
				label.text = str(hint[0][col])
				add_child(label)
				pass
				
			# Set the nonagram tilemap to a blank tile
			nonagram_tile_map.set_cell(col, row, 0)
			
			# Set the corresponding solution for the SolutionTileMap based on solution
			# index is needed because of a bad translation between solution value (0 = not colored, 1 = colored)
			# and tilemap id value (1 = not colored, 2 = colored)
			var index
			if solution[row][col] == 0:
				index = 1
			else:
				index = 2
				
			solution_tile_map.set_cell(col, row, index)

# Takes a board solution and generates an array that contains the hints for that board
# The returned array is an array[2][x] of strings where:
# In array[0], x is the hints of the columns (top of board) and
# In array[1], x is the hints of the rows (left of board)
func _generate_hint(solution):
	
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
	for col in solution[0].size():
		
		# Reset vars for new column
		line_count = 0
		line_text = ""
		
		for row in solution.size():
			if solution[row][col] == 1:
				# If a 1 is found, record it
				line_count += 1
			elif solution[row][col] == 0 and line_count > 0:
				# If a 0 is found and we were already counting a sequence of 1's,
				# record and terminate that sequence
			
				if line_text != "":
					# Don't add a leading space for the first number
					line_text += "\n"
					
				# Record and terminate sequence
				line_text += str(line_count) 
				line_count = 0
		
		# Process the value of line_count at the end of a column
		if line_count > 0:
			# If there is a line count left over, then add it to the row text
			
			if line_text != "":
				# Only add a leading space if there was already something in the row text
				line_text += " "
			
			line_text += str(line_count)
			
		elif line_count == 0 and line_text == "":
			# if there was no 1's in that entire row, add a zero to the row text
			line_text += "0"
		
		solution_line.append(line_text)
	
	output.append(solution_line)
	
	solution_line = []
	# Generate the hints for the rows (left side)
	# Go row by row
	for row in solution.size():
		# Reset vars for new row
		line_count = 0
		line_text = ""
		for col in solution[row].size():
			
			
			if solution[row][col] == 1:
				# If a 1 is found
				line_count += 1
			elif solution[row][col] == 0 and line_count > 0:
				# If a 0 is found and we were already counting a sequence of 1's,
				# terminate and record that sequence
			
				if line_text != "":
					# Don't add a leading space for the first number
					line_text += " "
					
				# Add the current sequence to the row and reset count
				line_text += str(line_count) 
				line_count = 0
		
		
		# Process the end of a column
		if line_count > 0:
			# At the end of a row, if there is a line count left over, then add it to the row text
			if line_text != "":
				# Only add a leading space if there was already something in the row text
				line_text += " "
			line_text += str(line_count)
		elif line_count == 0 and line_text == "":
			# if there was no 1's in that row, add a zero to the row text
			line_text += "0"
		
		solution_line.append(line_text)
		
	output.append(solution_line)
	
	return output

func set_tile(tilemap_coord, tileset_index):
	nonagram_tile_map.set_cellv(tilemap_coord, tileset_index)
	
# Based on the tile coords and mouse input, make a mark on the nonogram tilemap
func handle_tile_input(nonagram_tile_map_coords, button_index):
	
	# Don't try to change a tile that is not in the board
	if not is_in_board(nonagram_tile_map_coords):
		return
	
	var tile = -1
	match (button_index):
		BUTTON_LEFT:
			tile = tiles.Colored
		BUTTON_RIGHT:
			tile = tiles.Crossed
		
		
	# Compare this action with solution tile map to see if it's a correct one
	if solution_tile_map.get_cellv(nonagram_tile_map_coords) == tile and \
	not nonagram_tile_map.get_cellv(nonagram_tile_map_coords) == -1:
		
		# If it is correct, then the tile is removed to reveal the tilemaps underneath it
		nonagram_tile_map.set_cellv(nonagram_tile_map_coords, -1)
		
	elif nonagram_tile_map.get_cellv(nonagram_tile_map_coords) == tile or \
		nonagram_tile_map.get_cellv(nonagram_tile_map_coords) == -1:
		
		# If the tile is already set to what we are trying to color it, then clear it
		nonagram_tile_map.set_cellv(nonagram_tile_map_coords, 0)
		
	else:
		# Set the tile
		nonagram_tile_map.set_cellv(nonagram_tile_map_coords, tile)

# Gets a nonagram_tile_map coordinate and returns whether or not that is in the board
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

# Returns the position of the closest tile that the mouse is pointing at
func get_selected_tile():
	return nonagram_tile_map.world_to_map(nonagram_tile_map.get_local_mouse_position())
	
# Converts world space to tilemap space
func world_to_board(pos: Vector2):
	return nonagram_tile_map.world_to_map(pos)
