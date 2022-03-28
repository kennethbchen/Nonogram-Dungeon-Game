extends Interactable

class_name Potion

var restore_amount = 60

func interact_with(character: Character):
	character.restore_energy(restore_amount)
	delete_self()
