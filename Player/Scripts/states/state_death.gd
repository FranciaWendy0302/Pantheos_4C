class_name State_Death extends State

@export var exhaust_audio: AudioStream
@export var knockdown_duration: float = 3.0  # Auto-revive after 3 seconds
@onready var audio: AudioStreamPlayer2D = $"../../Audio/AudioStreamPlayer2D"
@onready var idle: State = $"../Idle"

var knockdown_timer: float = 0.0

func init() -> void:
	pass
	
func Enter() -> void:
	# Play knockdown animation (death animation)
	if player.animation_player:
		player.animation_player.play("death")
	if audio:
		audio.stream = exhaust_audio
		audio.play()
	
	# Start knockdown timer
	knockdown_timer = knockdown_duration
	
	# Make player invulnerable while knocked down
	player.invulnerable = true
	
	print("[Knockdown] Player knocked down! Auto-reviving in ", knockdown_duration, " seconds...")
	pass

func Exit() -> void:
	# Restore vulnerability
	player.invulnerable = false
	# Re-enable hit detection
	if player.hit_box:
		player.hit_box.monitoring = true
	print("[Knockdown] Player is now vulnerable again")
	pass
	
func Process(delta: float) -> State:
	player.velocity = Vector2.ZERO
	
	# Count down to auto-revive
	knockdown_timer -= delta
 	
	if knockdown_timer <= 0:
		# Auto-revive!
		print("[Knockdown] Auto-reviving player!")
		player.update_hp(int(player.max_hp / 2.0))  # Restore to 50% HP
		# Call revival method for class-specific effects
		if player.has_method("_on_revive"):
			player.call("_on_revive")
		return idle
	
	return null

func Physics(_delta: float) -> State:
	return null
	
func HandleInput(_event: InputEvent) -> State:
	return null
