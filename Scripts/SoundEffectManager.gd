extends Node

onready var players = self.get_children()

var rng = RandomNumberGenerator.new()

# last_ variables are dictionaries to force them to be passed by reference to update their value

var last_footstep = {"value": -1}
var footsteps = [
	preload("res://Audio/Footstep/footstep-1.wav"),
	preload("res://Audio/Footstep/footstep-2.wav"),
	preload("res://Audio/Footstep/footstep-3.wav"),
	preload("res://Audio/Footstep/footstep-4.wav"),
	preload("res://Audio/Footstep/footstep-5.wav")
]

var last_attack = {"value": -1}
var attacks = [
	preload("res://Audio/Attack/swish-1.wav"),
	preload("res://Audio/Attack/swish-2.wav"),
	preload("res://Audio/Attack/swish-3.wav"),
	preload("res://Audio/Attack/swish-4.wav"),
	preload("res://Audio/Attack/swish-5.wav"),
]

var last_door = {"value": -1}
var door = [
	preload("res://Audio/Door/door-2.wav"),
	preload("res://Audio/Door/door-3.wav"),
	preload("res://Audio/Door/door-4.wav"),
	preload("res://Audio/Door/door-5.wav")
]

var last_food = {"value": -1}
var food_crunch = [
	preload("res://Audio/FoodCrunch/crunch-1.wav"),
	preload("res://Audio/FoodCrunch/crunch-2.wav"),
	preload("res://Audio/FoodCrunch/crunch-3.wav")
]

var trap = preload("res://Audio/Single/trap.wav")

# Potion sound effect
var energy = preload("res://Audio/SIngle/bottle.wav")

func _ready():
	rng.randomize()

func _on_player_footstep():
	_play_rand(footsteps, last_footstep)
	pass
	
func _on_player_attack():
	_play_rand(attacks, last_attack)
	pass

func _on_player_damage():
	pass

func _on_door():
	_play_rand(door, last_door)


func _on_trap():
	print("trap")
	_play(trap)
	
func _on_health():
	_play_rand(food_crunch, last_food)

func _on_energy():
	_play(energy)
	pass

func _on_nono_color():
	pass

func _on_nono_cross():
	pass
	
func _play_rand(sounds, last_index):
	var index = rng.randi_range(0, sounds.size() - 1)
	
	if index == last_index["value"]:
		index = (index + 1) % sounds.size()
	
	last_index["value"] = index
	
	var player = _get_audio_player()
	player.stream = sounds[index]
	player.play()

func _get_audio_player():
	
	# Go through all of the available audio players and get one that is free
	for player in players:
		if !player.playing:
			return player
	
	return players[0]

func _play(sound):
	var player = _get_audio_player()
	player.stream = sound
	player.play()
