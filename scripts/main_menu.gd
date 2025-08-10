extends Control

@onready var main_screen: Control = $MainScreen
@onready var lobby_screen: Control = $LobbyScreen
@onready var join_form: Control = $MainScreen/VBoxContainer1/VBoxContainer1/JoinForm
@onready var lobby_message: Label = $MainScreen/LobbyMessage

var screen_index: int = 0
var lobby_code_regex: RegEx = RegEx.new()

func _ready() -> void:
	lobby_code_regex.compile("(?i)([a-z]|\\d){8}")
	
	lobby_screen.lobby_ended.connect(_handle_lobby_ended)
	
	var host_join_button: OptionButton = $MainScreen/VBoxContainer1/HostJoinButton
	var connect_button: Button = $MainScreen/VBoxContainer1/Connect

	host_join_button.item_selected.connect(_handle_host_join_selected)
	connect_button.button_up.connect(_handle_connect_clicked)

func _handle_lobby_ended(message: String = "") -> void:
	lobby_screen.hide()
	main_screen.show()
	
	if message.length() > 0:
		lobby_message.text = message

func _handle_host_join_selected(index: int) -> void:
	if index == 0:
		join_form.hide()
	else:
		join_form.show()
	
	screen_index = index

func _handle_connect_clicked() -> void:
	var player_name_input: LineEdit = $MainScreen/VBoxContainer1/VBoxContainer1/VBoxContainer1/PlayerName
	var player_name_input_error: Label = $MainScreen/VBoxContainer1/VBoxContainer1/VBoxContainer1/PlayerNameError
	var player_name: String = player_name_input.text
	
	if player_name.length() == 0:
		player_name_input_error.show()
		player_name_input_error.text = "Invalid name"
		return
	else:
		player_name_input_error.hide()
	
	if screen_index == 0:
		_join_lobby("", player_name)
	else:
		var lobby_code_input: LineEdit = $MainScreen/VBoxContainer1/VBoxContainer1/JoinForm/LobbyCode
		var lobby_code_input_error: Label = $MainScreen/VBoxContainer1/VBoxContainer1/JoinForm/LobbyCodeError
		var code: String = lobby_code_input.text.to_upper()

		if (lobby_code_regex.search(code)):
			lobby_code_input_error.hide()
			_join_lobby(code, player_name)
		else:
			lobby_code_input_error.show()
			lobby_code_input_error.text = "Invalid code"

func _join_lobby(code: String, player_name: String) -> void:
	main_screen.hide()
	lobby_screen.show()
	lobby_message.text = ""
	
	lobby_screen.start(code, player_name)
