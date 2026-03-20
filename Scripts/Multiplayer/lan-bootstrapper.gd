extends Node

@export_category("UI")
@export var title_ui: Control
@export var connect_ui: Control
@export var address_input: LineEdit
@export var port_input: LineEdit

func host_only():
	host()

func host():
	var hostee = _parse_input()
	if hostee.size() == 0:
		return ERR_CANT_RESOLVE	

	var port = hostee.port
	print("Starting host on port %s" % port)
	
	var peer = ENetMultiplayerPeer.new()
	if peer.create_server(port) != OK:
		print("Failed to listen on port %s" % port)

	get_tree().get_multiplayer().multiplayer_peer = peer
	print("Listening on port %s" % port)
	
	await Async.condition(
		func():
			return peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTING
	)

	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		OS.alert("Failed to start server!")
		return
	
	print("Server started")
	get_tree().get_multiplayer().server_relay = true
	
	connect_ui.hide()
	title_ui.hide()
	var menu = preload("res://Scenes/UI/PlayersJoined.tscn").instantiate()
	$"../PlayersMenu".add_child(menu)
	menu.name = "PlayersJoined"
	
	NetworkTime.start()

func join():
	var hostee = _parse_input()
	if hostee.size() == 0:
		return ERR_CANT_RESOLVE
		
	var address = hostee.address
	var port = hostee.port

	# Connect
	print("Connecting to %s:%s" % [address, port])
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(address, port)
	if err != OK:
		OS.alert("Failed to create client, reason: %s" % error_string(err))
		return err

	get_tree().get_multiplayer().multiplayer_peer = peer
	
	await Async.condition(
		func():
			return peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTING
	)

	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		OS.alert("Failed to connect to %s:%s" % [address, port])
		return

	print("Client started")
	connect_ui.hide()
	title_ui.hide()
	var menu = preload("res://Scenes/UI/PlayersJoined.tscn").instantiate()
	$"../PlayersMenu".add_child(menu)
	menu.name = "PlayersJoined"

func _parse_input() -> Dictionary:
	var address = address_input.text
	var port = port_input.text
	
	if address == "":
		OS.alert("No host specified!")
		return {}
		
	if not port.is_valid_int():
		OS.alert("Invalid port!")
		return {}
	port = port.to_int()

	return {
		"address": address,
		"port": port
	}
