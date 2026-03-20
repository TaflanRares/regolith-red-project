extends AudioStreamPlayer

@export var songs: Array[AudioStream] = []

var current_index := 0

func _ready():
	if songs.size() > 0:
		stream = songs[current_index]
		play()

func _process(_delta):
	if not is_playing() and songs.size() > 0:
		_play_next()

func _play_next():
	current_index = (current_index + 1) % songs.size()
	stream = songs[current_index]
	play()

func _play_previous():
	current_index = (current_index - 1 + songs.size()) % songs.size()
	stream = songs[current_index]
	play()

func next_song():
	stop()
	_play_next()

func prev_song():
	stop()
	_play_previous()
