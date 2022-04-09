extends Node2D

enum states {
	NORMAL,
	DRAG
}

onready var main_sprite = $Main

onready var tileset = load("res://Sprites/Nonagram Tiles.png")

# Start and end position sprites for multi selecting
onready var multi_start = $MultiStart
onready var multi_end = $MultiEnd

# The region values in the tilemap
var horiz_region = Rect2(Util.tile_size * 4, 0, Util.tile_size, Util.tile_size)
var verti_region = Rect2(Util.tile_size * 4, Util.tile_size, Util.tile_size, Util.tile_size)

onready var scale_tween = $CursorScale

onready var position_tween = $CursorPosition

onready var effect_tilemap = $"../Tilemaps/EffectTileMap"

onready var board_ctrl = $"../BoardController"

var tilemap_position = Vector2(0,0)
var current_position = Vector2(0,0)

var current_state = states.NORMAL

func _ready():
	_update_tween_scale()
	_update_tween_position()
	
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

func _update_tween_position():
	position = current_position

func set_position(tilemap_pos: Vector2):
	enable_cursor()
	disable_multi()
	
	tilemap_position = tilemap_pos
	current_position = tilemap_pos * Util.tile_size + Util.tile_offset
	_update_tween_position()
	
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

func set_multi(tilemap_start: Vector2, tilemap_end: Vector2):
	disable_cursor()
	enable_multi()
	
	var diff = tilemap_end - tilemap_start
	var end_offset = diff * Util.tile_size
	
	multi_start.show()
	multi_end.show()
	
	
	
	
	if abs(diff.x) > abs(diff.y):
		# Horizontal
		
		multi_start.region_rect = horiz_region
		multi_end.region_rect = horiz_region
		
		multi_start.flip_v = false
		multi_end.flip_v = false
		
		if diff.x > 0:
			multi_start.flip_h = false
			
			multi_end.flip_h = true
		else:
			multi_start.flip_h = true
			
			multi_end.flip_h = false
			
		
		
		multi_start.position = Vector2.ZERO
		multi_end.position = Vector2(end_offset.x, multi_start.position.y)
		
		print("horizontal")
	else:
		
		multi_start.region_rect = verti_region
		multi_end.region_rect = verti_region
		
		multi_start.flip_h = false
		multi_end.flip_h = false
		
		if diff.y > 0:
			multi_start.flip_v = true
			
			multi_end.flip_v = false
		else:
			multi_start.flip_v = false
			
			multi_end.flip_v = true
		
		
		multi_start.position = Vector2.ZERO
		multi_end.position = Vector2(multi_start.position.x, end_offset.y)
		
		print("vertical")
				

func disable_cursor():
	effect_tilemap.clear()
	main_sprite.hide()
	
func enable_cursor():
	main_sprite.show()

func enable_multi():
	multi_start.show()
	multi_end.show()
	
func disable_multi():
	multi_start.hide()
	multi_end.hide()
