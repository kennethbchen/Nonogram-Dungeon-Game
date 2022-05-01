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

var max_subdivisions = 5

# Subdivision Data purely for drawing debug graphics to the screen
var subdivision_data = null


# Array of MapRegions that contain a room
var room_regions = []

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
		

func generate_board():
	
	rand.randomize()
	
	dungeon_tile_map.clear()
	room_regions = []
	
	for col in range(0, max_floor_columns):
		for row in range(0, max_floor_rows):
			
			var point = Vector2(col, row)
			# Fill in the board with walls
			dungeon_tile_map.set_cellv(point, Util.world_wall)
	
	# http://roguebasin.com/index.php/Basic_BSP_Dungeon_generation
	
	var root = MapRegion.new(Rect2(Vector2(0,0), Vector2(max_rooms_x, max_rooms_y)))

	
	var subdivisions = max_subdivisions
	
		
	subdivide_area(root, max_subdivisions)
	generate_rooms(root)
	
	var entrypoints = place_entities(room_regions)

	for i in range(0, room_regions.size()):
		#print(room_regions[i].get_room_area().position)
		pass
	subdivision_data = root
	
	return entrypoints

# Places entities in the room_regions
# Returns an array where
# Index 0 is the player's starting position
# Index 1 is the exit
func place_entities(rooms):
	
	# Pick a random room to be the starting room
	var start_room = rooms[rand.randi_range(0, rooms.size() - 1)]
	
	# The end room is a randrom room that is not the start room
	var end_room
	while end_room == null or end_room == start_room:
		end_room = rooms[rand.randi_range(0, rooms.size() - 1)]
	
	
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
	var room_width = rand.randi_range((tile_bounds.size.x / 2) + 1, tile_bounds.size.x)
	var room_height = rand.randi_range((tile_bounds.size.y / 2) + 1, tile_bounds.size.y)
	
	# The position of the room is in random places where it fits given the size
	var room_x = rand.randi_range(0, tile_bounds.size.x - room_width)
	var room_y = rand.randi_range(0, tile_bounds.size.y - room_height)
	
	var room_bounds = Rect2(tile_bounds.position + Vector2(room_x, room_y), Vector2(room_width, room_height))
	
	
	var room_inside = room_bounds.grow(-1)
	
	for col in range(room_bounds.position.x, room_bounds.end.x):

		for row in range(room_bounds.position.y, room_bounds.end.y):
			
			var pos = Vector2(col, row)
			
			# Carve out the room
			if room_inside.has_point(pos):
				dungeon_tile_map.set_cellv(pos, -1)
			
	
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
	var point_1 = Vector2(rand.randi_range(inner_a.position.x, inner_a.end.x), rand.randi_range(inner_a.position.y, inner_a.end.y))
	var point_2 = Vector2(rand.randi_range(inner_b.position.x, inner_b.end.x), rand.randi_range(inner_b.position.y, inner_b.end.y))
	

	
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
		
		dungeon_tile_map.set_cellv(Vector2(x,y), -1)
		pass

# Takes a region in tilemap coordinates and draws walls in that area
func draw_rectangle(region: Rect2):
	
	for col in range(region.position.x, region.end.x):
		for row in range(region.position.y, region.end.y):
			dungeon_tile_map.set_cellv(Vector2(col, row), Util.nono_blank)

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

	
	
	
