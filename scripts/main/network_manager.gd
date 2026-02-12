# Network Manager

extends Node

class_name NetworkManager

## Limit of packets that can be read at once
const PACKET_READ_LIMIT := 32
## Maximum player count.
const MAX_LOBBY_MEMBERS := 24

## The id of the current lobby.
var lobby_id := 0
## List of members in this lobby.
var lobby_members := []

## Self's player id.
var player_id := 0
## Self's username.
var player_username := ""



func _init():
	OS.set_environment("SteamAppID",str(2837470))
	OS.set_environment("SteamGameID",str(2837470))

func _ready():
	connect_to_steam()

func _process(_delta):
	Steam.run_callbacks()
	if lobby_id > 0:
		read_all_p2p_packets()

## Connects to the steam servers.
func connect_to_steam():
	var steam_results := Steam.steamInitEx()
	if steam_results["status"] == 0:
		print("Successfully connected to Steam servers!")
		player_id = Steam.getSteamID()
		player_username = Steam.getPersonaName()
		
		Steam.lobby_created.connect(_on_lobby_created)
		Steam.lobby_joined.connect(_on_lobby_joined)
		Steam.p2p_session_request.connect(_on_p2p_session_request)
		Steam.lobby_chat_update.connect(_on_lobby_chat_update)
		get_lobby_members()
	else:
		print("Error ", steam_results["status"]," when connecting to steam: ", steam_results["verbal"])
		get_lobby_members()

## Returns true the given player id (or self by default) is the host of the session.
func is_host(id := player_id):
	return id == Steam.getLobbyOwner(lobby_id)

func get_host_id() -> int:
	return Steam.getLobbyOwner(lobby_id)

## Returns true if member is currently in lobby.
func has_lobby_member(id: int):
	return lobby_members.has(id)


## Create a steam lobby.
func create_lobby():
	if lobby_id == 0:
		Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC,MAX_LOBBY_MEMBERS)

## When lobby is created we set ourselves as a part of it.
func _on_lobby_created(success: int, id: int):
	if success:
		lobby_id = id
		print("Created lobby with id: "+str(lobby_id))
		Steam.setLobbyJoinable(lobby_id, true)
		Steam.setLobbyData(lobby_id,"name",player_username+"'s Lobby")
		var _set_relay := Steam.allowP2PPacketRelay(true)

## Join a steam lobby.
func join_lobby(id: int):
	Steam.joinLobby(id)

## When we join a lobby we set ourselves as a part of it.
func _on_lobby_joined(id: int, _permissions: int, _locked: bool, response: int):
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		lobby_id = id
		print("Joined lobby "+str(lobby_id))
		get_lobby_members() # Update lobby array.
		make_p2p_handshake() # Announce that we are part of the lobby.

## When a player's status changes we are notified.
func _on_lobby_chat_update(_id: int, changed_id: int, change_maker_id: int, chat_state: int):
	var changed_name = Steam.getFriendPersonaName(changed_id)
	var change_maker_name = Steam.getFriendPersonaName(change_maker_id)
	match chat_state:
		Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
			print(changed_name+" has joined the lobby.")
		Steam.CHAT_MEMBER_STATE_CHANGE_LEFT:
			print(changed_name+" has left the lobby.")
		Steam.CHAT_MEMBER_STATE_CHANGE_DISCONNECTED:
			print(changed_name+" has been disconnected from the lobby.")
		Steam.CHAT_MEMBER_STATE_CHANGE_KICKED:
			print(changed_name+" has been kicked from the lobby by "+change_maker_name+".")
		Steam.CHAT_MEMBER_STATE_CHANGE_BANNED:
			print(changed_name+" has been kicked banned the lobby by "+change_maker_name+".")
	get_lobby_members() # Update lobby members.

## Update lobby members array so we know what players are here.
func get_lobby_members():
	lobby_members.clear()
	if lobby_id == 0:
		lobby_members.append(player_id)
		return
	var lobby_count := Steam.getNumLobbyMembers(lobby_id)
	print("Host is ", Steam.getFriendPersonaName(Steam.getLobbyOwner(lobby_id)))
	print("Current members: ")
	for member in range(0,lobby_count):
		var member_id := Steam.getLobbyMemberByIndex(lobby_id, member)
		var member_name := Steam.getFriendPersonaName(member_id)
		print(member_name)
		lobby_members.append(member_id)
	#for simulated_member_id in [76561198053693271, 76561198036161282, 76561198207763132, 76561198106468984]:
	#	lobby_members.append(simulated_member_id)

## Send a packet to another player.
func send_p2p_packet(target: int, packet: Dictionary, send_type:=Steam.P2P_SEND_RELIABLE):
	var channel: int = 0
	var packet_data: PackedByteArray
	packet_data.append_array(var_to_bytes(packet))
	if target == 0: # Multicast to everyone else.
		if lobby_members.size()>1:
			for member in lobby_members:
				if member['steam_id'] != player_id:
					Steam.sendP2PPacket(member['steam_id'], packet_data, send_type, channel)
	else: # Send to target.
		Steam.sendP2PPacket(target, packet_data, send_type, channel)

