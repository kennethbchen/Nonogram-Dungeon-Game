extends Node2D

"""
Handles creation of the floors
"""
# Tilemap that represents the nonogram board
# Correctly marked tiles on the board will hide to reveal the WorldTileMap
onready var nonogram_tilemap = $"/root/Main Scene/Tilemaps/NonogramTileMap"

# Tilemap that represents the solution of the nonogram board
# with proper coloring or marking out
onready var solution_tilemap = $"/root/Main Scene/Tilemaps/SolutionTileMap"

onready var dungeon_tilemap = $"/root/Main Scene/Tilemaps/WorldTileMap"

onready var pathfinder = $"../../PathfindingController"

onready var hint_font = load("res://UI/NonogramHint.tres")

# Tilemap containing all possible dungeon boards
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

# Use Open Simplex Noise to generate random picross boards
var noise = OpenSimplexNoise.new()

# The solution to the current nonogram
# It's assumed that the solution is at least rectangular, if not square
var solution = []

# The hints of the current board that are displayed
var hint = []

# Array of label nodes that display the hints
# The format of the labels is the same as the hint array
var hint_labels = []

# The max size of a dungeon floor measured in individual tiles
var max_floor_columns = Util.max_floor_columns
var max_floor_rows = Util.max_floor_rows

# The max size of a room measured in individual tiles
var room_columns = Util.room_columns
var room_rows = Util.room_rows

# The maximum amount of rooms allowed in the horizontal or vertical direction
# For example, each floor is a collection of x by y rooms
var max_rooms_x = Util.max_rooms_x
var max_rooms_y = Util.max_rooms_y

var tile_size = Util.tile_size

# Amount of subdivisions that the board generator will perform
var max_subdivisions = 5

# Subdivision Data purely for drawing debug graphics to the screen
var subdivision_data = null

# Array of MapRegions that contain a room
var room_regions = []

# Generates the nonogram board and solution based on the input data
# Generates the dungeon board procedurally
func generate_board():
	
	# ------------ Setup ------------
	rng.randomize()
	
	# Configure noise generator for nonogram board generation
	noise.seed = rng.randi()
	noise.octaves = 8
	noise.period = 3.2
	noise.persistence = 0.4
	
	# Clear boards
	nonogram_tilemap.clear()
	dungeon_tilemap.clear()
	solution_tilemap.clear()
	
	# Clear all enemies
	for child in get_tree().get_nodes_in_group("enemy"):
		child.free()
	
	# Also clear all entities
	for child in get_tree().get_nodes_in_group("entity"):
		child.free()
	
	# ------------ Generate Nonogram Board ------------
	solution = _generate_nonogram_board(Util.max_floor_columns, Util.max_floor_rows)
	
	# Generate the hint to display based on the solution of the board
	hint = _generate_hint(solution)

	hint_labels = create_labels(hint, hint_labels)
	
	# Fills the nonogram tilemap and the solution tilemap with appropriate tiles
	for col in max_floor_columns:
		
		for row in max_floor_rows:
			
			# Set the nonogram tilemap to a blank tile
			nonogram_tilemap.set_cell(col, row, 0)
			
			# Set the corresponding solution for the SolutionTileMap based on solution
			# index is needed because of a bad translation between solution value (0 = not colored, 1 = colored)
			# and tilemap id value (1 = not colored, 2 = colored)
			var index
			if solution[row][col] == 0:
				index = Util.nono_color
			else:
				index = Util.nono_cross
				
			solution_tilemap.set_cell(col, row, index)
			
	# ------------ Generate Dungeon Board ------------
	var entrypoints = _generate_dungeon()
	player.position = dungeon_tilemap.map_to_world(entrypoints[0]) + Util.tile_offset
	

	# Update the pathfinder
	pathfinder.calculate_paths(max_floor_rows, max_floor_columns)
	
	return entrypoints
			
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
		label.set_position(nonogram_tilemap.get_global_position() - Vector2(-nonogram_tilemap.map_to_world(Vector2(col_id, 0))[0], 64))
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
		label.set_position(nonogram_tilemap.get_global_position() - Vector2(66, -nonogram_tilemap.map_to_world(Vector2(0,row_id))[1]))
		label.add_font_override("font", hint_font)
		label.align = HALIGN_RIGHT
		label.valign = VALIGN_BOTTOM
		
		# hint[1] is the hints for the left side
		label.text = str(hint[1][row_id])
		add_child(label)
		
		line.append(label)
	output.append(line)
	
	return output

