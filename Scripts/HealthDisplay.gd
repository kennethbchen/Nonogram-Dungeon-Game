extends Label

func _on_Player_health_changed(value, max_value):
	text = str(value) + " / " + str(max_value)
