extends Label

func _on_value_changed(value, max_value = 0):
	if max_value != 0:
		text = str(value) + " / " + str(max_value)
	else:
		text = str(value)
