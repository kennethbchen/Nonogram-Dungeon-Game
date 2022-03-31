extends Node

"""
Handles creation of the game boards
"""
# Tilemap that represents the nonogram board
# Correctly marked tiles on the board will hide to reveal the WorldTileMap
onready var nonogram_tile_map = $"/root/Main Scene/Tilemaps/NonogramTileMap"

# Tilemap that represents the solution of the nonogram board
# with proper coloring or marking out
onready var solution_tile_map = $"/root/Main Scene/Tilemaps/SolutionTileMap"

onready var world_tile_map = $"/root/Main Scene/Tilemaps/WorldTileMap"

onready var pathfinder = $"../../PathfindingController"

onready var hint_font = load("res://UI/NonogramHint.tres")

# Tilemap containing all possible nonogram / dungeon boards
onready var nonogram_layouts = $"/root/Main Scene/Tilemaps/NonogramBoards"
onready var dungeon_layouts = $"/root/Main Scene/Tilemaps/DungeonBoards"

# Node containing all enemies
onready var enemies_node = $"/root/Main Scene/Enemies"

# Node containing all entities
onready var entities_node = $"/root/Main Scene/Entities"

onready var player = $"/root/Main Scene/Player"

# Entities
onready var health_entity = load("res:///Scenes/Apple.tscn")
onready var energy_entity = load("res:///Scenes/Potion.tscn")
onready var door_entity = load("res:///Scenes/Door.tscn")
onready var enemy_entity = load("res:///Scenes/Enemy.tscn")
onready var stairs_entity = load("res:///Scenes/Stairs.tscn")
onready var trap_entity = load("res:///Scenes/Trap.tscn")



var rng = RandomNumberGenerator.new()




# The solution to the current board
# It's assumed that the solution is at least rectangular, if not square
var solution = []

# The hints of the current board that are displayed
var hint = []

# Array of label nodes that display the hints
# The format of the labels is the same as the hint array
var hint_labels = []

var columns = 8
var rows = 8

var tile_size = 16

# Total number of nonogram / dungeon boards in their respective tilemaps
var nonogram_boards = 8
var dungeon_boards = 8

# The index of the last selected nonogram / dungeon boards
# Used to prevent repeats back to back
var last_nonogram = -1
var last_dungeon = -1

# Generates the nonogram board and solution based on the input data
# The World layer of the board is within the world_tilemap itself
# Returns an array indicating the size of the newly generated board:
# array[0] = number of columns
# array[1] = number of rows
func generate_board():
	rng.randomize()
	# Clear boards first
	nonogram_tile_map.clear()
	world_tile_map.clear()
	solution_tile_map.clear()
	
	# Clear all enemies
	for child in get_tree().get_nodes_in_group("enemy"):
		child.free()
	
	# Also clear all entities
	for child in get_tree().get_nodes_in_group("entity"):
		child.free()

	solution = _pickNonogramBoard();
	_pickDungeonBoard()
	
	# Generate the hint to display based on the solution of the board
	hint = _generate_hint(solution)

	hint_labels = create_labels(hint, hint_labels)
	
	# Generate NonogramTileMap tiles based on board dimensions
	for col in columns:
		
		for row in rows:
			
			# Set the nonogram tilemap to a blank tile
			nonogram_tile_map.set_cell(col, row, 0)
			
			# Set the corresponding solution for the SolutionTileMap based on solution
			# index is needed because of a bad translation between solution value (0 = not colored, 1 = colored)
			# and tilemap id value (1 = not colored, 2 = colored)
			var index
			if solution[row][col] == 0:
				index = 1
			else:
				index = 2
				
			solution_tile_map.set_cell(col, row, index)
	
	# Update the pathfinder
	pathfinder.calculate_paths(rows, columns)
	
	return [columns, rows]
			
# Takes a board solution and generates an array that contains the hints for that board
# The returned array is an array[2][x] of strings where:
# In array[0], x is the hints of the columns (top of board) and
# In array[1], x is the hints of the rows (left of board)
# Each individual cell (array[a][b]) is the full hint as a string that should be displayed
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
	for col in range(0, solution[0].size()):
		
		# Reset vars for new column
		line_count = 0
		line_text = ""
		
		for row in range(0, solution.size()):
			if solution[row][col] == 1:
				# If a 1 is found, record it
				line_count += 1
			elif solution[row][col] == 0 and line_count > 0:
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

