extends Character

onready var player = $"/root/Main Scene/Player"

onready var pathfinder = $"/root/ Main Scene/PathfindingController"

var move_path = []

var player_pos_changed = false

# Last known player position (Tile space)
var last_player_position

# When an enemy dies, it emits this signal
signal enemy_died(enemy_object)

# Top left, top right, bottom left, bottom right points
onready var relative_corner_points = [
	Vector2(-board_controller.tile_size/2,-board_controller.tile_size/2),
	Vector2(board_controller.tile_size/2,-board_controller.tile_size/2),
	Vector2(-board_controller.tile_size/2,board_controller.tile_size/2),
	Vector2(board_controller.tile_size/2,board_controller.tile_size/2)
]

func _ready():
	pass

# Reduces health and fires signal
func take_damage(damage):
	.take_damage(damage)
	
	if health == 0:
		emit_signal("enemy_died", self)
		queue_free()

func act():
	
	# Do a raycast to the player's position
	
	# Do a raycast in all four corners to project the whole tile
	for point in relative_corner_points:
		ray.position = point
		ray.cast_to = (player.position - (position + ray.position)) * board_controller.tile_size * 10
		ray.force_raycast_update()
		if(ray.is_colliding() and ray.get_collider() is Player):
			# If the player is found, update the last known player position
			last_player_position = board_controller.world_to_board(player.position)
			player_pos_changed = true
			print("Player Found")
			break
	ray.position = Vector2(0,0)
	
	if player_pos_changed:
		# Recalculate move path to this new position
		# TODO: Create path-geting method in PathfindingController
		pass
