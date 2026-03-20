extends Node
class_name PlayerInput

@export var CameraPivot: Node3D
@export var CameraRot: Node3D
@export var PlayerCamera: Camera3D
@export var TurnEndButtonPath: NodePath = "PlayerUI/DownRight UI/Next Turn Button"
@onready var TurnEndButton: Button = $"../PlayerUI/DownRight UI/Next Turn Button"
@onready var province_bitmap_path = "res://Assets/Provinces/mars_provinces_bitmap.bmp"
@onready var image_texture = ImageTexture.new()
@onready var isPlayerTurn=0

var CameraBasis : Basis = Basis.IDENTITY
var Holding_RightMouse := false
var Distance := 50.0

const CAMERA_MOUSE_ROTATION_SPEED := 0.001
const CAMERA_X_ROT_MIN := deg_to_rad(-60.0)
const CAMERA_X_ROT_MAX := deg_to_rad(60.0)
const CAMERA_UP_DOWN_MOVEMENT := -1

var MIN_Distance := 40.0
var MAX_Distance := 60.0
var Camera_ZoomSpeed := 3.0

signal onProvince_selected

func _is_game_active() -> bool:
	return TurnManager.is_game_started()

func _ready():
	image_texture = load(province_bitmap_path)
	if multiplayer.get_unique_id() == str(get_parent().name).to_int():
		PlayerCamera.current = true
	else:
		PlayerCamera.current = false
	TurnManager.turn_started.connect(_on_turn_started)

func _gather():
	if not is_multiplayer_authority():
		return
	CameraBasis = CameraPivot.global_transform.basis 

func _process(_delta):
	var holding = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)

	if holding and not Holding_RightMouse:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		Holding_RightMouse = true
	elif not holding and Holding_RightMouse:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		Holding_RightMouse = false

func _input(event):	
	if not is_multiplayer_authority():
		return
		
	if event.is_action_pressed("ui_cancel"):
		if $"../PlayerUI/PauseMenu".visible:
			$"../PlayerUI/PauseMenu".hide()
		else:
			$"../PlayerUI/PauseMenu".show()
	
	if not _is_game_active():
		return
	
	if event is InputEventMouseMotion and Holding_RightMouse:
		rotate_camera(event.relative * CAMERA_MOUSE_ROTATION_SPEED)
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		onProvince_selected.emit(shoot_ray())
	
	if event is InputEventMouseButton and event.pressed:
		if Holding_RightMouse:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				Distance = clamp(Distance - Camera_ZoomSpeed, MIN_Distance, MAX_Distance)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				Distance = clamp(Distance + Camera_ZoomSpeed, MIN_Distance, MAX_Distance)
			PlayerCamera.transform.origin = Vector3(0, 0, Distance)

		if event.button_index == MOUSE_BUTTON_RIGHT:
			Holding_RightMouse = event.pressed
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if Holding_RightMouse else Input.MOUSE_MODE_VISIBLE)

func rotate_camera(move: Vector2) -> void:
	CameraPivot.rotate_y(-move.x)
	CameraPivot.orthonormalize()
	CameraRot.rotation.x = clamp(CameraRot.rotation.x + CAMERA_UP_DOWN_MOVEMENT * move.y, CAMERA_X_ROT_MIN, CAMERA_X_ROT_MAX)

func _on_turn_end_button_pressed() -> void:
	if multiplayer.is_server():
		TurnManager.end_turn()
	else:
		TurnManager.rpc_id(1, "request_end_turn")

func _on_turn_started(current_player_id: int):
	if current_player_id == multiplayer.get_unique_id():
		TurnEndButton.disabled = false
	else:
		TurnEndButton.disabled = true
	if (TurnManager.request_turn()):
		isPlayerTurn=1
		TurnEndButton.disabled = false
	else:
		isPlayerTurn=0
		if not multiplayer.is_server():
			$"../PlayerUI/DownRight UI/Next Turn Button".disabled = true

func shoot_ray():
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_length = 3000
	var from = PlayerCamera.project_ray_origin(mouse_pos)
	var to = from + PlayerCamera.project_ray_normal(mouse_pos) * ray_length
	var space = PlayerCamera.get_world_3d().direct_space_state
	var ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.from = from
	ray_query.to = to
	var raycast_result = space.intersect_ray(ray_query)
	print(raycast_result)
	if !raycast_result.is_empty():
		return SpatialCoord_to_color(Vector3(raycast_result.position.x, raycast_result.position.y, raycast_result.position.z))

func SpatialCoord_to_color(SpatialCoord: Vector3):
	var image = image_texture.get_image()
	
	var x = SpatialCoord.x
	var y = SpatialCoord.y
	var z = SpatialCoord.z
	var uv = get_uv_from_sphere_point(Vector3(x,y,z))

	var image_x := int(uv.x * image.get_width())
	var image_y := int(uv.y * image.get_height())
	image_x = clamp(image_x, 0, image.get_width() - 1)
	image_y = clamp(image_y, 0, image.get_height() - 1)
	image_x = image_x - image.get_width()
	image_x = abs(image_x)

	return color_to_hex(image.get_pixel(image_x, image_y))

func get_uv_from_sphere_point(p: Vector3) -> Vector2:
	var n = p.normalized()
	var u = 0.5 + atan2(n.z, n.x) / (2.0 * PI)
	var v = 0.5 - asin(clamp(n.y, -1.0, 1.0)) / PI
	return Vector2(u, v)

func color_to_hex(color: Color) -> String:
	var r = int(color.r * 255)
	var g = int(color.g * 255)
	var b = int(color.b * 255)
	return "#%02X%02X%02X" % [r, g, b]
