extends Node2D

# https://gist.github.com/fcingolani/035e43f57abf72801ec2e774fb89ad06#file-astar2dvisualizer-gd

class_name AStar2DVisualizer

export(float) var point_radius = 6
export(float) var scale_multiplier = 16
export(Vector2) var offset = Vector2(0,0)
export(Color) var enabled_point_color = Color('00ff00')
export(Color) var disabled_point_color = Color('ff0000')
export(Color) var line_color = Color('0000ff')
export(float) var line_width = 2

var astar : AStar2D

func visualize(new_astar : AStar2D):
	astar = new_astar
	update()

func _point_pos(id):
	return offset + astar.get_point_position(id) * scale_multiplier

func _draw():
	
	if not astar:
		return
	
	for point in astar.get_points():
		
		for other in astar.get_point_connections(point):
			draw_line(_point_pos(point), _point_pos(other), line_color, line_width)
			
		var point_color = disabled_point_color if astar.is_point_disabled(point) else enabled_point_color
		draw_circle(_point_pos(point), point_radius, point_color)

 

