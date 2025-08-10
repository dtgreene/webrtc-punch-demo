extends Node2D

@onready var lobby_screen: Control = get_node("/root/MainMenu/LobbyScreen")
@onready var character_sprites: AnimatedSprite2D = $CharacterSprites
@onready var player_name_label: Label = $PlayerName

const movement_speed: float = 128.0
const update_tick_rate: int = 4

var update_tick: int = 0
var player_name: String = ""

func _physics_process(delta: float) -> void:
	var input_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if input_vector.x != 0:
		position.x += input_vector.x * movement_speed * delta
		position.x = clampf(position.x, 0, 640)
		
		if input_vector.x > 0:
			character_sprites.walk_right()
		else:
			character_sprites.walk_left()
	elif input_vector.y != 0:
		position.y += input_vector.y * movement_speed * delta
		position.y = clampf(position.y, 0, 480)
		
		if input_vector.y > 0:
			character_sprites.walk_down()
		else:
			character_sprites.walk_up()
	else:
		character_sprites.idle()
	
	update_tick += 1
	
	if update_tick >= update_tick_rate:
		update_tick = 0
		
		var data = PackedByteArray()
		data.resize(8)
		data.encode_float(0, position.x)
		data.encode_float(4, position.y)
		
		lobby_screen.peer_update.rpc(data)

func set_player_name(_player_name: String) -> void:
	player_name = _player_name
	player_name_label.text = _player_name
