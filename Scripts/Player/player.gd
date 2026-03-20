extends CharacterBody3D

var color:Color
@export var input: PlayerInput
@onready var isPlayerTurn: bool
@onready var player_id: int
@onready var troops: int
var selected_province
var troops_attack:int

func _ready():
	troops=5
	$PlayerUI/AttackPanel/TroopSlider.max_value=troops;
	position = Vector3(0, 0, 0)
	player_id = multiplayer.get_unique_id()
	if input == null:
		input = $Input

func onInput_province_selected(hex_selected) -> void:
	if (TurnManager.request_turn()):
		isPlayerTurn=1
	else:
		isPlayerTurn=0;
	if (hex_selected):
		selected_province = ProvincesManager.get_province_by_hex(hex_selected)
		$PlayerUI/SelectedProvince.update_provinceInfo(selected_province)
		if isPlayerTurn:
			$PlayerUI/AttackPanel.show()
		
func onTroops_chosen(value: int) -> void:
	troops_attack = value
	$PlayerUI/AttackPanel/TroopCounter.text = str(troops_attack)

func onAttackButton_pressed() -> void:
	var battle=0
	var battle_cnt=0
	if troops:
		if troops_attack:
			if selected_province.get_occupation()==player_id:
				troops=troops-troops_attack
				ProvincesManager.player_try_update_province(selected_province, player_id, selected_province.get_troops()+troops_attack)
			else:
				troops=troops-troops_attack
				battle=abs(selected_province.get_troops()-troops_attack)
				if selected_province.get_troops():
					selected_province.set_troops(clamp(selected_province.get_troops()-troops_attack, 0, 10))
				if selected_province.get_troops()==0:
					ProvincesManager.player_try_update_province(selected_province, player_id, battle)
					if (battle_cnt<2):
						troops+=1
				battle_cnt+=1
			$PlayerUI/AttackPanel/TroopSlider.max_value=troops
