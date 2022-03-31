"""
Controls and handles pathfinding calculations for other objects
"""
extends Node

# https://youtu.be/dVNH6mIDksQ

class_name PathfindingController

onready var world_tilemap = $"../Tilemaps/WorldTileMap"

onready var entity_positions = []

# The used cells in the world tilemap
# Includes valid and invalid nodes for pathing
onready var used_cells = world_tilemap.get_used_cells()

var astar

# For debugging
onready var astar_visualizer = $"../AStarVisualizer"

func _ready():
	astar = AStar2D.new()

func calculate_paths(rows, columns):
	
	astar.clear()
	
	_load_entities()
	_load_points(rows, columns)
	_load_connections()
	
	astar_visualizer.offset = Vector2(8,8)
	astar_visualizer.visualize(astar)
	
# Go though all of the entities and compute a list of their positions (tilemap-space)
func _load_entities():
	
	entity_positions = []
	
	for entity in get_tree().get_nodes_in_group("entity"):
		entity_positions.append(world_tilemap.world_to_map(entity.position))
		entity.connect("tile_free", self, "_on_tile_free")

func _load_points(rows, columns):
	# Read through the tilemap and add valid pathing nodes to astar
	for row in range(0, rows):
		for col in range(0, columns):
			var coord = Vector2(col, row)
			var tile_id = world_tilemap.get_cellv(coord)
			if tile_id == Util.nono_empty or tile_id == -1:
				# TODO: Valid path detection system that doesn't require a blank tile
				
				astar.add_point(_id(coord), coord, 1)
			
			if entity_positions.has(coord):
				# If the tile has an entity on it, then don't add it as a valid point
				astar.set_point_disabled(_id(coord))
				continue

func _load_connections():
	# Go through all of the points in astar and make connections between them
	for point_id in astar.get_points():
		# Check each neighboring cell for each cell
		# Right Left Up Down
		var neighbors = [Vector2(1,0), Vector2(-1,0), Vector2(0,-1), Vector2(0,1)]
		
		for neighbor in neighbors:
			
			var next = astar.get_point_position(point_id) + neighbor
			
			# Connect points if they exist
			if astar.has_point(_id(next)) and next.x >= 0 and next.y >= 0:
				# Make sure next coordinates are only positive because
				# the Cantor Pairing Function only maps one to one for positive integers
				astar.connect_points(point_id, _id(next), true)

# Cantor Pairing Function to map 2D tilemap space to 1D ID space
func _id(point: Vector2):
	var a = point.x
	var b = point.y
	return (a + b) * (a + b + 1) / 2 + b

# The returned path is in terms of relative vector direction movements
func get_tile_path(start: Vector2, goal: Vector2):
	var output = []
	
	# Get the path
	var path = astar.get_point_path(_id(start), _id(goal))
	
	# Calculate relative movement
	for i in range(0, path.size() - 1):
		output.append(path[i+1] - path[i])

	return output

# Checks if the tile is in the list of points and not disabled
func is_valid_tile(tile: Vector2):
	var tile_id = _id(tile)
	return astar.has_point(tile_id) and not astar.is_point_disabled(tile_id)

func _on_tile_free(entity):
	astar.set_point_disabled(_id(world_tilemap.world_to_map(entity.position)), false)
	
	astar_visualizer.visualize(astar)
	
