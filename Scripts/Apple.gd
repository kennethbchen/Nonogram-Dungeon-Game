extends "res://Scripts/Interactable.gd"

class_name Apple

export var heal_amount = 5

func interact_with(character: Character):
	character.heal(heal_amount)
	delete_self()