## When p2p session requested, accept.
func _on_p2p_session_request(remote_id: int):
	var _requester := Steam.getFriendPersonaName((remote_id))
	Steam.acceptP2PSessionWithUser(remote_id)

## Send a handshake to everyone.
func make_p2p_handshake():
	send_p2p_packet(0, {"m": Message.HANDSHAKE, "steam_id": player_id, "username": player_username})

## Keep reading packets.
func read_all_p2p_packets(read_count: int = 0):
	if (read_count>=PACKET_READ_LIMIT):
		return
	else:
		if Steam.getAvailableP2PPacketSize(0) > 0:
			read_p2p_packet()
			read_all_p2p_packets(read_count+1)

## Read a packet.
func read_p2p_packet():
	var packet_size := Steam.getAvailableP2PPacketSize(0)
	if packet_size > 0:
		var packet := Steam.readP2PPacket(packet_size,0)
		var sender_id: int = packet['remote_steam_id']
		var packet_code: PackedByteArray = packet['data']
		var readable_data: Dictionary = bytes_to_var(packet_code)
		
		if readable_data.has("m"):
			match readable_data["m"]:
				Message.HANDSHAKE: 
					get_lobby_members()
					if is_host():
						send_p2p_packet(0, {"m": Message.HANDSHAKE_ACK})
				Message.HANDSHAKE_ACK: 
					print(Steam.getFriendPersonaName(sender_id), " has acknowledged the handshake from ", sender_id, ".")
				Message.SPAWN_CHAR: 
					if is_host(sender_id):
						var level: Level = get_tree().current_scene.get_node("Level")
						level.spawn_character(readable_data["char_path"], readable_data["owner_id"], readable_data["position"], readable_data["registry_id"])
				Message.SPAWN_PICKUP: 
					if is_host(sender_id):
						var level: Level = get_tree().current_scene.get_node("Level")
						var item_state = ItemState.new()
						item_state.from_dict(readable_data["item_state"])
						level.spawn_pickup(item_state, readable_data["position"], readable_data["registry_id"])
				Message.DESPAWN_OBJECT: 
					if is_host(sender_id):
						var level: Level = get_tree().current_scene.get_node("Level")
						level.despawn_registry_object(readable_data["registry_id"])
				Message.CLIENT_CHAR_INPUT: 
					if is_host():
						var level: Level = get_tree().current_scene.get_node("Level")
						#print("Recieving client input for character ", readable_data["id"])
						#print(level.level_registry)
						if not level.level_registry.has(readable_data["id"]): return
						var character: Character = level.level_registry[readable_data["id"]]
						if character.owning_player_id == sender_id:
							character.use_player_input(readable_data["in"], readable_data["d"])
				Message.REGISTRY_UPDATE: 
					if is_host(sender_id):
						var network_registry = readable_data["r"]
						var level: Level = get_tree().current_scene.get_node("Level")
						for id in network_registry:
							if level.level_registry.has(id):
								if level.level_registry[id] is Character:
									# If this is our local character we should rubberband more subtlely.
									level.level_registry[id].from_reg_dict(network_registry[id])
				Message.CLIENT_REQUEST_GAME: 
					if is_host():
						print("Sending game info to ", Steam.getFriendPersonaName(sender_id))
						var level: Level = get_tree().current_scene.get_node("Level")
						var match_state_dict: Dictionary = level.match_state.to_dict() # Get the match state in dictionary form.
						var registry_initial: Dictionary
						for id in level.level_registry:
							var registry_scene = level.level_registry[id]
							registry_initial[id] = {}
							registry_initial[id]["path"] = registry_scene.scene_file_path
							registry_initial[id]["data"] = registry_scene.to_init_dict()
							registry_initial[id]["reg_dict"] = registry_scene.to_reg_dict()
						send_p2p_packet(sender_id, {"m": Message.RETRIEVE_GAME_INFO, "ri": registry_initial, "ms": match_state_dict})
				Message.RETRIEVE_GAME_INFO: 
					if is_host(sender_id):
						var level: Level = get_tree().current_scene.get_node("Level")
						level.match_state.from_dict(readable_data["ms"]) # Retrieve match state.
						var initial_registry: Dictionary = readable_data["ri"]
						for id in initial_registry:
							var new_scene = load(initial_registry[id]["path"]).instantiate()
							new_scene.from_init_dict(initial_registry[id]["data"])
							new_scene.from_reg_dict(initial_registry[id]["reg_dict"])
							level.add_child(new_scene)
							level.level_registry[id] = new_scene
				Message.CHARACTER_TACKLED: 
					if is_host(sender_id):
						var level: Level = get_tree().current_scene.get_node("Level")
						var character: Character = level.level_registry[readable_data["id"]]
						var tackler: Character = level.level_registry[readable_data["tid"]]
						var tackle_force = readable_data["tf"]
						character.tackle(tackler, tackle_force)
				Message.CHARACTER_RECOVERED: 
					if is_host(sender_id):
						var level: Level = get_tree().current_scene.get_node("Level")
						var character: Character = level.level_registry[readable_data["id"]]
						character.recover()
				Message.CHARACTER_EQUIP: 
					if is_host(sender_id):
						var level: Level = get_tree().current_scene.get_node("Level")
						var character: Character = level.level_registry[readable_data["id"]]
						character.equip_item(readable_data["index"])
				Message.CHARACTER_UNEQUIP: 
					if is_host(sender_id):
						var level: Level = get_tree().current_scene.get_node("Level")
						var character: Character = level.level_registry[readable_data["id"]]
						character.unequip_item()
				Message.CLIENT_INTERACT: 
					if is_host():
						var level: Level = get_tree().current_scene.get_node("Level")
						var character: Character = level.level_registry[readable_data["id"]]
						var interactable: Node3D = level.level_registry[readable_data["iid"]]
						if interactable.has_method("interact"):
							interactable.interact(character)
				Message.CLIENT_DROP: 
					if is_host():
						var level: Level = get_tree().current_scene.get_node("Level")
						var character: Character = level.level_registry[readable_data["id"]]
						character.drop_equipped_item()
				Message.CHARACTER_ADDITEM: 
					if is_host(sender_id):
						var level: Level = get_tree().current_scene.get_node("Level")
						var character: Character = level.level_registry[readable_data["id"]]
						var item_state = ItemState.new()
						item_state.from_dict(readable_data["item_state"])
						character.get_node("InventoryComponent").add_item(item_state)
				Message.CHARACTER_REMOVEITEM: 
					if is_host(sender_id):
						var level: Level = get_tree().current_scene.get_node("Level")
						var character: Character = level.level_registry[readable_data["id"]]
						character.get_node("InventoryComponent").remove_item(readable_data["index"])
				Message.SET_STATE_OF_MATCH:
					if is_host(sender_id):
						var level: Level = get_tree().current_scene.get_node("Level")
						var match_state: MatchState = level.match_state
						match_state.set_state_of_match(readable_data["state_of_match"])
				Message.SET_MATCH_TIME:
					if is_host(sender_id):
						var level: Level = get_tree().current_scene.get_node("Level")
						var match_state: MatchState = level.match_state
						match_state.set_match_time(readable_data["time"])
				Message.SET_INTERMISSION_TIME:
					if is_host(sender_id):
						var level: Level = get_tree().current_scene.get_node("Level")
						var match_state: MatchState = level.match_state
						match_state.set_intermission_time(readable_data["time"])
				Message.SET_PLAYER_TEAM:
					if is_host(sender_id):
						var level: Level = get_tree().current_scene.get_node("Level")
						var match_state: MatchState = level.match_state
						match_state.assign_player_team(readable_data["player_id"], readable_data["team_id"])
				Message.ADD_PLAYER_STATE:
					if is_host(sender_id):
						var level: Level = get_tree().current_scene.get_node("Level")
						var match_state: MatchState = level.match_state
						match_state.add_player_state(readable_data["player_id"])
				Message.SET_TEAM_SCORE:
					if is_host(sender_id):
						var level: Level = get_tree().current_scene.get_node("Level")
						var match_state: MatchState = level.match_state
						match_state.set_team_score(readable_data["team_id"], readable_data["score"])
				Message.SET_PLAYER_SCORE:
					if is_host(sender_id):
						var level: Level = get_tree().current_scene.get_node("Level")
						var match_state: MatchState = level.match_state
						match_state.set_player_score(readable_data["player_id"], readable_data["current"], readable_data["total"])

