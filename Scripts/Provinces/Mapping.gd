extends StaticBody3D
var provbitmap_path = "res://Assets/Provinces/mprovbmp(copy).bmp"
var map_material_2d_path = "res://Assets/Materials/Map2DMat.tres"
@onready var province_color_to_Lookup : Dictionary
@onready var map_material_2d = load(map_material_2d_path)
@onready var color_map_occupation: Image = Image.create(256, 256, false, Image.FORMAT_RGB8)
var current_map_mode:Image

func _ready() -> void:
	create_lookup_texture()
	create_color_map()
	
func create_lookup_texture() -> void:
	var province_image: Image = load(provbitmap_path).get_image()
	var lookup_image: Image = province_image.duplicate()
	var color_map_r: int = 0
	var color_map_g: int = 0

	for x in range(lookup_image.get_width()):
		for y in range(lookup_image.get_height()):
			var province_color : Color = province_image.get_pixel(x,y)
			if not province_color_to_Lookup.has(province_color):
				province_color_to_Lookup[province_color] = Color(color_map_r/255.0, color_map_g/255.0, 0.0)
				color_map_r += 1
				if color_map_r == 256:
					color_map_r = 0
					color_map_g += 1
			lookup_image.set_pixel(x,y,province_color_to_Lookup[province_color])
	var lookup_texture = ImageTexture.create_from_image(lookup_image)
	map_material_2d.set_shader_parameter("lookup_image", lookup_texture)

func create_color_map() -> void:
	for province_color in province_color_to_Lookup.keys():
		var lookup = province_color_to_Lookup[province_color]
		var x = int(lookup.r * 255)
		var y = int(lookup.g * 255)
		var hex_key = color_to_hex(province_color)
		if ProvincesManager.hex_to_province.has(hex_key):
			var province: Province = ProvincesManager.hex_to_province[hex_key]
			print(province)
			if province.get_type() == "land":
				var owner_color = TurnManager.playercolor(province.occupation)
				color_map_occupation.set_pixel(x,y, owner_color)
		else:
			print("Province not found for color key:", hex_key)
	var color_map_texture = ImageTexture.create_from_image(color_map_occupation)
	map_material_2d.set_shader_parameter("color_map_image", color_map_texture)
	current_map_mode = color_map_occupation

func color_to_hex(color: Color) -> String:
	var r = int(color.r * 255)
	var g = int(color.g * 255)
	var b = int(color.b * 255)
	return "#%02X%02X%02X" % [r, g, b]
