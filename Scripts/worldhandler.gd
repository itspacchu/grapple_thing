extends Node3D

@onready var main_menu = $CanvasLayer/MainMenu
@onready var addr_entry = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/LineEdit
const PlayerEntity = preload("res://character.tscn")

const PORT = 12212
var enet_peer = ENetMultiplayerPeer.new()

func _ready():
	if "--server" in OS.get_cmdline_args():
		_on_host_pressed(false)
	pass

func _process(delta):
	$CanvasLayer/MainMenu/MarginContainer/VBoxContainer/HBoxContainer/Label3.text = str($CanvasLayer/MainMenu/MarginContainer/VBoxContainer/HBoxContainer/HSlider.value)

func add_player(peer_id,nickname:String="",sens=1):
	var player = PlayerEntity.instantiate()
	player.name = str(peer_id)
	if(nickname==null or nickname==""):
		if(peer_id == 1):
			player.player_nick="Host"
		else:
			player.player_nick=str(peer_id)
	else:
		nickname = nickname.replace(" ","").substr(0,10)
		player.player_nick=str(nickname)
		player.SENS = sens
	add_child(player)

func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if(player):
		player.queue_free()

func _on_host_pressed(spawnPlayer:bool=true):
	main_menu.hide()
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	if(spawnPlayer):
		add_player(multiplayer.get_unique_id(),$CanvasLayer/MainMenu/MarginContainer/VBoxContainer/nick.text,0.001*$CanvasLayer/MainMenu/MarginContainer/VBoxContainer/HBoxContainer/HSlider.value)

func _on_join_pressed():
	var err = enet_peer.create_client(addr_entry.text,PORT)
	print(err)
	if(err != OK):
		addr_entry.text = ""
		addr_entry.placeholder_text = "Server Can't be reachable"
		return
	main_menu.hide()
	multiplayer.multiplayer_peer = enet_peer
	add_player(multiplayer.get_unique_id(),$CanvasLayer/MainMenu/MarginContainer/VBoxContainer/nick.text,0.001*$CanvasLayer/MainMenu/MarginContainer/VBoxContainer/HBoxContainer/HSlider.value)

