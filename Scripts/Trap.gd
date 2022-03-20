extends Interactable

class_name Trap

export var attack = 2

func interact_with(character: Character):
	character.take_damage(attack)
	delete_self()