# Generates a random nonogram board using a noise texture
func _generate_nonogram_board(max_floor_columns, max_floor_rows):
	
	var output = []
	
	var row_data = []
	for col in range(0, max_floor_columns):
		
		row_data = []
		for row in range(0, max_floor_rows):
			
			# The noise determines the value of that cell in the solution
			var val = noise.get_noise_2d(col,row)
			
			
			if val >= 0 - 0.02:
				row_data.append(1)
			else:
				row_data.append(0)
			
		output.append(row_data)
		#print(row_data)
	
	
	
	return output

# Class that represents a region of the map which may or may not contain a room
class MapRegion:
	
	# The bounds of the region in room coordinates
	var bounds: Rect2
	
	# The bounds of the room within this region in tilemap coordinates
	# Only leaf nodes have rooms
	var room_bounds: Rect2
	
	var parent: MapRegion
	
	var child_a: MapRegion = null
	var child_b: MapRegion = null
	
	# TODO, is there a better way to do this without giving every node a RNG?
	var rng = RandomNumberGenerator.new()
	
	
	func _init(rect, new_parent = null):
		
		rng.randomize()
		
		bounds = rect
		
		if new_parent != null:
			parent = new_parent
	
	# Gets the bounds of the region in tilemap coordinates
	func get_tile_bounds():
		return Rect2(bounds.position * Vector2(Util.room_columns, Util.room_rows), bounds.size * Vector2(Util.room_columns, Util.room_rows))
	
	# The inner room bounds is simply the room bounds but shrunk 1 unit on each side
	func get_room_area():
		if not has_room():
			return null
			
		return room_bounds.grow(-1)
	
	func has_room():
		if room_bounds == null or room_bounds == Rect2(0,0,0,0):
			return false
		else:
			return true
	
	# Returns a Vector2 representing a random point within the inner room bounds of the room
	func rand_in_room():
		
		if not has_room():
			return null
		
		# Rect2.end appears to be one larger in both dimensions than I expect
		# I think this is because the position is expected to be a top left point and
		# the end is supposed to be a bottom left point
		# Adjust for this by subtracting 1 from each end dimension
		print([get_room_area().position.x, get_room_area().end.x - 1])
		return Vector2(rng.randi_range(get_room_area().position.x, get_room_area().end.x - 1), rng.randi_range(get_room_area().position.y, get_room_area().end.y - 1))
		
	# If this region has a room (room_bound), then return it
	# Otherwise, go through the children until you get to a room
	# https://gamedevelopment.tutsplus.com/tutorials/how-to-use-bsp-trees-to-generate-game-maps--gamedev-12268
	func get_room_in_children():
		
		
		if has_room():
			return room_bounds
			
		var a = null
		var b = null
		
		if child_a != null:
			a = child_a.get_room_in_children()
		
		if child_b != null:
			b = child_b.get_room_in_children()
			
		if a == null and b == null:
			return null
		elif a == null:
			return b
		elif b == null:
			return a
		elif rng.randi_range(0,1) == 0:
			return a
		else:
			return b
		
# Generate a dungeon based on BSP
# http://roguebasin.com/index.php/Basic_BSP_Dungeon_generation
func _generate_dungeon():

	room_regions = []
	
	# Fill the dungeon tilemap with walls
	for col in range(0, max_floor_columns):
		for row in range(0, max_floor_rows):
			var point = Vector2(col, row)
			
			dungeon_tilemap.set_cellv(point, Util.world_wall)
	
	var root = MapRegion.new(Rect2(Vector2(0,0), Vector2(max_rooms_x, max_rooms_y)))
	
	subdivide_area(root, max_subdivisions)
	generate_rooms(root)
	
	var entrypoints = place_entities(room_regions)

	subdivision_data = root
	
	return entrypoints

