extends Node

# Mobile Network Manager
# Handles Android-specific networking considerations and optimizations

signal network_status_changed(is_connected: bool, connection_type: String)
signal connection_quality_changed(quality: String)

enum ConnectionType {
	NONE,
	WIFI,
	CELLULAR,
	ETHERNET,
	UNKNOWN
}

enum ConnectionQuality {
	EXCELLENT,
	GOOD,
	FAIR,
	POOR,
	OFFLINE
}

var current_connection_type: ConnectionType = ConnectionType.NONE
var current_quality: ConnectionQuality = ConnectionQuality.OFFLINE
var is_network_available: bool = false

# Mobile-specific settings
var use_mobile_optimizations: bool = true
var reduce_update_frequency: bool = false
var compress_data: bool = true

func _ready():
	if not PlatformManager.is_platform_android():
		print("Mobile Network Manager: Not on Android, disabling...")
		set_process(false)
		return
	
	print("Mobile Network Manager: Initializing for Android...")
	setup_mobile_networking()
	start_network_monitoring()

func setup_mobile_networking():
	# Request necessary Android permissions
	PlatformManager.request_android_permissions()
	
	# Wait a moment for permissions to be granted
	await get_tree().create_timer(1.0).timeout
	
	# Check initial network status
	check_network_status()
	
	# Apply mobile optimizations to NetworkManager
	apply_mobile_optimizations()

func apply_mobile_optimizations():
	if not NetworkManager:
		return
	
	print("Applying mobile network optimizations...")
	
	# Reduce WebSocket message frequency for mobile
	if use_mobile_optimizations:
		# Increase position update interval for mobile (save battery/data)
		if NetworkManager.has_method("set_position_update_interval"):
			NetworkManager.set_position_update_interval(0.1)  # 100ms instead of 50ms
		
		# Enable data compression if available
		if compress_data and NetworkManager.has_method("enable_compression"):
			NetworkManager.enable_compression(true)

func start_network_monitoring():
	# Monitor network status every 5 seconds
	var timer = Timer.new()
	timer.wait_time = 5.0
	timer.timeout.connect(check_network_status)
	timer.autostart = true
	add_child(timer)

func check_network_status():
	var was_connected = is_network_available
	var old_type = current_connection_type
	
	# Check if we have internet connectivity
	is_network_available = has_internet_connection()
	
	# Detect connection type (Android-specific)
	current_connection_type = detect_connection_type()
	
	# Assess connection quality
	current_quality = assess_connection_quality()
	
	# Emit signals if status changed
	if was_connected != is_network_available or old_type != current_connection_type:
		var type_name = get_connection_type_name(current_connection_type)
		network_status_changed.emit(is_network_available, type_name)
		print("Network status changed: ", "Connected" if is_network_available else "Disconnected", " (", type_name, ")")
	
	# Apply quality-based optimizations
	apply_quality_optimizations()

func has_internet_connection() -> bool:
	# Simple connectivity check - try to resolve a DNS name
	# This is a basic check; in production you might want to ping a server
	return OS.has_feature("network")

func detect_connection_type() -> ConnectionType:
	if not is_network_available:
		return ConnectionType.NONE
	
	# On Android, we can check network type through OS calls
	# This is a simplified version - real implementation would use Android APIs
	
	# For now, assume WiFi if connected (most common on mobile)
	# In a real implementation, you'd use Android's ConnectivityManager
	return ConnectionType.WIFI

func assess_connection_quality() -> ConnectionQuality:
	if not is_network_available:
		return ConnectionQuality.OFFLINE
	
	# Simple quality assessment based on connection type
	match current_connection_type:
		ConnectionType.WIFI:
			return ConnectionQuality.GOOD
		ConnectionType.CELLULAR:
			return ConnectionQuality.FAIR
		ConnectionType.ETHERNET:
			return ConnectionQuality.EXCELLENT
		_:
			return ConnectionQuality.POOR

