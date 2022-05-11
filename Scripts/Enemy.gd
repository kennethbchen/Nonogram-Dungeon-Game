extends Character

var player = null

onready var pathfinder = $"../../PathfindingController"

var move_path = []

# If the player's position changed from where it was last known
var player_pos_changed = false

# Last known player position (Tile space)
var last_player_position

# When an enemy dies, it emits this signal
signal enemy_died(enemy_object)

# Top left, top right, bottom left, bottom right points
onready var relative_corner_points = [
	Vector2(-Util.tile_size/2,-Util.tile_size/2),
	Vector2(Util.tile_size/2,-Util.tile_size/2),
	Vector2(-Util.tile_size/2,Util.tile_size/2),
	Vector2(Util.tile_size/2,Util.tile_size/2)
]

func init(player_node):
	player = player_node
	print(self)
	print(player.position)
	

func _ready():
	print(player)
	pass

# Reduces health and fires signal
func take_damage(damage):
	.take_damage(damage)
	
	if health == 0:
		delete_self()

func delete_self():
	queue_free()

func act():
	# Do a raycast to the player's position
	# Do a raycast in all four corners to project the whole tile
	for point in relative_corner_points:
		
		ray.position = point
		
		ray.cast_to = (player.position - (position + ray.position)) * Util.tile_size * 10
		ray.force_raycast_update()
		
		if(ray.is_colliding() and ray.get_collider() is Player):
			# If the player is found and it's new and valid, update the last known player position
			if last_player_position != board_controller.world_to_board(player.position) and \
				pathfinder.is_valid_tile(board_controller.world_to_board(player.position)):
					
				last_player_position = board_controller.world_to_board(player.position)
				player_pos_changed = true
				
			break
			
	# Reset the ray's relative position for other operations
	ray.position = Vector2(0,0)
	
	if player_pos_changed:

		# Recalculate move path to this new position
		move_path = pathfinder.get_tile_path(board_controller.world_to_board(position), board_controller.world_to_board(player.position))
		player_pos_changed = false
	
	# If there are moves on the move path
	if move_path.size() > 0:
		
		# If there is a successful move, then remove that step
		var move_result = try_move(move_path[0])
		if move_result:
			
			move_path.remove(0)
	

# Handle a collision for try_move
func _handle_collision(direction: Vector2, collider: Object):
	
	if collider is Player:
		collider.change_health(abs(attack) * -1)
		bump_tween(direction)
		return false
	pass
