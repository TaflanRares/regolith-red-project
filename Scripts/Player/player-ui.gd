extends CanvasLayer

@onready var SolCounter: Label = $"DownRight UI/Sol Counter"

func _ready():
	TurnManager.turn_ended.connect(_on_turn_counter_changed)
	SolCounter.text = "Sol: " + str(TurnManager.turn_counter)

func _on_turn_counter_changed(new_value: int) -> void:
	SolCounter.text = "Sol: " + str(new_value)
