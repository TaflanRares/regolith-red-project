extends CanvasLayer
@export var ProvinceTitle_label:Label
@export var ProvinceType_label:Label
@export var ProvinceOwner_label:Label
@export var ProvinceTroops_label:Label

func update_provinceInfo(province:Province):
	ProvinceTitle_label.text = province.get_title()
	ProvinceType_label.text = province.get_type()
	var occupier = str(province.get_occupation())
	var troopnr = str(province.get_troops())
	if occupier == "-1":
		occupier = "nobody"
	if troopnr == "0":
		troopnr = "none"
	ProvinceOwner_label.text = occupier
	ProvinceTroops_label.text = troopnr
	if ProvincesManager.all_provinces_have_same_occupation():
		$WinScreen.show()
