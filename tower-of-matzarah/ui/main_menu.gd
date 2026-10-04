extends CenterContainer
## Host / Join menu. Calls Network and shows what it reports back.

# `%Name` finds a node marked "unique name in owner" anywhere in this scene,
# so moving widgets around in the layout won't break these paths.
@onready var _address_input: LineEdit = %AddressInput
@onready var _host_button: Button = %HostButton
@onready var _join_button: Button = %JoinButton
@onready var _status_label: Label = %StatusLabel


func _ready() -> void:
	_host_button.pressed.connect(_on_host_pressed)
	_join_button.pressed.connect(_on_join_pressed)
	Network.connected_to_host.connect(_on_connected_to_host)
	Network.connection_failed.connect(_on_connection_failed)
	Network.player_connected.connect(_on_player_connected)
	Network.server_disconnected.connect(_on_server_disconnected)
	_host_button.grab_focus()


func _on_host_pressed() -> void:
	var error := Network.host_game()
	if error != OK:
		_status_label.text = "Couldn't host on port %d (%s)." % [Network.PORT, error_string(error)]
		return
	_set_buttons_enabled(false)
	_status_label.text = "Hosting on port %d. Waiting for players..." % Network.PORT


func _on_join_pressed() -> void:
	var address := _address_input.text.strip_edges()
	if address.is_empty():
		address = Network.DEFAULT_ADDRESS
	var error := Network.join_game(address)
	if error != OK:
		_status_label.text = "Couldn't start connecting (%s)." % error_string(error)
		return
	_set_buttons_enabled(false)
	_status_label.text = "Connecting to %s..." % address


func _on_connected_to_host() -> void:
	_status_label.text = "Connected as peer %d." % multiplayer.get_unique_id()


func _on_connection_failed(reason: String) -> void:
	_status_label.text = reason
	_set_buttons_enabled(true)


func _on_player_connected(peer_id: int) -> void:
	if multiplayer.is_server():
		_status_label.text = "Player %d joined." % peer_id


func _on_server_disconnected() -> void:
	_status_label.text = "The host left the game."
	_set_buttons_enabled(true)
	_host_button.grab_focus()


func _set_buttons_enabled(enabled: bool) -> void:
	_host_button.disabled = not enabled
	_join_button.disabled = not enabled
	_address_input.editable = enabled
