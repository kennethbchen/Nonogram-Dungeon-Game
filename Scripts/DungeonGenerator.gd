extends Node2D

"""
Each floor is broken into different rooms of x by x size
"""

onready var dungeon_tile_map = $"/root/Main Scene/Tilemaps/WorldTileMap"

var rand = RandomNumberGenerator.new()

# The max size of a room measured in individual tiles
var room_columns = Util.room_columns
var room_rows = Util.room_rows

# The max size of a dungeon floor measured in individual tiles
var max_floor_columns = Util.max_floor_columns
var max_floor_rows = Util.max_floor_rows

# The maximum amount of rooms allowed in the horizontal or vertical direction
var max_rooms_x = Util.max_rooms_x
var max_rooms_y = Util.max_rooms_y

var subdivision_data = []

func generate_board():
	
	rand.randomize()
	
	dungeon_tile_map.clear()
	
	# Fill in the board with walls
	for col in range(0, max_floor_columns):
		for row in range(0, max_floor_rows):
			pass
			#dungeon_tile_map.set_cellv(Vector2(col, row), Util.world_wall)
	
	# http://roguebasin.com/index.php/Basic_BSP_Dungeon_generation

	
	var bound = Rect2(Vector2(0,0), Vector2(max_rooms_x, max_rooms_y))
	
	var subdivisions = 4
	
	var temp = []
	var buffer = []
	
	temp.append(bound)
	while subdivisions > 0:
		
		if temp.size() > 0:
			# Divisions go into the buffer until all of the areas have been subdivided once
			buffer.append_array(subdivide_area(temp.pop_front()))
		else:
			subdivisions -= 1
			temp.append_array(buffer)
			buffer.clear()
	
	subdivision_data = temp
	
	print(subdivision_data)

# Takes a Rect2 area and randomly divides it in half horizontally or vertically and returns the subdivided pieces
# Individual Rect2 units (position or height / width units) represent rooms in the floor
func subdivide_area(bounds: Rect2):
	
	if bounds.size <= Vector2(1,1):
		# Bounds are too small to divide
		return [bounds]
	
	# 0 - Dividing line is horizontal
	# 1 - Dividing line is vertical
	var split_direction = -1
	
	# Determine the direction to split the bounds in
	if bounds.size.y <= 1:
		# If the width of the bound is too small to be divided,
		# Then the split direction must be vertical
		split_direction = 1
	elif bounds.size.x <= 1:

		# If the height of the board is too small to be divided,
		# Then the split direction must be horizontal
		split_direction = 0
	else:
		split_direction = rand.randi_range(0,1)
	
	# When the board is split, it divides it into an a section and a b section
	# If the dividing line is horizontal, then a is the upper subdivision and b is the lower
	# If the dividing line is vertical, then a is the left subdivision and b is the right
	var a = null
	var b = null
	
	var split_position = 0
	
	if split_direction == 0:
		# Horizontal line, choose vertical position for that line
		
		split_position = rand.randi_range(min(bounds.size.y - 1, bounds.position.y + 1), max(bounds.size.y - 1, 1))
		
		# Assign subdivision sections
		a = Rect2(bounds.position, Vector2(bounds.size.x, bounds.size.y - (bounds.size.y - split_position) ))
		b = Rect2(Vector2(bounds.position.x, bounds.position.y + split_position), Vector2(bounds.size.x, bounds.size.y - split_position))
		
		
	elif split_direction == 1:
		# Vertical line, choose horizontal position for that line
		
		split_position = rand.randi_range(min(bounds.size.x - 1, bounds.position.x + 1), max(bounds.size.x - 1, 1))
		
		# Assign subdivision sections
		a = Rect2(bounds.position, Vector2(bounds.size.x - (bounds.size.x - split_position), bounds.size.y))
		b = Rect2(Vector2(bounds.position.x + split_position, bounds.position.y), Vector2(bounds.size.x - split_position, bounds.size.y))
		
		
	return [a,b]

func _draw():
	
	if subdivision_data.size() > 0:
		
		for i in range(0, subdivision_data.size()):
			var newRect = Rect2(subdivision_data[i].position * Util.tile_size * 8, subdivision_data[i].size * Util.tile_size * 8)
			
			draw_rect(newRect, Color.from_hsv(rand.randf_range(0,1), 1,1))
	
	# Draw the dividing lines between rooms
	for room_col in range(0, max_rooms_x + 1):
		draw_line(Vector2(room_col * room_columns, 0 ) * Util.tile_size, Vector2(room_col * room_columns, max_floor_rows) * Util.tile_size, Color.aqua)
	
	for room_row in range(0, max_rooms_y + 1):
		draw_line(Vector2(0, room_row * room_rows) * Util.tile_size, Vector2(max_floor_columns, room_row * room_rows) * Util.tile_size, Color.aqua)
	
	
	
	
