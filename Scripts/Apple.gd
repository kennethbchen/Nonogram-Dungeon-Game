extends "res://Scripts/Interactable.gd"

export var heal_amount = 5

func interact_with(character: Character):
	character.heal(heal_amount)
	delete_self()
