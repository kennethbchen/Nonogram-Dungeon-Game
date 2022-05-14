extends Control

onready var instruction_popup = $InstructionPopup

func _on_Start_Button_pressed():
	get_tree().change_scene("res://Game_Main.tscn")


func _on_Instruction_Button_pressed():
	instruction_popup.popup_centered()


func _on_ClosePopupButton_pressed():
	instruction_popup.hide()
