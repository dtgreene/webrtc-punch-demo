extends Control

const PlayerScene = preload("res://scenes/player.tscn")
const PeerPlayerScene = preload("res://scenes/peer_player.tscn")

@onready var client: Node = $Client
@onready var loading_label: Label = $Loading
@onready var lobby: Control = $Lobby
@onready var lobby_code_label: Label = $Lobby/VBoxContainer1/HBoxContainer1/LobbyCode
@onready var lobby_timer: Timer = $LobbyTimer
@onready var players: Node2D = $Lobby/Players

signal lobby_ended(message: String)

var player_info: Dictionary = {
	"player_name": ""
}
var peer_nodes: Dictionary = {}

func _ready() -> void:
	multiplayer.connected_to_server.connect(_handle_mp_connected_to_server)
	multiplayer.connection_failed.connect(_handle_mp_connection_failed)
	multiplayer.server_disconnected.connect(_handle_mp_server_disconnected)
	multiplayer.peer_connected.connect(_handle_mp_peer_connected)
	multiplayer.peer_disconnected.connect(_handle_mp_peer_disconnected)
	
	client.disconnected.connect(_handle_disconnected)
	client.join_lobby_success.connect(_handle_join_lobby_success)
	
	lobby_timer.timeout.connect(_handle_lobby_timeout)
	
	var copy_button: Button = $Lobby/VBoxContainer1/HBoxContainer1/CopyButton
	copy_button.button_up.connect(_handle_copy_button_clicked)
	
	var lobby_disconnect_button: Button = $Lobby/MarginContainer/Disconnect
	lobby_disconnect_button.button_up.connect(_handle_lobby_disconnect_clicked)

func _handle_mp_connected_to_server() -> void:
	print("[Multiplayer]: Connected to server")
	
	_create_player()

func _handle_mp_connection_failed() -> void:
	print("[Multiplayer]: Connection to server failed")

func _handle_mp_server_disconnected() -> void:
	print("[Multiplayer]: Disconnected from server")
	
	_go_back("Server closed connection")

func _handle_mp_peer_connected(id: int) -> void:
	print("[Multiplayer]: Peer connected %s" % id)
	_register_player.rpc_id(id, player_info)

func _handle_mp_peer_disconnected(id: int) -> void:
	print("[Multiplayer]: Peer disconnected %s" % id)
	_remove_peer_player(id)

func _handle_disconnected() -> void:
	print("[Signaling]: Disconnected")

func _handle_join_lobby_success(id: int, code: String) -> void:
	print("[Signaling]: Join lobby success")
	
	loading_label.hide()
	lobby.show()
	
	lobby_timer.stop()
	lobby_code_label.text = "Lobby code: %s" % code
	client.lobby_code = code
	
	if multiplayer.get_unique_id() == 1:
		_create_player()

func _handle_lobby_timeout() -> void:
	_go_back("Timeout during join")

func _handle_copy_button_clicked() -> void:
	DisplayServer.clipboard_set(client.lobby_code)

func _handle_lobby_disconnect_clicked() -> void:
	_go_back()

func _go_back(message: String = "") -> void:
	for child in players.get_children():
		child.queue_free()
	
	client.stop()
	lobby_ended.emit(message)

func _create_player() -> void:
	var player: Node2D = PlayerScene.instantiate()

	players.add_child(player)
	player.set_player_name(player_info.player_name)
	player.position = Vector2(320, 240)

func _remove_peer_player(id: int) -> void:
	if peer_nodes.has(id):
		peer_nodes[id].queue_free()

func start(code: String, player_name: String) -> void:
	loading_label.show()
	lobby.hide()
	
	for child in players.get_children():
		child.queue_free()
	
	player_info.player_name = player_name
	
	client.start("wss://webrtc-punch-demo-server.fly.dev/", code)
	lobby_timer.start()

@rpc("any_peer", "reliable")
func _register_player(other_player_info: Dictionary):
	var other_id: int = multiplayer.get_remote_sender_id()
	var peer_player: Node2D = PeerPlayerScene.instantiate()
	
	players.add_child(peer_player)
	
	peer_player.set_player_name(other_player_info.player_name)
	peer_player.set_initial_position(Vector2(320, 240))
	peer_player.player_id = other_id
	
	peer_nodes[other_id] = peer_player

@rpc("any_peer")
func peer_update(data: PackedByteArray):
	var other_id: int = multiplayer.get_remote_sender_id()
	
	if peer_nodes.has(other_id):
		peer_nodes[other_id].peer_sync(data)
