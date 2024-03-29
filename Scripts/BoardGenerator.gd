extends Node2D

"""
Handles creation of the floors
"""
# Tilemap that represents the nonogram board
# Correctly marked tiles on the board will hide to reveal the WorldTileMap
export(NodePath) onready var nonogram_tilemap = $"../../Tilemaps/NonogramTileMap"

# Tilemap that represents the solution of the nonogram board
# with proper coloring or marking out
export(NodePath) onready var solution_tilemap = $"../../Tilemaps/SolutionTileMap"

export(NodePath) onready var dungeon_tilemap = $"../../Tilemaps/WorldTileMap"

export(NodePath) onready var pathfinder = $"../../PathfindingController"

# Node containing all enemies
export(NodePath) onready var enemies_node = $"../../Enemies"

# Node containing all entities
export(NodePath) onready var entities_node = $"../../Entities"

onready var player = $"../../Player"

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

onready var raycast = $RayCast2D

# The solution to the current nonogram
# It's assumed that the solution is at least rectangular, if not square
var solution = []

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
	
	# Fills the nonogram tilemap and the solution tilemap with appropriate tiles
	for col in max_floor_columns:
		
		for row in max_floor_rows:
			
			# Set the nonogram tilemap to a blank tile
			nonogram_tilemap.set_cell(col, row, 0)
			
			# Set the corresponding solution for the SolutionTileMap based on solution
			# index is needed because of a bad translation between solution value (0 = not colored, 1 = colored)
			# and tilemap id value (1 = not colored, 2 = colored)
			var index
			if solution[col][row] == 0:
				index = Util.nono_color
			else:
				index = Util.nono_cross
				
			solution_tilemap.set_cell(col, row, index)
			
	# ------------ Generate Dungeon Board ------------
	
	var entrypoints = _generate_dungeon()
	player.position = dungeon_tilemap.map_to_world(entrypoints[0]) + Util.tile_offset
	
	# Place stairs
	var stairs = stairs_entity.instance()
	stairs.position = dungeon_tilemap.map_to_world(entrypoints[1]) + Util.tile_offset
	entities_node.add_child(stairs)
	
	# Update the pathfinder
	pathfinder.calculate_paths(max_floor_rows, max_floor_columns)
	
	return entrypoints

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
	func rand_in_room(grow = 0):
		
		if not has_room():
			return null
		
		# Modify the room area by growing it the specified amount
		var m_room = get_room_area().grow(grow)
		
		# Rect2.end appears to be one larger in both dimensions than I expect
		# I think this is because the position is expected to be a top left point and
		# the end is supposed to be a bottom left point
		# Adjust for this by subtracting 1 from each end dimension
		return Vector2(rng.randi_range(m_room.position.x, m_room.end.x - 1), rng.randi_range(m_room.position.y, m_room.end.y - 1))
		
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
	
	var used_tiles = [start_position, end_position]
	
	# Go through all of the rooms and put things in random places
	for i in range(0, rooms.size()):
		

		# Put n things in each rooms
		for iteration in range(0, 2):
			
			var object
			
			# Choose between a good or hazardous thing
			if rng.randf_range(0,1) < 0.6:
				# Good thing
				# Choose between health or energy item
				# TODO: Generalize system with loot tables?
				
				# 50 / 50 chance of health or energy
				if rng.randi_range(0,1) == 0:
					# Health
					object = health_entity
				else:
					# Energy
					object = energy_entity
			else:
				# Hazardous thing
				
				# 60 / 40 chance of trap / enemy
				# Don't spawn enemies in the starting room
				if rng.randf_range(0, 1) < 0.6 or rooms[i] == start_room:
					object = trap_entity
				else:
					object = enemy_entity
			
			var position = rooms[i].rand_in_room()
			# Select a random position in the room that doesn't have something already
			while(used_tiles.has(position)):
				position = rooms[i].rand_in_room()
				
			used_tiles.append(position)
			
			var new_obj = object.instance()
			
			new_obj.position = dungeon_tilemap.map_to_world(position) + Util.tile_offset
			
			if object == enemy_entity:
				new_obj.init(player)
				enemies_node.add_child(new_obj)
			else:
				entities_node.add_child(new_obj)
		
	

	
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
	
#	if subdivision_data != null:
#		#_draw_rec(subdivision_data, 0)
#		pass
#
#	# Draw the dividing lines between rooms
#	for room_col in range(0, max_rooms_x + 1):
#		draw_line(Vector2(room_col * room_columns, 0 ) * Util.tile_size, Vector2(room_col * room_columns, max_floor_rows) * Util.tile_size, Color.aqua)
#
#	for room_row in range(0, max_rooms_y + 1):
#
#		draw_line(Vector2(0, room_row * room_rows) * Util.tile_size, Vector2(max_floor_columns, room_row * room_rows) * Util.tile_size, Color.aqua)
	pass