# TODO: add the labels to an array so they can be reused
# Takes the nonogram board hints and displays that as labels
# The resulting labels are stored in an array in the same format as the hints
# The label_array is the array of labels, if they exist already
# They are used to determine if the labels can be reused or not
# However, it's assumed that in the case of a reuse, the size of the board did not change
func create_labels(hint, label_array):
	
	var output = []
	
	# Stores the entire row / column of labels before they are put in the output array
	var line = []
	
	# If the labels can be reused, don't create new ones
	if label_array.size() != 0:
		for col_id in range (0, hint[0].size()):
			
			label_array[0][col_id].text = hint[0][col_id]
			
		for row_id in range(0, hint[1].size()):
			label_array[1][row_id].text = hint[1][row_id]

		return label_array
	
	# Generate hint for the columns (top side of board)
	for col_id in range(0, hint[0].size()):
		
		var label = Label.new();
		
		# Do some horrible math to generate label for left side of board
		label.set_size(Vector2(16, 64))
		label.set_position(nonogram_tile_map.get_global_position() - Vector2(-nonogram_tile_map.map_to_world(Vector2(col_id, 0))[0], 64))
		label.add_font_override("font", hint_font)
		label.align = HALIGN_CENTER
		label.valign = VALIGN_BOTTOM
		
		label.text = str(hint[0][col_id])
		add_child(label)
		
		line.append(label)
	
	output.append(line)
	line = []
	# Generate hint for the rows (left side of board)
	for row_id in range(0, hint[1].size()):
		
		var label = Label.new();
				
		# Do some horrible math to generate label for left side of board
		label.set_size(Vector2(64, 0))
		label.set_position(nonogram_tile_map.get_global_position() - Vector2(66, -nonogram_tile_map.map_to_world(Vector2(0,row_id))[1]))
		label.add_font_override("font", hint_font)
		label.align = HALIGN_RIGHT
		label.valign = VALIGN_BOTTOM
		
		# hint[1] is the hints for the left side
		label.text = str(hint[1][row_id])
		add_child(label)
		
		line.append(label)
	output.append(line)
	
	return output

# Picks a random nonogram board to generate
func _pickNonogramBoard():
	# Pick a random board
	var rand = rng.randi_range(0, nonogram_boards - 1)
	
	if rand == last_nonogram:
		rand = (rand + 1) % nonogram_boards
		print("reroll nono")
		
	last_nonogram = rand
		
	var start = rand * columns
	
	var output = []
	var line = []
	for row in range(0, rows):
		line = []
		for col in range (0, columns):
			
			# Translate the data to an array where
			# Colored square = 1, else 0
			match (nonogram_layouts.get_cellv(Vector2(col + start, row))):
				Util.indi_colored:
					line.append(1)
				_:
					line.append(0)
				
		output.append(line)
	
	return output

# Picks a random Dungeon board to generate
func _pickDungeonBoard():
	# Pick a random board
	var rand = rng.randi_range(0, dungeon_boards - 1)
	if rand == last_dungeon:
		rand = (rand + 1) % dungeon_boards
		print("reroll dungeon")
	last_dungeon = rand
		
	var start = rand * columns
	
	for row in range(0, rows):
		for col in range (0, columns):
			
			var tile_coord = Vector2(col + start, row)
			var tile_id = dungeon_layouts.get_cellv(tile_coord)
			var tile_offset = Vector2(tile_size / 2, tile_size / 2)
			
			var output_coord = Vector2(col , row)
			
			match (tile_id):
				Util.indi_player:
					player.position = world_tile_map.map_to_world(output_coord) + tile_offset
				Util.indi_health:
					# Pick between spawning a health item or an energy item
					var num = rng.randi_range(0,1)
					print(num)
					var obj
					match(num):
						0:
							obj = health_entity.instance()
						1:
							obj = energy_entity.instance()
					
					obj.position = world_tile_map.map_to_world(output_coord) + tile_offset
					entities_node.add_child(obj)
				Util.indi_door:
					var obj = door_entity.instance()
					obj.position = world_tile_map.map_to_world(output_coord) + tile_offset
					entities_node.add_child(obj)
				Util.indi_stairs:
					var obj = stairs_entity.instance()
					obj.position = world_tile_map.map_to_world(output_coord) + tile_offset
					entities_node.add_child(obj)
				Util.indi_enemy:
					var obj = enemy_entity.instance()
					obj.position = world_tile_map.map_to_world(output_coord) + tile_offset
					enemies_node.add_child(obj)
				Util.indi_trap:
					var obj = trap_entity.instance()
					obj.position = world_tile_map.map_to_world(output_coord) + tile_offset
					entities_node.add_child(obj)
				Util.indi_wall:
					world_tile_map.set_cellv(output_coord, Util.world_wall)	
		

