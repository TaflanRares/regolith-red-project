extends Node

signal turn_started(current_player_id: int)
signal turn_ended(new_value: int)

var players_joined_ui: Control = null
var player_ids: Array = []
var current_turn_index: int = 0
var game_started: bool = false
@export var turn_counter: int = 0

func is_game_started() -> bool:
	return game_started

@rpc("authority")
func start_game():
	print("Game is starting...")
	game_started = true
	if players_joined_ui != null:
		players_joined_ui.hide()
	start_turn()

func _ready() -> void:
	if multiplayer.is_server():
		set_multiplayer_authority(1)
		NetworkEvents.on_server_start.connect(_on_server_start)
		NetworkEvents.on_peer_join.connect(_on_peer_join)

func _on_server_start() -> void:
	player_ids.clear()
	game_started = false
	current_turn_index = 0

func _on_peer_join(id: int) -> void:
	if multiplayer.is_server():
		if game_started:
			print("Game already started — not adding player %d to player_ids." % id)
	if game_started:
		while id in player_ids:
			player_ids.erase(id)
	for province in get_children():
		if province is Province:
			var data = {
				"id": province.get_id(),
				"colorhex": province.get_colorhex(),
				"title": province.get_title(),
				"type": province.get_type(),
				"occupation": province.get_occupation(),
				"troops": province.get_troops()
			}
			rpc_id(id, "client_create_province", data)
	rpc_id(id, "sync_turn_state", player_ids, current_turn_index)

func start_turn():
	if player_ids.is_empty():
		return
	current_turn_index %= player_ids.size()
	var current_player = player_ids[current_turn_index]
	print("TURN START: Player %s" % current_player)

	rpc("sync_turn_state", player_ids, current_turn_index)

	turn_started.emit(current_player)

@rpc("any_peer")
func request_end_turn() -> void:
	var sender_id := multiplayer.get_remote_sender_id()
	if multiplayer.is_server():
		if sender_id == player_ids[current_turn_index]:
			end_turn()
		else:
			print("Player %d tried to end another player's turn!" % sender_id)

func end_turn() -> void:
	print("Ending turn for player: ", player_ids[current_turn_index])
	current_turn_index = (current_turn_index + 1) % player_ids.size()
	turn_counter += 1
	
	rpc("sync_turn_counter", turn_counter)
	start_turn()

@rpc("any_peer")
func request_turn() -> bool:
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = multiplayer.get_unique_id()
	if sender_id != player_ids[current_turn_index]:
		return 0
	else:
		return 1

@rpc("any_peer", "call_local")
func sync_turn_counter(new_value: int) -> void:
	turn_counter = new_value
	turn_ended.emit(turn_counter)

@rpc
func sync_turn_state(ids: Array, turn_index: int):
	player_ids = ids.duplicate()
	current_turn_index = turn_index
	print("Synced turn state. Current player ID:", player_ids[current_turn_index])

@rpc("any_peer")
func sync_turn(turn_idx: int) -> void:
	if turn_idx < player_ids.size():
		current_turn_index = turn_idx
		emit_signal("turn_started", player_ids[current_turn_index])
	else:
		print("sync_turn: Ignoring invalid turn index %d" % turn_idx)

func get_current_player_id() -> int:
	if player_ids.is_empty():
		return -1
	return player_ids[current_turn_index]

func playercolor(playerid: int) -> Color:
	var index = clamp(playerid%256+20, 50, 255)
	return Color(index, index, index)
