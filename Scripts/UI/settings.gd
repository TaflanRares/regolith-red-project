extends VBoxContainer

func onMasterVolume_change(value: float) -> void:
	AudioServer.set_bus_volume_db(0, value)

func onMuteButton_pressed(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(0, toggled_on)

func onResolutionOption_selected(index: int) -> void:
	match index:
		0: DisplayServer.window_set_size(Vector2i(1920,1080))
		1: DisplayServer.window_set_size(Vector2i(1600,900))
		2: DisplayServer.window_set_size(Vector2i(1280,720))

func onDisplayOption_selected(index: int) -> void:
	match index:
		0: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		1: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		2: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

func onExitButton_pressed() -> void:
	get_tree().quit()
