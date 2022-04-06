extends Node

"""
Manages the playing of sound effects 
There can be multiple audio stream players wihch allows for sounds to be
played concurrently
"""

# Number of audio players
export var num_channels = 1

var audio_players = []

var rng = RandomNumberGenerator.new()

# Note: The concept of making sure that each sound isn't played twice in a row
# doesn't really work anymore with the current implementation
# because each sound effect player is isolated from others
# so there's no global knowledge of sound effect history
var last_index = -1

signal players_finished()

func _ready():
	
	rng.randomize()
	
	# Create the specified number of audio stream players
	for _i in range(0, num_channels):
		var player = AudioStreamPlayer.new()
		player.bus = "Sound Effects"
		player.connect("finished", self, "_on_player_done")
		audio_players.append(player)
		
		add_child(player)
	
	
func play_rand(sounds):
	
	# Pick a random number
	var index = rng.randi_range(0, sounds.size() - 1)
	
	# If the index is the same as what was previously played,
	# Avoid this by changing the index
	if index == last_index:
		index = (index + 1) % sounds.size()
	
	last_index = index
	
	var player = _get_audio_player()
	
	player.stream = sounds[index]
	player.play()

func is_playing():
	
	# Go through all of the audio players
	# If any of them are still playing, then return false
	
	for player in audio_players:
		if player.playing:
			return true
	return false
	
func _get_audio_player():
	
	# Go through all of the available audio players and get one that is free
	for player in audio_players:
		if !player.playing:
			
			return player
	
	return audio_players[0]

# This is called whenever an audio player is finished playing
# This is to replicate an individual audio stream player's "finished" signal
# but while tracking multiple audio payers which is used to determine 
# whether or not the sound effect player is still in the middle of playing sounds
func _on_player_done():
	
	# If all players are not playing, then the on_audio_done signal is fired
	for player in audio_players:
		if player.playing:
			return
			
	
	emit_signal("players_finished")