# Places entities in the room_regions
# Returns an array where
# Index 0 is the player's starting position
# Index 1 is the exit
func place_entities(rooms):
	
	# Pick a random room to be the starting room
	var start_room = rooms[rng.randi_range(0, rooms.size() - 1)]
	
	# The end room is a randrom room that is not the start room
	var end_room
	while end_room == null or end_room == start_room:
		end_room = rooms[rng.randi_range(0, rooms.size() - 1)]
	
	
	var start_position = start_room.rand_in_room()
	var end_position = end_room.rand_in_room()
	print(start_position)
	return [start_position, end_position]

# Recursive Function
# Takes a root node and connects its children together
func generate_rooms(root: MapRegion):
	
	if root.child_a != null or root.child_b != null:
		
		if root.child_a != null:
			generate_rooms(root.child_a)
		
		if root.child_b != null:
			generate_rooms(root.child_b)
		
		if root.child_a != null and root.child_b != null:
				
			create_hall(root.child_a.get_room_in_children(), root.child_b.get_room_in_children())
	else:
		create_room(root)
		
		# Add this region to the list of all MapRegions with rooms
		room_regions.append(root)

# Takes a Map Region and randomly carves out (creates empty space) a room of random size and position
# that is within the bounds of that region
# The room is carved out and its bounds is stored within the given map region
func create_room(region: MapRegion):
	
	# The bounds of the region in tilemap units
	# The multiplication by Util stuff is transforming the region variable's map_region units to tilemap units
	var tile_bounds = region.get_tile_bounds()
	
	# The room is a random size withing the bounds of the region
	var room_width = rng.randi_range((tile_bounds.size.x / 2) + 1, tile_bounds.size.x)
	var room_height = rng.randi_range((tile_bounds.size.y / 2) + 1, tile_bounds.size.y)
	
	# The position of the room is in random places where it fits given the size
	var room_x = rng.randi_range(0, tile_bounds.size.x - room_width)
	var room_y = rng.randi_range(0, tile_bounds.size.y - room_height)
	
	var room_bounds = Rect2(tile_bounds.position + Vector2(room_x, room_y), Vector2(room_width, room_height))
	
	var room_inside = room_bounds.grow(-1)
	
	for col in range(room_bounds.position.x, room_bounds.end.x):

		for row in range(room_bounds.position.y, room_bounds.end.y):
			
			var pos = Vector2(col, row)
			
			# Carve out the room
			if room_inside.has_point(pos):
				dungeon_tilemap.set_cellv(pos, -1)
			
	
	# The resulting room is also stored in the region's room_bounds variable
	region.room_bounds = room_bounds
	
# Takes two regions and connects their rooms together
func create_hall(regionA: Rect2, regionB: Rect2):
	# Both regions must have rooms within them
	if regionA == null or regionB == null:
		
		return
	
	var inner_a = regionA.grow(-2)
	var inner_b = regionB.grow(-2)
	# pick one random point inside each room
	var point_1 = Vector2(rng.randi_range(inner_a.position.x, inner_a.end.x), rng.randi_range(inner_a.position.y, inner_a.end.y))
	var point_2 = Vector2(rng.randi_range(inner_b.position.x, inner_b.end.x), rng.randi_range(inner_b.position.y, inner_b.end.y))
	
	var x = point_1.x
	var y = point_1.y
	
	# https://bfnightly.bracketproductions.com/chapter_25.html
	# Draw straight hallways with one bend
	while x != point_2.x or y != point_2.y:
		
		if x < point_2.x:
			x += 1
		elif x > point_2.x:
			x -= 1
		elif y < point_2.y:
			y += 1
		elif y > point_2.y:
			y -= 1
		
		dungeon_tilemap.set_cellv(Vector2(x,y), -1)
		pass

