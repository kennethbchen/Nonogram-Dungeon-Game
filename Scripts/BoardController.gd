"""

Acts as an interface to the game boards to other nodes
Nonogram board -> player input area for nonogram
Solution board -> nonogram solution
World board -> player character world 
"""
extends Node

onready var board_generator = $BoardGenerator

# Tilemap that represents the nonogram board
# Correctly marked tiles on the board will hide to reveal the WorldTileMap
onready var nonogram_tile_map = $"/root/Main Scene/Tilemaps/NonogramTileMap"

# Tilemap that represents the solution of the nonogram board
# with proper coloring or marking out
onready var solution_tile_map = $"/root/Main Scene/Tilemaps/SolutionTileMap"

onready var world_tile_map = $"/root/Main Scene/Tilemaps/WorldTileMap"

onready var hint_font = load("res://Font/NonogramHint.tres")

var columns = 0
var rows = 0

var tile_size = 0

func _ready():
	tile_size = board_generator.tile_size
	
# Generates the nonogram board and solution based on the input data
# The World layer of the board is within the world_tilemap itself
func init_board():
	var data = board_generator.generate_board()
	columns = data[0]
	rows = data[1]
	
	
func set_tile(tilemap_coord, tileset_index):
	nonogram_tile_map.set_cellv(tilemap_coord, tileset_index)
	
# Based on the tile coords and mouse input, make a mark on the nonogram tilemap
func handle_tile_input(nonogram_tile_map_coords, button_index):
	
	# Don't try to change a tile that is not in the board
	if not is_in_board(nonogram_tile_map_coords):
		return
	
	var tile = -1
	match (button_index):
		BUTTON_LEFT:
			tile = Util.nono_color
		BUTTON_RIGHT:
			tile = Util.nono_cross
		
		
	# Compare this action with solution tile map to see if it's a correct one
	if solution_tile_map.get_cellv(nonogram_tile_map_coords) == tile and \
	not nonogram_tile_map.get_cellv(nonogram_tile_map_coords) == -1:
		
		# If it is correct, then the tile is removed to reveal the tilemaps underneath it
		nonogram_tile_map.set_cellv(nonogram_tile_map_coords, -1)
		
	elif nonogram_tile_map.get_cellv(nonogram_tile_map_coords) == tile or \
		nonogram_tile_map.get_cellv(nonogram_tile_map_coords) == -1:
		
		# If the tile is already set to what we are trying to color it, then clear it
		nonogram_tile_map.set_cellv(nonogram_tile_map_coords, Util.nono_blank)
		
	else:
		# Set the tile
		nonogram_tile_map.set_cellv(nonogram_tile_map_coords, tile)

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

# Returns the position of the closest tile that the mouse is pointing at
func get_selected_tile():
	return nonogram_tile_map.world_to_map(nonogram_tile_map.get_local_mouse_position())
	
# Converts world space to tilemap space
func world_to_board(pos: Vector2):
	return nonogram_tile_map.world_to_map(pos)
