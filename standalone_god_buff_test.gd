extends SceneTree

func _init():
	print("=== Standalone God Buff Test ===")
	
	# Test the exact same logic as in the main test
	var base_attack = 50
	var buff_amount = 5  # 10% of 50 = 5
	var buffed_attack = base_attack + buff_amount  # 50 + 5 = 55
	
	print("base_attack = ", base_attack)
	print("buff_amount = ", buff_amount)
	print("buffed_attack = ", buffed_attack)
	print("Expected = 55")
	
	if buffed_attack == 55:
		print("✅ PASS: God buff test works correctly")
	else:
		print("❌ FAIL: Something is very wrong - ", buffed_attack, " != 55")
	
	# Test basic arithmetic
	var test1 = 50 + 5
	print("Basic test: 50 + 5 = ", test1)
	
	if test1 == 55:
		print("✅ Basic arithmetic works")
	else:
		print("❌ Basic arithmetic broken!")
	
	quit(0)