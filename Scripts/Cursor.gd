extends Node2D


onready var mainSprite = $Main

onready var scale_tween = $CursorScale

onready var position_tween = $CursorPosition

onready var effect_tilemap = $"../Tilemaps/EffectTileMap"

onready var board_ctrl = $"../BoardController"

var tilemap_position = Vector2(0,0)
var current_position = Vector2(0,0)


func _ready():
	_update_tween_scale()
	_update_tween_position()
	
	
func _update_tween_scale():
	scale_tween.interpolate_property(mainSprite, "scale",
	Vector2(1,1), Vector2(1.2,1.2), .2, Tween.TRANS_LINEAR, Tween.EASE_IN)
	
	scale_tween.interpolate_property(mainSprite, "scale",
	Vector2(1.2,1.2), Vector2(1,1), .2, Tween.TRANS_LINEAR, Tween.EASE_OUT, 0.2)
	
	scale_tween.repeat = true
	scale_tween.start()

func _update_tween_position():
	#position_tween.interpolate_property(self, "position",
	#position, current_position, .05, Tween.TRANS_QUART, Tween.EASE_OUT_IN)
	#position_tween.start()
	position = current_position

func set_position(tilemap_pos: Vector2):
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

func disable_cursor():
	effect_tilemap.clear()
	mainSprite.hide()
	
func enable_cursor():
	mainSprite.show()
