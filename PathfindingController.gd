extends Node

#https://youtu.be/dVNH6mIDksQ

class_name PathfindingController

onready var world_tilemap = $"../Tilemaps/WorldTileMap"

# Node containing all of the entities
onready var entities = $"../Entities"
onready var entity_positions = []
# The used cells in the world tilemap
# Includes valid and invalid nodes for pathing
onready var used_cells = world_tilemap.get_used_cells()

var astar = AStar2D.new()

func _ready():
	
	_load_entities()
	
	_load_points()
	
	_load_connections()
	
	
	
	var path = get_tile_path(Vector2(6,0), (Vector2(0, 3)))
	
		
	
# Go though all of the entities and compute a list of their positions (tilemap-space)
func _load_entities():
	
	for entity in entities.get_children():
		entity_positions.append(world_tilemap.world_to_map(entity.position))
		pass

func _load_points():
	# Read through the tilemap and add valid pathing nodes to astar
	for tile in used_cells:
		# If the tile has an entity on it, then don't add it as a valid point
		if entity_positions.has(tile):
			continue
		elif world_tilemap.get_cellv(tile) == Util.nono_empty:
			astar.add_point(_id(tile), tile, 1)
		else:
			pass

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
				
	pass

# Cantor Pairing Function to map 2D tilemap space to 1D ID space
func _id(point: Vector2):
	var a = point.x
	var b = point.y
	return (a + b) * (a + b + 1) / 2 + b
	
func get_tile_path(start: Vector2, goal: Vector2):
	var path = astar.get_point_path(_id(start), _id(goal))
	print (path)
	return path
