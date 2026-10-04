extends Node3D
## Test level. On the server, spawns one Player per connected peer.
## PlayerSpawner replicates each spawn to every client.

const PLAYER_SCENE := preload("res://player/player.tscn")

var _next_spawn_index := 0

@onready var _players: Node3D = $Players
@onready var _spawn_points: Array[Node] = $SpawnPoints.get_children()
@onready var _player_spawner: MultiplayerSpawner = $PlayerSpawner


func _ready() -> void:
	# Every peer must know how to build a player from spawn data, because the
	# spawner runs this same function on each machine.
	_player_spawner.spawn_function = _spawn_player

	# Only the server decides who gets a player. (Offline also counts as the
	# server, so running this scene on its own still spawns you.)
	if not multiplayer.is_server():
		return
	Network.player_connected.connect(_add_player)
	Network.player_disconnected.connect(_remove_player)
	_add_player(multiplayer.get_unique_id())
	for peer_id in multiplayer.get_peers():
		_add_player(peer_id)


func _add_player(peer_id: int) -> void:
	if _players.has_node(str(peer_id)):
		return
	var spawn_point: Marker3D = _spawn_points[_next_spawn_index % _spawn_points.size()]
	_next_spawn_index += 1
	# spawn() calls _spawn_player here and sends the same data to every client.
	_player_spawner.spawn({"peer_id": peer_id, "position": spawn_point.global_position})


func _remove_player(peer_id: int) -> void:
	var player := _players.get_node_or_null(str(peer_id))
	if player:
		# Freeing a spawned node makes PlayerSpawner remove it on every client.
		player.queue_free()


func _spawn_player(data: Dictionary) -> Node:
	var player := PLAYER_SCENE.instantiate()
	player.name = str(data["peer_id"])
	# Not in the tree yet, so set the local position. Players sits at the
	# origin, so local and world positions match.
	player.position = data["position"]
	return player
