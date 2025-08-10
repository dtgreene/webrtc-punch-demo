extends Node2D

const lerp_speed: float = 15.0
const epsilon: float = 0.1

@onready var character_sprites: AnimatedSprite2D = $CharacterSprites
@onready var player_name_label: Label = $PlayerName

var target_position: Vector2 = position
var player_name: String = ""
var player_id: int = -1

func _physics_process(delta: float) -> void:
	var current_position: Vector2 = position
	var position_delta: Vector2 = target_position - position
	
	position = position.lerp(target_position, delta * lerp_speed)
	
	if abs(position_delta.x) > epsilon or abs(position_delta.y) > epsilon:
		if position_delta.x > epsilon:
			character_sprites.walk_right()
		elif position_delta.x < -epsilon:
			character_sprites.walk_left()
		elif position_delta.y > epsilon:
			character_sprites.walk_down()
		elif position_delta.y < -epsilon:
			character_sprites.walk_up()
	else:
		character_sprites.idle()

func peer_sync(data: PackedByteArray) -> void:
	target_position = Vector2(data.decode_float(0), data.decode_float(4))

func set_player_name(_player_name: String) -> void:
	player_name = _player_name
	player_name_label.text = _player_name

func set_initial_position(_position: Vector2) -> void:
	target_position = _position
	position = _position
