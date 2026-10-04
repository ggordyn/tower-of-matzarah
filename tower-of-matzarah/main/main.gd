extends Node
## Root scene: swaps between the menu and the world as Network events happen.

const TEST_ROOM := preload("res://levels/test_room.tscn")

@onready var _level: Node = $Level
@onready var _main_menu: Control = $UI/MainMenu


func _ready() -> void:
	Network.hosting_started.connect(_on_hosting_started)
	Network.connected_to_host.connect(_on_connected_to_host)
	Network.server_disconnected.connect(_on_server_disconnected)


func _on_hosting_started() -> void:
	_main_menu.hide()
	# Only the host adds the level; LevelSpawner recreates it on every client.
	_level.add_child(TEST_ROOM.instantiate())


func _on_connected_to_host() -> void:
	# The level itself arrives through LevelSpawner; we only hide the menu.
	_main_menu.hide()


func _on_server_disconnected() -> void:
	# The session is gone, but its spawned nodes are still here; clear them.
	for child in _level.get_children():
		child.queue_free()
	_main_menu.show()
