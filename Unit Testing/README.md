# Pantheos 4C - Unit Testing Suite

This directory contains comprehensive unit tests for the Pantheos 4C game using the GdUnit4 testing framework.

## 📁 Files

- `test_suite.gd` - Main test suite with 25+ test cases covering all game systems
- `run_tests.gd` - Test runner script for programmatic test execution
- `test_runner.tscn` - Scene file for running tests in Godot editor
- `README.md` - This documentation file

## 🧪 Test Coverage

The test suite covers the following game systems:

### Core Systems
- **Player System** (4 tests) - Health, stats, movement, abilities
- **Player Manager** (5 tests) - Leveling, positioning, health management
- **Enemy System** (4 tests) - Health, damage, state management
- **Inventory System** (4 tests) - Item management, equipment, slots

### Game Features
- **Quest System** (5 tests) - Quest updates, rewards, completion
- **Save System** (3 tests) - Save/load functionality
- **Item System** (2 tests) - Item data and effects

### Advanced Testing
- **Integration Tests** (2 tests) - System interactions
- **Edge Case Tests** (3 tests) - Error conditions and boundary cases

## 🚀 Running Tests

### Method 1: GdUnit4 Plugin (Recommended)
1. Open your project in Godot
2. Go to the GdUnit4 panel (usually in the bottom dock)
3. Select `test_suite.gd` from the test list
4. Click "Run" to execute all tests

### Method 2: Test Runner Scene
1. Open `test_runner.tscn` in Godot
2. Run the scene (F6 or Play button)
3. Check the output console for test results

### Method 3: Command Line
```bash
# If Godot is in your PATH
godot --headless --script "Unit Testing/test_suite.gd"

# Or run the test runner scene
godot --headless --scene "Unit Testing/test_runner.tscn"
```

## 🔧 Test Structure

Each test follows this pattern:
```gdscript
func test_feature_name():
    # Setup test data
    var test_object = SomeClass.new()
    add_child(test_object)
    
    # Perform test actions
    test_object.doSomething()
    
    # Assert expected results
    assert_that(test_object.property).is_equal(expected_value)
    
    # Cleanup is handled by the after() method
```

## 📋 Test Categories

### Player Tests
- `test_player_initialization()` - Verifies default player state
- `test_player_direction_setting()` - Tests movement direction
- `test_player_health_management()` - Tests health system
- `test_player_stats_modification()` - Tests stat changes

### Player Manager Tests
- `test_player_manager_initialization()` - Tests singleton setup
- `test_player_health_setting()` - Tests health management
- `test_player_position_setting()` - Tests position updates
- `test_xp_reward_system()` - Tests level advancement
- `test_camera_shake()` - Tests camera effects

### Enemy Tests
- `test_enemy_initialization()` - Tests enemy creation
- `test_enemy_direction_setting()` - Tests enemy movement
- `test_enemy_damage_system()` - Tests damage mechanics
- `test_enemy_destruction()` - Tests enemy death

### Inventory Tests
- `test_inventory_initialization()` - Tests inventory setup
- `test_inventory_slot_management()` - Tests slot organization
- `test_item_addition()` - Tests adding items
- `test_inventory_item_usage()` - Tests using items

### Quest Tests
- `test_quest_manager_initialization()` - Tests quest system setup
- `test_quest_creation()` - Tests creating new quests
- `test_quest_step_completion()` - Tests quest progress
- `test_quest_completion()` - Tests quest finishing
- `test_quest_finding()` - Tests quest lookup

### Save System Tests
- `test_save_manager_initialization()` - Tests save system setup
- `test_save_data_structure()` - Tests save data format
- `test_save_file_operations()` - Tests file operations

### Item System Tests
- `test_item_data_initialization()` - Tests item creation
- `test_item_usage()` - Tests item effects

### Integration Tests
- `test_player_enemy_interaction()` - Tests combat interaction
- `test_inventory_quest_integration()` - Tests reward system

### Edge Case Tests
- `test_negative_health()` - Tests error handling
- `test_inventory_overflow()` - Tests capacity limits
- `test_quest_duplicate_steps()` - Tests duplicate prevention

## 🛠️ Adding New Tests

To add new tests:

1. Add a new function starting with `test_` in `test_suite.gd`
2. Follow the existing pattern:
   - Setup test data
   - Perform actions
   - Assert results
3. Use descriptive function names
4. Add comments explaining what the test does

Example:
```gdscript
func test_new_feature():
    # Test description
    var test_object = NewClass.new()
    add_child(test_object)
    
    # Test the feature
    test_object.doNewThing()
    
    # Verify results
    assert_that(test_object.result).is_equal(expected_value)
```

## 🐛 Troubleshooting

### Common Issues

1. **Tests not running**: Make sure GdUnit4 plugin is enabled
2. **Class not found errors**: Check that all preload paths are correct
3. **Test failures**: Check the console output for detailed error messages

### Debug Tips

- Use `print()` statements in tests for debugging
- Check the GdUnit4 output panel for detailed test results
- Verify that all required classes are properly preloaded

## 📚 Resources

- [GdUnit4 Documentation](https://mikeschulze.github.io/gdUnit4/)
- [Godot Testing Best Practices](https://docs.godotengine.org/en/stable/tutorials/scripting/testing.html)
- [Unit Testing Guidelines](https://en.wikipedia.org/wiki/Unit_testing)

## 🤝 Contributing

When adding new features to the game:
1. Write tests first (TDD approach)
2. Ensure all tests pass
3. Add tests for edge cases
4. Update this README if needed

Happy testing! 🎮
