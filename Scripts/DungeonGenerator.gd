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

func generate_board():
	
	rand.randomize()
	
	dungeon_tile_map.clear()
	
	# Fill in the board with walls
	for col in range(0, max_floor_columns):
		for row in range(0, max_floor_rows):
			dungeon_tile_map.set_cellv(Vector2(col, row), Util.world_wall)
	
	# http://roguebasin.com/index.php/Basic_BSP_Dungeon_generation
	
	# 0 - Dividing line is horizontal
	# 1 - Dividing line is vertical
	var split_direction = rand.randi_range(0,1)
	
	var split_position = 0
	if split_direction == 0:
		# Horizontal line, choose vertical position for that line
		split_position = int(rand.randi_range(0, max_floor_rows) / room_rows)
	elif split_direction == 0:
		# Vertical line, choose horizontal position for that line
		split_position = int(rand.randi_range(0, max_floor_columns) / room_columns)
	
	print(split_direction)
	print(split_position)
	
func _draw():
	
	# Draw the dividing lines between rooms
	for room_col in range(0, max_rooms_x + 1):
		draw_line(Vector2(room_col * room_columns, 0 ) * Util.tile_size, Vector2(room_col * room_columns, max_floor_rows) * Util.tile_size, Color.aqua)
	
	for room_row in range(0, max_rooms_y + 1):
		draw_line(Vector2(0, room_row * room_rows) * Util.tile_size, Vector2(max_floor_columns, room_row * room_rows) * Util.tile_size, Color.aqua)
	