# Takes a MapRegion area and randomly divides it in half horizontally or vertically and returns the subdivided pieces
# Individual Rect2 units (position or height / width units) represent rooms in the floor
func subdivide_area(region: MapRegion, subdivisions):
	
	# Don't subdivide anymore
	if subdivisions == 0:
		return
		
	if region.bounds.size <= Vector2(1,1):
		# Bounds are too small to divide
		return [region]
	
	# 0 - Dividing line is horizontal
	# 1 - Dividing line is vertical
	var split_direction = -1
	
	# Determine the direction to split the bounds in
	if region.bounds.size.y <= 1:
		# If the width of the bound is too small to be divided,
		# Then the split direction must be vertical
		split_direction = 1
	elif region.bounds.size.x <= 1:

		# If the height of the board is too small to be divided,
		# Then the split direction must be horizontal
		split_direction = 0
	else:
		split_direction = rng.randi_range(0,1)
	
	# When the board is split, it divides it into an a section and a b section
	# If the dividing line is horizontal, then a is the upper subdivision and b is the lower
	# If the dividing line is vertical, then a is the left subdivision and b is the right
	var a: MapRegion = null
	var b: MapRegion = null
	
	# Vertical / Horizontal position of the subdivision, depending on split_direction
	var split_position = 0
	
	if split_direction == 0:
		# Horizontal line, choose vertical position for that line
		
		split_position = rng.randi_range(min(region.bounds.size.y - 1, region.bounds.position.y + 1), max(region.bounds.size.y - 1, 1))
		
		# Assign subdivision sections
		a = MapRegion.new(Rect2(region.bounds.position, Vector2(region.bounds.size.x, region.bounds.size.y - (region.bounds.size.y - split_position) )))
		b = MapRegion.new(Rect2(Vector2(region.bounds.position.x, region.bounds.position.y + split_position), Vector2(region.bounds.size.x, region.bounds.size.y - split_position)))
		
		
	elif split_direction == 1:
		# Vertical line, choose horizontal position for that line
		
		split_position = rng.randi_range(min(region.bounds.size.x - 1, region.bounds.position.x + 1), max(region.bounds.size.x - 1, 1))
		
		# Assign subdivision sections
		a = MapRegion.new(Rect2(region.bounds.position, Vector2(region.bounds.size.x - (region.bounds.size.x - split_position), region.bounds.size.y)))
		b = MapRegion.new(Rect2(Vector2(region.bounds.position.x + split_position, region.bounds.position.y), Vector2(region.bounds.size.x - split_position, region.bounds.size.y)))
	
	region.child_a = a
	region.child_b = b
	
	a.parent = region
	b.parent = region
	
	subdivide_area(a, subdivisions - 1)
	subdivide_area(b, subdivisions - 1)

func _draw_rec(region: MapRegion, offset):
	
	# The multiplication by Util stuff is transforming it from map region room units to tilemap units and from tilemap units to pixel units
	var new_rect = Rect2(region.bounds.position * Vector2(Util.room_columns, Util.room_rows) * Util.tile_size, 
						 region.bounds.size * Vector2(Util.room_columns, Util.room_rows) * Util.tile_size )
	var color = Color.white
	color.g -= 0.2 * offset
	draw_rect(new_rect.grow(-offset * 8), color, false, 2 * offset)
	
	if region.child_a != null:
		_draw_rec(region.child_a, offset + 1)
		
	if region.child_b != null:
		_draw_rec(region.child_b, offset + 1)

func _draw():
	
	if subdivision_data != null:
		#_draw_rec(subdivision_data, 0)
		pass

	# Draw the dividing lines between rooms
	for room_col in range(0, max_rooms_x + 1):
		draw_line(Vector2(room_col * room_columns, 0 ) * Util.tile_size, Vector2(room_col * room_columns, max_floor_rows) * Util.tile_size, Color.aqua)

	for room_row in range(0, max_rooms_y + 1):
		
		draw_line(Vector2(0, room_row * room_rows) * Util.tile_size, Vector2(max_floor_columns, room_row * room_rows) * Util.tile_size, Color.aqua)
