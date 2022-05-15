extends Control

onready var hint_font = load("res://UI/NonogramHint.tres")

# Array of label nodes that display the hints
# Each hint label is the label for each unique row / column
# The format of the labels is the same as the hint array and they should be the same size
var hint_labels = []

func _ready():
	_create_labels()

# The number of labels is dependent on the room size
# Create the actual label elements that will display text
func _create_labels(cols = Util.room_columns, rows = Util.room_rows):
	
	var line = []
	
	# Generate hint for the columns (top side of board)
	for col_id in range(0, cols):
		
		var label = Label.new()
		label.set_size(Vector2(Util.tile_size, Util.tile_size * 4))
		label.add_font_override("font", hint_font)
		label.align = HALIGN_CENTER
		label.valign = VALIGN_BOTTOM
		
		label.set_position(Vector2(col_id * Util.tile_size, -Util.tile_size * 4))
		
		label.text = "0\n1\n2"
		
		add_child(label)
		line.append(label)
		
		pass
	
	hint_labels.append(line)
	line = []
	
	for row_id in range(0, rows):
		
		var label = Label.new()
		label.set_size(Vector2(Util.tile_size * 4, Util.tile_size))
		label.add_font_override("font", hint_font)
		label.align = HALIGN_RIGHT
		label.valign = VALIGN_CENTER
		
		# For some reason, the vertical alignment for the row hints don't work perfectly, so adjust slightly
		label.set_position(Vector2(-Util.tile_size * 4, row_id * Util.tile_size + 3))
		
		label.text = "0 1 2"
		
		add_child(label)
		line.append(label)
		pass
		
	pass

# Takes a hint and displays that using the labels
# The input is an array[2][x] of strings where:
# In array[0], x is the hints of the columns (top of board) and
# In array[1], x is the hints of the rows (left of board)
# Each individual cell (array[a][b]) is the full hint as a string that should be displayed
func _update_labels(hint):
	pass
