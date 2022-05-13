extends Camera2D

# https://github.com/GDQuest/godot-demos/blob/master/2018/03-16-camera-2d-rig/end/characters/camera/grid-snapper.gd

var grid_position = Vector2()
var grid_size = Vector2()
var grid_offset = Vector2(Util.room_columns / 2 * Util.tile_size, Util.room_rows / 2 * Util.tile_size)

onready var parent = get_parent()

func _ready():
	# If you drag the camera from the OffsetPivot node,
	# its position will not be (0, 0)
	position = Vector2()
	grid_size = Vector2(Util.tile_size * Util.room_columns, Util.tile_size * Util.room_rows)
	print(grid_size)
	set_as_toplevel(true)
	update_grid_position()


func _physics_process(delta):
	update_grid_position()


func update_grid_position():
	var new_grid_position = calculate_grid_position()
	
	if grid_position == new_grid_position:
		return
	grid_position = new_grid_position
	jump_to_grid_position()


func calculate_grid_position():
	var x = round( (parent.position.x + grid_offset.x) / grid_size.x)
	var y = round( (parent.position.y + grid_offset.y) / grid_size.y)
	
	return Vector2(x, y)


func jump_to_grid_position():
	position = Vector2(grid_position * grid_size) - grid_offset
	print(grid_position)
	