func apply_quality_optimizations():
	var quality_name = get_quality_name(current_quality)
	
	match current_quality:
		ConnectionQuality.EXCELLENT, ConnectionQuality.GOOD:
			# High quality - normal settings
			reduce_update_frequency = false
			compress_data = false
		
		ConnectionQuality.FAIR:
			# Medium quality - light optimizations
			reduce_update_frequency = true
			compress_data = true
		
		ConnectionQuality.POOR:
			# Poor quality - aggressive optimizations
			reduce_update_frequency = true
			compress_data = true
			# Could also reduce graphics quality, disable non-essential features
		
		ConnectionQuality.OFFLINE:
			# No connection - switch to offline mode
			handle_offline_mode()
	
	connection_quality_changed.emit(quality_name)

func handle_offline_mode():
	print("Mobile Network: Switching to offline mode")
	
	# Disconnect from server if connected
	if NetworkManager and NetworkManager.has_method("disconnect_from_nodejs_server"):
		NetworkManager.disconnect_from_nodejs_server()
	
	# Show offline notification to user
	show_offline_notification()

func show_offline_notification():
	# Create a simple notification
	var notification = AcceptDialog.new()
	notification.title = "Network Offline"
	notification.dialog_text = "No internet connection detected.\nSome features may be unavailable."
	
	# Add to scene tree
	get_tree().current_scene.add_child(notification)
	notification.popup_centered()
	
	# Auto-close after 3 seconds
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(notification):
		notification.queue_free()

func get_connection_type_name(type: ConnectionType) -> String:
	match type:
		ConnectionType.WIFI:
			return "WiFi"
		ConnectionType.CELLULAR:
			return "Cellular"
		ConnectionType.ETHERNET:
			return "Ethernet"
		ConnectionType.NONE:
			return "None"
		_:
			return "Unknown"

func get_quality_name(quality: ConnectionQuality) -> String:
	match quality:
		ConnectionQuality.EXCELLENT:
			return "Excellent"
		ConnectionQuality.GOOD:
			return "Good"
		ConnectionQuality.FAIR:
			return "Fair"
		ConnectionQuality.POOR:
			return "Poor"
		ConnectionQuality.OFFLINE:
			return "Offline"
		_:
			return "Unknown"

# Public functions for game integration
func is_connected() -> bool:
	return is_network_available

func get_connection_info() -> Dictionary:
	return {
		"connected": is_network_available,
		"type": get_connection_type_name(current_connection_type),
		"quality": get_quality_name(current_quality)
	}

func can_use_high_bandwidth_features() -> bool:
	return current_quality in [ConnectionQuality.EXCELLENT, ConnectionQuality.GOOD]

func should_reduce_network_usage() -> bool:
	return current_quality in [ConnectionQuality.FAIR, ConnectionQuality.POOR]

# Mobile-specific network optimizations
func optimize_for_battery_life():
	print("Optimizing network usage for battery life...")
	
	# Reduce update frequencies
	reduce_update_frequency = true
	
	# Enable all compression
	compress_data = true
	
	# Could also:
	# - Reduce animation sync frequency
	# - Batch network requests
	# - Use lower quality assets

func optimize_for_data_usage():
	print("Optimizing network usage for data conservation...")
	
	# Enable aggressive compression
	compress_data = true
	
	# Reduce non-essential network traffic
	if NetworkManager:
		# Could disable features like:
		# - Real-time position sync for distant players
		# - High-frequency monster updates
		# - Chat message history sync

# Connection retry logic for mobile
func attempt_reconnection():
	if not is_network_available:
		print("Mobile Network: No connection available for retry")
		return false
	
	print("Mobile Network: Attempting to reconnect...")
	return true
	# Try to reconnect to the game server
	if NetworkManager and NetworkManager.has_method("connect_to_nodejs_server"):
		# Get stored connection info
		var player_id = PlayerManager.player_id if PlayerManager else 1
		var nickname = PlayerManager.nickname if PlayerManager else "Player"
		var character_class = PlayerManager.character_class if PlayerManager else "warrior"
		
		NetworkManager.connect_to_nodejs_server(player_id, nickname, character_class)
		return true
	
	return false

func _notification(what):
	# Handle Android app lifecycle events
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			print("Mobile Network: App paused - reducing network activity")
			optimize_for_battery_life()
		
		NOTIFICATION_APPLICATION_RESUMED:
			print("Mobile Network: App resumed - checking network status")
			check_network_status()
			if is_network_available:
				attempt_reconnection()
				attempt_reconnection()