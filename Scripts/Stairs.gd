extends Interactable

class_name Stairs

func interact_with(character: Character):
	character.stairs_found()
	print("stairs")
