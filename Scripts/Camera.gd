extends Camera2D

# https://github.com/GDQuest/godot-demos/blob/master/2018/03-16-camera-2d-rig/end/characters/camera/grid-snapper.gd

var grid_position = Vector2()
var grid_size = Vector2()
var grid_offset = Vector2(Util.room_columns / 2 * Util.tile_size, Util.room_rows / 2 * Util.tile_size)

onready var parent = get_parent()

signal camera_changed(new_position)

func _ready():
	# If you drag the camera from the OffsetPivot node,
	# its position will not be (0, 0)
	position = Vector2()
	grid_size = Vector2(Util.tile_size * Util.room_columns, Util.tile_size * Util.room_rows)
	set_as_toplevel(true)
	update_grid_position()


func _physics_process(delta):
	update_grid_position()


func update_grid_position():
	var new_grid_position = get_grid_pos()

	if grid_position == new_grid_position:
		return
	grid_position = new_grid_position
	emit_signal("camera_changed", grid_position)
	jump_to_grid_position()


func get_grid_pos():
	var x = round( (parent.position.x + grid_offset.x) / grid_size.x)
	var y = round( (parent.position.y + grid_offset.y) / grid_size.y)
	
	# Subtract by a 1,1 Vector2 to make the position zero-indexed
	return Vector2(x, y) - Vector2(1,1)

func jump_to_grid_position():
	position = Vector2((grid_position + Vector2(1,1) ) * grid_size) - grid_offset

# If the floor changed, then refresh the hints always to avoid issues
# Where the character would spawn in the same room area, meaning that the hints wouldn't update for the starting floor
# The camera needs to be the one that instigates a hint refresh on the event of a floor change
# Kind of a jank solution because it means that the hints are applied twice during the transition to a new floor
func _on_floor_changed(dungeon_floor):
	emit_signal("camera_changed", grid_position)
