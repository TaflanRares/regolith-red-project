extends Node

@onready var hex_to_province:Dictionary
var provinces_path = "res://Assets/Provinces/mars_provinces_dictionary.txt"

func _ready()->void:
	if multiplayer.is_server():
		generate_provinces()
	
func generate_provinces()->void:
	if not multiplayer.is_server(): return
	print("STARTING GENERATION")
	var provinces_file:String = FileAccess.open(provinces_path, FileAccess.READ).get_as_text()
	var rows:Array = provinces_file.split("\n")
	for row in rows:
		if row.strip_edges() != "":
			var columns:Array = row.split(";")
			var province_id:int = int(columns[0])
			var province_colorhex:String = columns[1]
			var province_title:String = columns[2]
			var province_type:String = columns[3]
			
			var province = Province.new(province_id, province_colorhex, province_title, province_type)
			province.name = province_title
			add_child(province)
			hex_to_province[province_colorhex]=province
			
			var data = {
				"id": province_id,
				"colorhex": province_colorhex,
				"title": province_title,
				"type": province_type,
				"occupation": -1,
				"troops": 0
			}
			rpc("client_create_province", data)
			
@rpc("authority", "call_local")
func client_create_province(data: Dictionary) -> void:
	if multiplayer.is_server(): return  # server doesn't need to create its own copy
	
	var province := Province.new(
		data["id"],
		data["colorhex"],
		data["title"],
		data["type"]
	)
	province.set_occupation(data.get("occupation", -1))
	province.set_troops(data.get("troops", 0))
	province.name = data["title"]
	add_child(province)
	hex_to_province[data["colorhex"]] = province

@rpc("any_peer")
func request_province_update(colorhex: String, occupation: int, troops: int) -> void:
	# Only server runs this code
	if not multiplayer.is_server():
		return

	var province = hex_to_province.get(colorhex)
	if province:
		province.set_occupation(occupation)
		province.set_troops(troops)

		# Broadcast updated state to all clients, including host/server itself
		var data = {
			"colorhex": colorhex,
			"occupation": occupation,
			"troops": troops,
		}
		rpc("client_update_province_state", data)
	else:
		print("Province %s not found on server" % colorhex)


func player_try_update_province(province: Province, new_occupation: int, new_troops: int) -> void:
	if not multiplayer.is_server():
		# Clients call the server asking for the update
		rpc_id(1, "request_province_update", province.get_colorhex(), new_occupation, new_troops)
	else:
		# Server can update directly if host
		province.set_occupation(new_occupation)
		province.set_troops(new_troops)
		var data = {
			"colorhex": province.get_colorhex(),
			"occupation": new_occupation,
			"troops": new_troops
		}
		rpc("client_update_province_state", data)

@rpc("authority", "call_local")
func client_update_province_state(data: Dictionary) -> void:
	var province = hex_to_province.get(data["colorhex"], null)
	if province:
		province.set_occupation(data.get("occupation", province.get_occupation()))
		province.set_troops(data.get("troops", province.get_troops()))
	else:
		print("Warning: Province with colorhex %s not found" % data["colorhex"])

func change_province_occupation(province: Province, new_occupation: int, new_troops: int) -> void:
	province.set_occupation(new_occupation)
	province.set_troops(new_troops)
	var data = {
		"colorhex": province.get_colorhex(),
		"occupation": new_occupation,
		"troops": new_troops
	}
	rpc("client_update_province_state", data)
	if all_provinces_have_same_occupation():
		print("PLAYER HAS WON")

func get_province_by_hex(hex: String) -> Province:
	return hex_to_province.get(hex)

func all_provinces_have_same_occupation() -> bool:
	if hex_to_province.is_empty():
		return true  # no provinces means trivially true

	var occupations = []
	for province in hex_to_province.values():
		if province == null:
			continue
		occupations.append(province.get_occupation())

	if occupations.size() <= 1:
		return true  # all same if 0 or 1 province

	var first_occ = occupations[0]
	for occ in occupations:
		if occ != first_occ:
			return false  # mismatch found
		if occ == -1:
			return false

	return true  # all occupations match
