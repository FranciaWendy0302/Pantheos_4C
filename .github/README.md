# GitHub CI/CD for Pantheos 4C

This directory contains GitHub Actions workflows for automated testing, building, and releasing your Godot game.

## 🚀 Workflows Overview

### 1. **CI Pipeline** (`ci.yml`)
**Triggers**: Push to main/develop/gek branches, Pull Requests
**Purpose**: Complete CI/CD pipeline with testing and building

**Jobs**:
- ✅ **Test Suite**: Runs unit tests using GdUnit4
- 🏗️ **Build Linux**: Creates Linux builds
- 🏗️ **Build Windows**: Creates Windows builds  
- 🏗️ **Build macOS**: Creates macOS builds
- 📦 **Release**: Creates GitHub releases (main branch only)

### 2. **Test Suite** (`test.yml`)
**Triggers**: Push to main/develop/gek branches, Pull Requests, Manual dispatch
**Purpose**: Dedicated testing with multiple Godot versions

**Features**:
- 🧪 Tests on Godot 4.4 and 4.3
- 📊 Test coverage analysis
- 📋 Detailed test reports
- 🔄 Matrix testing strategy

### 3. **Build & Release** (`build.yml`)
**Triggers**: Push to main, Tags (v*), Manual dispatch
**Purpose**: Platform-specific builds and releases

**Features**:
- 🎯 Selective platform building
- 📦 Archive creation (tar.gz, zip)
- 🏷️ Automatic GitHub releases
- 🔧 Manual workflow dispatch

## 📋 Test Coverage

Your project includes comprehensive unit tests covering:

### Core Systems (32+ tests)
- **Player System** (4 tests) - Health, stats, movement, abilities
- **Player Manager** (5 tests) - Leveling, positioning, health management
- **Enemy System** (4 tests) - Health, damage, state management
- **Inventory System** (4 tests) - Item management, equipment, slots
- **Quest System** (5 tests) - Quest updates, rewards, completion
- **Save System** (3 tests) - Save/load functionality
- **Item System** (2 tests) - Item data and effects
- **Integration Tests** (2 tests) - System interactions
- **Edge Case Tests** (3 tests) - Error conditions and boundary cases

## 🛠️ Setup Instructions

### 1. Enable GitHub Actions
1. Go to your repository on GitHub
2. Click on "Actions" tab
3. Enable GitHub Actions if prompted

### 2. Configure Secrets (Optional)
For advanced features, you may need to configure secrets:
- `GITHUB_TOKEN`: Automatically provided by GitHub
- Custom secrets can be added in Settings → Secrets and variables → Actions

### 3. Test the Workflows
1. Push code to trigger the CI pipeline
2. Check the "Actions" tab to see workflow runs
3. Review test results and build artifacts

## 🔧 Manual Workflow Triggers

### Run Tests Only
1. Go to Actions → Test Suite
2. Click "Run workflow"
3. Select branch and click "Run workflow"

### Build Specific Platform
1. Go to Actions → Build & Release
2. Click "Run workflow"
3. Select platform: all, linux, windows, or macos
4. Click "Run workflow"

## 📦 Build Artifacts

### Linux Build
- **File**: `aarpg-linux.tar.gz`
- **Platform**: Linux X11
- **Architecture**: x86_64

### Windows Build
- **File**: `aarpg-windows.zip`
- **Platform**: Windows Desktop
- **Architecture**: x86_64

### macOS Build
- **File**: `aarpg-macos.zip`
- **Platform**: macOS
- **Architecture**: Universal

## 🏷️ Release Process

### Automatic Releases
Releases are automatically created when you push a tag:
```bash
git tag v1.0.0
git push origin v1.0.0
```

### Manual Releases
1. Go to Actions → Build & Release
2. Click "Run workflow"
3. Select "all" platforms
4. Click "Run workflow"
5. Check the "Releases" section for your new release

## 🧪 Testing Framework

### GdUnit4 Integration
Your project uses GdUnit4 for unit testing:
- **Plugin**: `addons/gdUnit4/`
- **Test Suite**: `Unit Testing/test_suite.gd`
- **Test Runner**: `Unit Testing/run_tests.gd`
- **Test Scene**: `Unit Testing/test_runner.tscn`

### Running Tests Locally
```bash
# Run custom test runner
godot --headless --script "Unit Testing/run_tests.gd" --quit

# Run GdUnit4 test suite
godot --headless --script "Unit Testing/test_suite.gd" --quit

# Run test runner scene
godot --headless --scene "Unit Testing/test_runner.tscn" --quit
```

## 🔍 Monitoring & Debugging

### View Workflow Logs
1. Go to Actions tab
2. Click on a workflow run
3. Click on individual jobs to see logs
4. Download artifacts if needed

### Common Issues

#### Tests Failing
- Check if GdUnit4 plugin is properly installed
- Verify test script paths are correct
- Review test output in workflow logs

#### Build Failures
- Ensure export presets are configured
- Check if all required assets are present
- Verify Godot version compatibility

#### Release Issues
- Check if tag format is correct (v1.0.0)
- Verify GitHub token permissions
- Review release creation logs

## 📚 Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Godot CI Action](https://github.com/godotengine/godot-ci-action)
- [GdUnit4 Documentation](https://mikeschulze.github.io/gdUnit4/)
- [Godot Export Documentation](https://docs.godotengine.org/en/stable/tutorials/export/)

## 🤝 Contributing

When contributing to this project:
1. Ensure all tests pass locally
2. Push to a feature branch
3. Create a pull request
4. Wait for CI to complete
5. Address any test failures
6. Merge when approved

## 📊 Workflow Status

You can add workflow status badges to your README:

```markdown
![CI](https://github.com/yourusername/yourrepo/workflows/CI%2FCD%20Pipeline/badge.svg)
![Tests](https://github.com/yourusername/yourrepo/workflows/Test%20Suite/badge.svg)
![Build](https://github.com/yourusername/yourrepo/workflows/Build%20%26%20Release/badge.svg)
```

---

**Happy Gaming! 🎮**
