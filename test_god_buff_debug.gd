extends SceneTree

func _init():
	print("=== God Buff Debug Test ===")
	
	var base_attack = 50
	var zeus_buff = 0.10  # 10% lightning damage
	var buffed_attack = base_attack * (1 + zeus_buff)
	
	print("Base attack: ", base_attack)
	print("Zeus buff: ", zeus_buff)
	print("Calculation: ", base_attack, " * (1 + ", zeus_buff, ") = ", base_attack, " * ", (1 + zeus_buff), " = ", buffed_attack)
	print("Expected: 55.0")
	print("Actual: ", buffed_attack)
	print("Type of result: ", typeof(buffed_attack))
	print("Exact comparison (== 55.0): ", buffed_attack == 55.0)
	print("Exact comparison (== 55): ", buffed_attack == 55)
	print("Approximate comparison (abs diff < 0.001): ", abs(buffed_attack - 55.0) < 0.001)
	
	if abs(buffed_attack - 55.0) < 0.001:
		print("✅ PASS: God buff applied correctly (+10%)")
	else:
		print("❌ FAIL: God buff application failed - Expected: 55.0, Got: ", buffed_attack)
	
	quit(0)