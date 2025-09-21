extends Node

# Test runner for Pantheos 4C Test Suite
# This script demonstrates how to run the test suite programmatically

func _ready():
	print("Starting Pantheos 4C Test Suite...")
	
	# Load and instantiate the test suite
	var test_suite_script = load("res://Unit Testing/test_suite.gd")
	var test_suite = test_suite_script.new()
	
	# Add to scene tree
	add_child(test_suite)
	
	# Wait a frame for initialization
	await get_tree().process_frame
	
	# Run the test suite
	await run_test_suite(test_suite)
	
	print("Test execution completed!")
	get_tree().quit()

func run_test_suite(test_suite: GdUnitTestSuite):
	# This is a simplified test runner
	# In practice, you would use GdUnit4's built-in test execution
	print("Running test suite...")
	
	# Get all test methods
	var test_methods = []
	for method in test_suite.get_script().get_script_method_list():
		if method.name.begins_with("test_"):
			test_methods.append(method.name)
	
	print("Found %d test methods:" % test_methods.size())
	for method_name in test_methods:
		print("  - %s" % method_name)
	
	# Note: This is a basic example
	# For full test execution, use GdUnit4's test runner or the Godot editor plugin
