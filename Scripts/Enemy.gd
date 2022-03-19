extends Character

onready var player = $"../Player"

var move_path = []

var last_player_position

# Top left, top right, bottom left, bottom right points
onready var relative_corner_points = [
	Vector2(-board_controller.tile_size/2,-board_controller.tile_size/2),
	Vector2(board_controller.tile_size/2,-board_controller.tile_size/2),
	Vector2(-board_controller.tile_size/2,board_controller.tile_size/2),
	Vector2(board_controller.tile_size/2,board_controller.tile_size/2)
]

func _ready():
	
	act()
	
func act():
	
	# Do a raycast to the player's position
	
	# Do a raycast in all four corners to project the whole tile
	for point in relative_corner_points:
		ray.position = point
		ray.cast_to = (player.position - (position + ray.position)) * board_controller.tile_size * 10
		ray.force_raycast_update()
		if(ray.is_colliding() and ray.get_collider() is Player):
			print("Player Found")
			break
	ray.position = Vector2(0,0)
	pass
