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

var max_subdivisions = 4

var subdivision_data = null


# Class that represents 
class MapRegion:
	
	var bounds: Rect2
	var parent: MapRegion
	var children: Array
	var id: int
	
	func _init(rect, new_parent = null):
		bounds = rect
		
		if new_parent != null:
			parent = new_parent
		
	func add_child(new_child: MapRegion):
		children.append(new_child)
		
	func add_children(new_children: Array):
		children.append_array(new_children)
		pass

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
	
	var root = MapRegion.new(Rect2(Vector2(0,0), Vector2(max_rooms_x, max_rooms_y)))
	root.id = 0
	
	var current = [root]
	
	var subdivisions = max_subdivisions
	
	subdivide_area(root, max_subdivisions)
	
	
	subdivision_data = root


# Takes a MapRegion area and randomly divides it in half horizontally or vertically and returns the subdivided pieces
# Individual Rect2 units (position or height / width units) represent rooms in the floor
func subdivide_area(region: MapRegion, subdivisions):
	
	
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
		split_direction = rand.randi_range(0,1)
	
	# When the board is split, it divides it into an a section and a b section
	# If the dividing line is horizontal, then a is the upper subdivision and b is the lower
	# If the dividing line is vertical, then a is the left subdivision and b is the right
	var a: MapRegion = null
	var b: MapRegion = null
	
	var split_position = 0
	
	if split_direction == 0:
		# Horizontal line, choose vertical position for that line
		
		split_position = rand.randi_range(min(region.bounds.size.y - 1, region.bounds.position.y + 1), max(region.bounds.size.y - 1, 1))
		
		# Assign subdivision sections
		a = MapRegion.new(Rect2(region.bounds.position, Vector2(region.bounds.size.x, region.bounds.size.y - (region.bounds.size.y - split_position) )))
		b = MapRegion.new(Rect2(Vector2(region.bounds.position.x, region.bounds.position.y + split_position), Vector2(region.bounds.size.x, region.bounds.size.y - split_position)))
		
		
	elif split_direction == 1:
		# Vertical line, choose horizontal position for that line
		
		split_position = rand.randi_range(min(region.bounds.size.x - 1, region.bounds.position.x + 1), max(region.bounds.size.x - 1, 1))
		
		# Assign subdivision sections
		a = MapRegion.new(Rect2(region.bounds.position, Vector2(region.bounds.size.x - (region.bounds.size.x - split_position), region.bounds.size.y)))
		b = MapRegion.new(Rect2(Vector2(region.bounds.position.x + split_position, region.bounds.position.y), Vector2(region.bounds.size.x - split_position, region.bounds.size.y)))
	
	region.add_child(a)
	region.add_child(b)
	
	a.parent = region
	b.parent = region
	
	subdivide_area(a, subdivisions - 1)
	subdivide_area(b, subdivisions - 1)
	
func _draw_rec(region: MapRegion, offset):
	
	var new_rect = Rect2(region.bounds.position * Util.tile_size * 8, region.bounds.size * Util.tile_size * 8)
	var color = Color.white
	color.g -= 0.2 * offset
	draw_rect(new_rect.grow(-offset * 8), color, false, 2 * offset)
	
	for i in range(0, region.children.size()):
		_draw_rec(region.children[i], offset + 1)

func _draw():
	
	if subdivision_data != null:
		_draw_rec(subdivision_data, 0)

	# Draw the dividing lines between rooms
	for room_col in range(0, max_rooms_x + 1):
		draw_line(Vector2(room_col * room_columns, 0 ) * Util.tile_size, Vector2(room_col * room_columns, max_floor_rows) * Util.tile_size, Color.aqua)

	for room_row in range(0, max_rooms_y + 1):
		draw_line(Vector2(0, room_row * room_rows) * Util.tile_size, Vector2(max_floor_columns, room_row * room_rows) * Util.tile_size, Color.aqua)

	
	
	
