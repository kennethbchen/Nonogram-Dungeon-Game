extends Node2D

onready var bar_over = $BarOver
onready var bar_under = $BarUnder

onready var tween = $Tween

func _on_health_changed(value, max_value):
	if not is_visible() and value < max_value:
		show()
	
	bar_under.max_value = max_value
	if value == max_value:
		bar_under.value = max_value
		
	tween.interpolate_property(bar_under, "value", bar_under.value, value, 1, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.start()
	print()
	print(bar_under.value)
	bar_over.max_value = max_value
	bar_over.value = value
	
