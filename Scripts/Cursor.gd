extends Node2D

onready var main_sprite = $Main

onready var tileset = load("res://Sprites/Nonagram Tiles.png")

# Start and end position sprites for multi selecting
onready var multi_start = $MultiStart
onready var multi_end = $MultiEnd

# The Multi Label is a UI element that shows how many squares are being selected in multi select mode
onready var multi_text_back = $MultiLabel/MultiLabelText/MultiLabelBack
onready var multi_label = $MultiLabel/MultiLabelText

# The region values that point to the right sprites in the tileset
var horiz_region = Rect2(Util.tile_size * 4, 0, Util.tile_size, Util.tile_size)
var verti_region = Rect2(Util.tile_size * 4, Util.tile_size, Util.tile_size, Util.tile_size)

onready var scale_tween = $CursorScale

onready var effect_tilemap = $"../Tilemaps/EffectTileMap"

onready var board_ctrl = $"../BoardController"

# Current position of the cursor in tilemap space
var tilemap_position = Vector2(0,0)

# Current position of the cursor in world space
var current_position = Vector2(0,0)

func _ready():
	_update_tween_scale()
	
	multi_start.region_enabled = true
	multi_start.texture = tileset
	multi_start.hide()
	
	multi_end.region_enabled = true
	multi_end.texture = tileset
	multi_end.hide()
	
	disable_cursor()
	disable_multi()
	
func _update_tween_scale():
	scale_tween.interpolate_property(main_sprite, "scale",
	Vector2(1,1), Vector2(1.2,1.2), .2, Tween.TRANS_LINEAR, Tween.EASE_IN)
	
	scale_tween.interpolate_property(main_sprite, "scale",
	Vector2(1.2,1.2), Vector2(1,1), .2, Tween.TRANS_LINEAR, Tween.EASE_OUT, 0.2)
	
	scale_tween.interpolate_property(multi_start, "scale",
	Vector2(1,1), Vector2(1.2,1.2), .2, Tween.TRANS_LINEAR, Tween.EASE_IN)
	
	scale_tween.interpolate_property(multi_start, "scale",
	Vector2(1.2,1.2), Vector2(1,1), .2, Tween.TRANS_LINEAR, Tween.EASE_OUT, 0.2)
	
	scale_tween.interpolate_property(multi_end, "scale",
	Vector2(1,1), Vector2(1.2,1.2), .2, Tween.TRANS_LINEAR, Tween.EASE_IN)
	
	scale_tween.interpolate_property(multi_end, "scale",
	Vector2(1.2,1.2), Vector2(1,1), .2, Tween.TRANS_LINEAR, Tween.EASE_OUT, 0.2)
	
	scale_tween.repeat = true
	scale_tween.start()

# Used to indicate the position of the cursor for single tile marking
func set_position(tilemap_pos: Vector2):
	enable_cursor()
	disable_multi()
	
	tilemap_position = tilemap_pos
	current_position = tilemap_pos * Util.tile_size + Util.tile_offset
	position = current_position
	
	# Also make the horizontal and vertical guides
	effect_tilemap.clear()
	
	for col in range (0, Util.board_columns):
		
		if col != tilemap_position.x:
			effect_tilemap.set_cellv(Vector2(col, tilemap_position.y), Util.nono_horiz_guide)
			pass
		pass
		
	for row in range(0, Util.board_rows):
		
		if row != tilemap_position.y:
			effect_tilemap.set_cellv(Vector2(tilemap_position.x, row), Util.nono_verti_guide)
			pass
		pass

# Used to indicate the tiles that will be affected in multi tile marking
func set_multi(tilemap_start: Vector2, tilemap_end: Vector2):
	disable_cursor()
	enable_multi()
	
	var diff = tilemap_end - tilemap_start
	
	# The start sprite doesn't change local coordinate wise
	# The end sprite does, however
	var end_offset = diff * Util.tile_size
	
	# Determine whether or not the multi select is happening horizontall or vertically
	# The dimension with the largest distance between start and end wins
	if abs(diff.x) > abs(diff.y):
		# Horizontal
		
		# Set sprites
		multi_start.region_rect = horiz_region
		multi_end.region_rect = horiz_region
		
		# Horizontal select means no vertical flips
		multi_start.flip_v = false
		multi_end.flip_v = false
		
		# Determine whether or not the selection is happening from
		# left to right or right ot left
		# This changes which sprite (start/end) should be flipped
		if diff.x > 0:
			# Positive diff, left to right
			multi_start.flip_h = false
			
			multi_end.flip_h = true
		else:
			# Negative diff, right to left
			multi_start.flip_h = true
			
			multi_end.flip_h = false
			
		multi_label.text = str(abs(diff.x) + 1)
		
		
		# Set the positions
		# End position inherits the start's y value
		multi_start.position = Vector2.ZERO
		multi_end.position = Vector2(end_offset.x, multi_start.position.y)
		multi_label.set_position(Vector2( (multi_start.position.x + multi_end.position.x) / 2, multi_start.position.y) - Util.tile_offset)
		
	else:
		
		# Set sprites
		multi_start.region_rect = verti_region
		multi_end.region_rect = verti_region
		
		# Vertical select means no horizontal flips
		multi_start.flip_h = false
		multi_end.flip_h = false
		
		# Determine whether or not the selection is happening from
		# top to bottom or bottom to top
		# This changes which sprite (start/end) should be flipped
		if diff.y > 0:
			# Positive diff, bottom to top
			multi_start.flip_v = true
			
			multi_end.flip_v = false
		else:
			# Negative diff, top to bottom
			multi_start.flip_v = false
			
			multi_end.flip_v = true
		
		multi_label.text = str(abs(diff.y) + 1)
		
		# Set the positions
		# End position inherits the start's x value
		multi_start.position = Vector2.ZERO
		multi_end.position = Vector2(multi_start.position.x, end_offset.y)
		multi_label.set_position( Vector2(multi_start.position.x, (multi_start.position.y + multi_end.position.y) / 2) - Util.tile_offset)
				

func disable_cursor():
	effect_tilemap.clear()
	main_sprite.hide()
	
func enable_cursor():
	main_sprite.show()

func enable_multi():
	multi_start.show()
	multi_end.show()
	multi_text_back.show()
	multi_label.show()
	
func disable_multi():
	multi_start.hide()
	multi_end.hide()
	multi_text_back.hide()
	multi_label.hide()
