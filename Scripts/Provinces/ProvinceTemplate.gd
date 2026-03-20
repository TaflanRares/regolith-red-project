extends Node
class_name Province
var id:int
var colorhex:String
var title:String
var type:String
var occupation:int
var troops:int

func set_id(value: int) -> void:
	id = value

func set_colorhex(value: String) -> void:
	colorhex = value

func set_title(value: String) -> void:
	title = value

func set_type(value: String) -> void:
	type = value
	
func set_occupation(value: int) -> void:
	occupation = value

func set_troops(value: int) -> void:
	troops = value

func _init(_id: int, _colorhex: String, _title: String, _type: String) -> void:
	set_id(_id)
	set_colorhex(_colorhex)
	set_title(_title)
	set_type(_type)
	set_occupation(-1)
	set_troops(0)

func get_id() -> int:
	return id

func get_colorhex() -> String:
	return colorhex

func get_title() -> String:
	return title

func get_type() -> String:
	return type
	
func get_occupation() -> int:
	return occupation
	
func get_troops() -> int:
	return troops