## Enum for the message types for the network manager.
enum Message {
	HANDSHAKE, ## Handshake
	HANDSHAKE_ACK, ## Handshake acknowledgement sent from the host.
	SPAWN_CHAR, ## Spawns a character in local registry.
	SPAWN_PICKUP, ## Spawns a pickup in local registry.
	SPAWN_PROJECTILE, ## Spawns a projectile in local registry.
	DESPAWN_OBJECT, ## Despawns an object in local registry
	CLIENT_CHAR_INPUT, ## A client sends their input for their character.
	REGISTRY_UPDATE, ## A registry update from host, updating the state of each item.
	CLIENT_REQUEST_GAME, ## Client requesting game info from server.
	RETRIEVE_GAME_INFO, ## Client retrieves info from server.
	CHARACTER_TACKLED, ## Character is tackled.
	CHARACTER_RECOVERED, ## Character recovers from being tackled.
	CHARACTER_EQUIP, ## Character equips item.
	CHARACTER_UNEQUIP, ## Character equips item.
	CLIENT_INTERACT, ## Client wants to interact with something.
	CLIENT_DROP, ## Client wants to drop item.
	CHARACTER_ADDITEM, ## Adds an item to a character's inventory.
	CHARACTER_REMOVEITEM, ## Removes an item from a character's inventory.
	SET_STATE_OF_MATCH, ## Server sets the state of the match.
	SET_MATCH_TIME, ## Server sets the match time.
	SET_INTERMISSION_TIME, ## Server sets the intermission time.
	SET_PLAYER_TEAM, ## Server sets a player's team.
	ADD_PLAYER_STATE, ## Adds a player state to the match state.
	SET_TEAM_SCORE, ## Sets a team's score.
	SET_PLAYER_SCORE ## Sets a player's scores.
}
