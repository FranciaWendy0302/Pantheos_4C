@tool
extends EditorScript

## Batch update class requirements for items
## Edit the arrays below, then run this script from Script Editor → File → Run

# Add item paths and their required class
var swordsman_items = [
	"res://Items/equipment/swordsman/knight_helmet.tres",
	"res://Items/equipment/swordsman/knight_armor.tres",
	"res://Items/equipment/swordsman/knight_sword.tres",
	# Add more swordsman items here
]

var archer_items = [
	"res://Items/equipment/archer/hunter_bow.tres",
	"res://Items/equipment/archer/hunter_vest.tres",
	# Add more archer items here
]

var mage_items = [
	"res://Items/equipment/mage/fire_mage_staff.tres",
	"res://Items/equipment/mage/fire_mage_robe.tres",
	# Add more mage items here
]

func _run():
	print("=== Setting Class Requirements ===")
	
	var updated_count = 0
	
	# Update Swordsman items
	for path in swordsman_items:
		if _set_class_requirement(path, EquipableItemData.ClassRequirement.SWORDSMAN):
			updated_count += 1
	
	# Update Archer items
	for path in archer_items:
		if _set_class_requirement(path, EquipableItemData.ClassRequirement.ARCHER):
			updated_count += 1
	
	# Update Mage items
	for path in mage_items:
		if _set_class_requirement(path, EquipableItemData.ClassRequirement.MAGE):
			updated_count += 1
	
	print("=== Complete! Updated %d items ===" % updated_count)
	print("Remember to save the project to persist changes!")

func _set_class_requirement(item_path: String, requirement: EquipableItemData.ClassRequirement) -> bool:
	if not ResourceLoader.exists(item_path):
		print("⚠ Item not found: ", item_path)
		return false
	
	var item = load(item_path) as EquipableItemData
	if not item:
		print("⚠ Not an EquipableItemData: ", item_path)
		return false
	
	item.class_requirement = requirement
	
	var err = ResourceSaver.save(item, item_path)
	if err == OK:
		var class_name = item.get_class_requirement_name()
		print("✓ Set %s → %s" % [item_path.get_file(), class_name])
		return true
	else:
		print("✗ Failed to save: ", item_path)
		return false
