extends AudioStreamPlayer

var rng = RandomNumberGenerator.new()
var last_index= -1

# last_ variables are dictionaries to force them to be passed by reference to update their value

func _ready():
	rng.randomize()
	
func play_rand(sounds):
	# Pick a random number
	var index = rng.randi_range(0, sounds.size() - 1)
	
	# If the index is the same as what was previously played,
	# Avoid this by changing the index
	if index == last_index:
		index = (index + 1) % sounds.size()
	
	last_index = index
	
	stream = sounds[index]
	play()
