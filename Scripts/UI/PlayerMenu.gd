extends Control

@onready var player_list: ItemList = $PlayersPanel/PlayerContainer/PlayerList
@onready var start_button: Button = $PlayersPanel/StartGameButton

func _ready():
	TurnManager.players_joined_ui = self
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	update_player_list()

	if not multiplayer.is_server():
		start_button.hide()

func _on_peer_connected(_id: int) -> void:
	update_player_list()

func _on_peer_disconnected(_id: int) -> void:
	update_player_list()

func update_player_list():
	player_list.clear()
	
	if multiplayer.is_server():
		print("Adding host")
		player_list.add_item("Host (You)")
		
		for id in multiplayer.get_peers():
			print("Adding player %d" % id)
			player_list.add_item("Player %d" % id)
	else:
		var found_self = false
		for id in multiplayer.get_peers():
			if id == multiplayer.get_unique_id():
				print("Adding You")
				player_list.add_item("You")
				found_self = true
			else:
				print("Adding player %d" % id)
				player_list.add_item("Player %d" % id)
		if not found_self:
			print("Adding You (fallback)")
			player_list.add_item("You (Spectator)")

func _on_start_pressed():
	if multiplayer.is_server():
		TurnManager.start_game()
		TurnManager.rpc("start_game")
		hide()

@rpc("any_peer", "call_local")
func hide_menu_on_clients():
	hide()
