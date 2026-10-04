extends Node
## Owns the network connection: hosting, joining, and leaving.
## This is the only script that knows the transport (ENet now, Steam later).

const GAME_ID := "tower_of_matzarah"
const PORT := 7777
const MAX_CLIENTS := 7  # 8 players total, counting the host
const DEFAULT_ADDRESS := "127.0.0.1"

## A peer joined the game. On the host this is a new client; on a client it is
## the host or another client becoming visible.
signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
## Host only: the server is up and accepting connections.
signal hosting_started
## Client only: the connection to the host is up.
signal connected_to_host
## Client only: could not connect (or was rejected). `reason` is player-facing.
signal connection_failed(reason: String)
## Client only: the host left or the connection dropped.
signal server_disconnected


func _ready() -> void:
	# `multiplayer` is the SceneMultiplayer that every node can reach.
	# These signals fire no matter which transport (ENet/Steam) is in use.
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	# Setting an auth callback holds every new connection in an authentication
	# stage: no peer_connected, RPCs, or spawns until both sides complete_auth().
	var scene_multiplayer := multiplayer as SceneMultiplayer
	scene_multiplayer.auth_callback = _on_auth_received
	scene_multiplayer.peer_authenticating.connect(_on_peer_authenticating)
	scene_multiplayer.peer_authentication_failed.connect(_on_peer_authentication_failed)


func _notification(what: int) -> void:
	# Closing the window would otherwise just drop off the network, and the
	# other side would need ENet's 5–30 s timeout to notice. Closing the peer
	# tells them right away.
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		leave_game()


func host_game() -> Error:
	var peer := ENetMultiplayerPeer.new()
	# Fails with ERR_CANT_CREATE if another program already uses the port.
	var error := peer.create_server(PORT, MAX_CLIENTS)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	print("[Network] Hosting on port %d as peer %d (v%s)" % [PORT, multiplayer.get_unique_id(), get_game_version()])
	hosting_started.emit()
	return OK


func join_game(address: String) -> Error:
	var peer := ENetMultiplayerPeer.new()
	# Returns OK even if nobody is hosting there: the failure arrives later
	# through multiplayer.connection_failed, once ENet gives up.
	var error := peer.create_client(address, PORT)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	print("[Network] Connecting to %s:%d (v%s)" % [address, PORT, get_game_version()])
	return OK


func leave_game() -> void:
	multiplayer.multiplayer_peer.close()
	# The offline peer is Godot's default "not connected" state.
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()


func get_game_version() -> String:
	# Debug builds only: `--version-override=X` after `--` on the command line
	# fakes a different version, so the mismatch path can be tested locally.
	if OS.is_debug_build():
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--version-override="):
				return arg.get_slice("=", 1)
	return ProjectSettings.get_setting("application/config/version", "0.0.0")


# --- Authentication (version check) ---

func _on_peer_authenticating(peer_id: int) -> void:
	# Fires on both sides. Only the client speaks first; the host waits for data.
	if multiplayer.is_server():
		return
	var handshake := {"game": GAME_ID, "version": get_game_version()}
	var scene_multiplayer := multiplayer as SceneMultiplayer
	scene_multiplayer.send_auth(peer_id, var_to_bytes(handshake))
	# The client trusts the host; the host still has to complete its side.
	scene_multiplayer.complete_auth(peer_id)


func _on_auth_received(peer_id: int, data: PackedByteArray) -> void:
	# bytes_to_var() (not _with_objects) refuses to decode objects, so a
	# malicious peer can't make us instantiate scripts.
	var message: Variant = bytes_to_var(data)
	if multiplayer.is_server():
		_check_client_handshake(peer_id, message)
	else:
		_handle_host_rejection(message)


func _check_client_handshake(peer_id: int, message: Variant) -> void:
	var scene_multiplayer := multiplayer as SceneMultiplayer
	var reason := ""
	if not message is Dictionary:
		reason = "Invalid handshake."
	elif message.get("game", "") != GAME_ID:
		reason = "That host is running a different game."
	elif message.get("version", "") != get_game_version():
		reason = "Version mismatch: host has v%s, you have v%s." % [get_game_version(), message.get("version", "?")]

	if reason.is_empty():
		scene_multiplayer.complete_auth(peer_id)
		return
	print("[Network] Rejected peer %d: %s" % [peer_id, reason])
	# We never complete auth for this peer; if it ignores the reason and stays,
	# auth_timeout drops it automatically.
	scene_multiplayer.send_auth(peer_id, var_to_bytes({"rejected": reason}))


func _handle_host_rejection(message: Variant) -> void:
	var reason := "The host rejected the connection."
	if message is Dictionary and message.get("rejected", "") is String:
		reason = message["rejected"]
	leave_game()
	connection_failed.emit(reason)


func _on_peer_authentication_failed(peer_id: int) -> void:
	print("[Network] Peer %d failed authentication (timed out)" % peer_id)
	if not multiplayer.is_server():
		leave_game()
		connection_failed.emit("The host didn't accept the connection.")


# --- Connection events ---

func _on_peer_connected(peer_id: int) -> void:
	print("[Network] Peer %d connected" % peer_id)
	player_connected.emit(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	print("[Network] Peer %d disconnected" % peer_id)
	player_disconnected.emit(peer_id)


func _on_connected_to_server() -> void:
	print("[Network] Connected to host as peer %d" % multiplayer.get_unique_id())
	connected_to_host.emit()


func _on_connection_failed() -> void:
	leave_game()
	connection_failed.emit("Couldn't reach the host.")


func _on_server_disconnected() -> void:
	leave_game()
	server_disconnected.emit()
