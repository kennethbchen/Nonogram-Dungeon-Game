extends Label

func _on_Player_energy_changed(value, max_value):
	text = str(value) + " / " + str(max_value)
