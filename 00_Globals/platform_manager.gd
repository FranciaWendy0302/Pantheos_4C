extends Node

# Platform Detection and Management System
# Ensures the game only runs on Android devices

signal platform_validated
signal platform_rejected(reason: String)

enum PlatformType {
	ANDROID,
	IOS,
	WINDOWS,
	LINUX,
	MACOS,
	WEB,
	UNKNOWN
}

var current_platform: PlatformType
var is_mobile: bool = false
var is_android_only: bool = true  # Set to true for Android-only mode

func _ready():
	detect_platform()
	validate_platform()

func detect_platform() -> void:
	var os_name = OS.get_name()
	
	match os_name:
		"Android":
			current_platform = PlatformType.ANDROID
			is_mobile = true
		"iOS":
			current_platform = PlatformType.IOS
			is_mobile = true
		"Windows":
			current_platform = PlatformType.WINDOWS
		"Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			current_platform = PlatformType.LINUX
		"macOS":
			current_platform = PlatformType.MACOS
		"Web":
			current_platform = PlatformType.WEB
		_:
			current_platform = PlatformType.UNKNOWN
	
	print("Platform detected: ", get_platform_name())

func validate_platform() -> void:
	if is_android_only and current_platform != PlatformType.ANDROID:
		var reason = "This game is designed exclusively for Android devices. Current platform: " + get_platform_name()
		print("ERROR: ", reason)
		platform_rejected.emit(reason)
		show_platform_error(reason)
		return
	
	print("Platform validation successful!")
	platform_validated.emit()

func show_platform_error(reason: String) -> void:
	# Create error dialog
	var dialog = AcceptDialog.new()
	dialog.title = "Platform Not Supported"
	dialog.dialog_text = reason + "\n\nThe application will now close."
	dialog.confirmed.connect(_quit_application)
	
	# Add to scene tree
	get_tree().current_scene.add_child(dialog)
	dialog.popup_centered()

func _quit_application() -> void:
	print("Quitting application due to platform restriction")
	get_tree().quit()

func get_platform_name() -> String:
	match current_platform:
		PlatformType.ANDROID:
			return "Android"
		PlatformType.IOS:
			return "iOS"
		PlatformType.WINDOWS:
			return "Windows"
		PlatformType.LINUX:
			return "Linux"
		PlatformType.MACOS:
			return "macOS"
		PlatformType.WEB:
			return "Web"
		_:
			return "Unknown"

func is_platform_android() -> bool:
	return current_platform == PlatformType.ANDROID

func is_platform_mobile() -> bool:
	return is_mobile

func get_screen_size() -> Vector2:
	return DisplayServer.screen_get_size()

func get_screen_dpi() -> int:
	return DisplayServer.screen_get_dpi()

# Android-specific functions
func request_android_permissions() -> void:
	if not is_platform_android():
		return
	
	var permissions = [
		"android.permission.INTERNET",
		"android.permission.ACCESS_NETWORK_STATE",
		"android.permission.WRITE_EXTERNAL_STORAGE",
		"android.permission.READ_EXTERNAL_STORAGE"
	]
	
	for permission in permissions:
		if not OS.request_permission(permission):
			print("Failed to request permission: ", permission)

func enable_android_optimizations() -> void:
	if not is_platform_android():
		return
	
	# Adjust quality settings for mobile
	var quality_settings = {
		"rendering/textures/canvas_textures/default_texture_filter": 1,  # Linear filter
		"rendering/anti_aliasing/quality/msaa_2d": 0,  # Disable MSAA for performance
		"rendering/anti_aliasing/quality/msaa_3d": 0,
		"rendering/shadows/shadow_atlas/size": 1024,  # Reduce shadow atlas size
		"rendering/reflections/reflection_atlas/reflection_size": 128
	}
	
	for setting in quality_settings:
		if ProjectSettings.has_setting(setting):
			ProjectSettings.set_setting(setting, quality_settings[setting])
	
	print("Android optimizations applied")