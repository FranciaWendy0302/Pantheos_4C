extends SceneTree

func _init():
	print("=== Simple God Buff Test ===")
	
	# Test 1: Integer arithmetic
	var base_attack_int = 50
	var buff_percent = 10  # 10%
	var buffed_attack_int = base_attack_int + (base_attack_int * buff_percent / 100)
	print("Integer test: ", base_attack_int, " + (", base_attack_int, " * ", buff_percent, " / 100) = ", buffed_attack_int)
	
	if buffed_attack_int == 55:
		print("✅ Integer test PASSED")
	else:
		print("❌ Integer test FAILED")
	
	# Test 2: Float arithmetic (original)
	var base_attack = 50
	var zeus_buff = 0.10
	var buffed_attack = base_attack * (1 + zeus_buff)
	print("Float test: ", base_attack, " * (1 + ", zeus_buff, ") = ", buffed_attack)
	
	if buffed_attack == 55:
		print("✅ Float exact test PASSED")
	elif buffed_attack == 55.0:
		print("✅ Float exact 55.0 test PASSED")
	elif abs(buffed_attack - 55.0) < 0.001:
		print("✅ Float approximate test PASSED")
	else:
		print("❌ Float test FAILED - Got: ", buffed_attack)
	
	# Test 3: Simple multiplication
	var result = 50 * 1.1
	print("Direct multiplication: 50 * 1.1 = ", result)
	
	if result == 55:
		print("✅ Direct multiplication PASSED")
	else:
		print("❌ Direct multiplication FAILED - Got: ", result)
	
	quit(0)