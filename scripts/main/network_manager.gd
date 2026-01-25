# Network Manager

extends Node

class_name NetworkManager

## Limit of packets that can be read at once
const PACKET_READ_LIMIT := 32
## Maximum player count.
const MAX_LOBBY_MEMBERS := 24

var lobby_id := 0
var lobby_members := []


var player_id := 0
var player_username := ""
var host_id = 0

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
		host_id = player_id # In case we're staying local. This probably will be redundant later.
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
	return host_id==id

## Create a steam lobby.
func create_lobby():
	host_id = player_id
	if lobby_id == 0:
		Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC,MAX_LOBBY_MEMBERS)

## When lobby is created we set ourselves as a part of it.
func _on_lobby_created(success: int, id: int):
	if success:
		lobby_id = id
		host_id = player_id
		print("Created lobby with id: "+str(lobby_id))
		Steam.setLobbyJoinable(lobby_id, true)
		Steam.setLobbyData(lobby_id,"name",player_username+"'s Lobby")
		var _set_relay := Steam.allowP2PPacketRelay(true)

# Join a steam lobby.
func join_lobby(id: int):
	Steam.joinLobby(id)

# When we join a lobby we set ourselves as a part of it.
func _on_lobby_joined(id: int, _permissions: int, _locked: bool, response: int):
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		lobby_id = id
		print("Joined lobby "+str(lobby_id))
		get_lobby_members() # Update lobby array.
		make_p2p_handshake() # Announce that we are part of the lobby.
		validate_host()

# When a player's status changes we are notified.
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
	validate_host() # If host left we migrate.

# Update lobby members array so we know what players are here.
func get_lobby_members():
	lobby_members.clear()
	if lobby_id == 0:
		lobby_members.append({"steam_id": player_id, "steam_name": "Player"})
		return
	var lobby_count := Steam.getNumLobbyMembers(lobby_id)
	print("Host is ", Steam.getFriendPersonaName(host_id), " or by steam standards, ", Steam.getFriendPersonaName(Steam.getLobbyOwner(lobby_id)))
	print("Current members: ")
	for member in range(0,lobby_count):
		var member_id := Steam.getLobbyMemberByIndex(lobby_id, member)
		var member_name := Steam.getFriendPersonaName(member_id)
		print(member_name)
		lobby_members.append({"steam_id": member_id, "steam_name": member_name})

# Send a packet to another player.
func send_p2p_packet(target: int, packet: Dictionary, send_type:=Steam.P2P_SEND_RELIABLE):
	var channel: int = 0
	var packet_data: PackedByteArray
	packet_data.append_array(var_to_bytes(packet))
	if target == 0: # Multicast to everyone else.
		if lobby_members.size()>1:
			for member in lobby_members:
				if member['steam_id'] != player_id:
					if send_type == Steam.P2P_SEND_RELIABLE: print("< Sending packet '",packet["m"],"' to "+Steam.getFriendPersonaName(member['steam_id']))
					Steam.sendP2PPacket(member['steam_id'], packet_data, send_type, channel)
	else: # Send to target.
		Steam.sendP2PPacket(target, packet_data, send_type, channel)

# When p2p session requested, accept.
func _on_p2p_session_request(remote_id: int):
	var _requester := Steam.getFriendPersonaName((remote_id))
	Steam.acceptP2PSessionWithUser(remote_id)

# Send a handshake to everyone.
func make_p2p_handshake():
	send_p2p_packet(0, {"m": MSG_HANDSHAKE, "steam_id": player_id, "username": player_username})

# Keep reading packets.
func read_all_p2p_packets(read_count: int = 0):
	if (read_count>=PACKET_READ_LIMIT):
		return
	else:
		if Steam.getAvailableP2PPacketSize(0) > 0:
			read_p2p_packet()
			read_all_p2p_packets(read_count+1)

# Read a packet.
func read_p2p_packet():
	var packet_size := Steam.getAvailableP2PPacketSize(0)
	if packet_size > 0:
		var packet := Steam.readP2PPacket(packet_size,0)
		var sender_id: int = packet['remote_steam_id']
		var packet_code: PackedByteArray = packet['data']
		var readable_data: Dictionary = bytes_to_var(packet_code)
		
		if readable_data.has("m"):
			#print("> Recieved packet "+str(readable_data["m"])+" from "+Steam.getFriendPersonaName(sender_id))
			match readable_data["m"]:
				MSG_HANDSHAKE: # Handshake.
					get_lobby_members()
					if is_host():
						send_p2p_packet(0, {"m": MSG_HANDSHAKE_ACK})
				MSG_HANDSHAKE_ACK: # Handshake acknowledgement sent from the host.
					print(Steam.getFriendPersonaName(sender_id), " has acknowledged the handshake from ", sender_id, ".")
				MSG_SPAWN_CHAR:
					if is_host(sender_id):
						var level: Level = get_tree().current_scene.get_node("Level")
						level.spawn_character(readable_data["char_path"], readable_data["owner_id"], readable_data["position"], readable_data["registry_id"])
				MSG_CLIENT_CHAR_INPUT: # A client sends their input for their character.
					if is_host():
						var level: Level = get_tree().current_scene.get_node("Level")
						var character: Character = level.level_registry[readable_data["id"]]
						if character.owning_player_id == sender_id:
							character.use_player_input(readable_data["in"], readable_data["d"])
				MSG_REGISTRY_UPDATE: # A registry update from host, updating the state of each item.
					if is_host(sender_id):
						var network_registry = readable_data["r"]
						var level: Level = get_tree().current_scene.get_node("Level")
						for id in network_registry:
							if level.level_registry.has(id):
								print("Retrieving state of ", level.level_registry[id].name)
								if level.level_registry[id] is Character:
									# If this is our local character we should rubberband more subtlely.
									if level.level_registry[id].is_locally_possessed():
										pass
									else:
										level.level_registry[id].position = network_registry[id]["p"]
										level.level_registry[id].rotation = network_registry[id]["r"]
										level.level_registry[id].control_pitch = network_registry[id]["pcr"]
				MSG_REQUEST_GAME_INFO: # Client requesting game info from server.
					var level: Level = get_tree().current_scene.get_node("Level")
					var match_state_dict: Dictionary = level.get_node("MatchState").to_dict() # Get the match state in dictionary form.
					var registry_initial: Dictionary
					for id in level.level_registry:
						var registry_scene = level.level_registry[id]
						registry_initial[id] = {}
						registry_initial[id]["path"] = registry_scene.scene_file_path
					send_p2p_packet(sender_id, {"m": MSG_RETRIEVE_GAME_INFO, "ri": registry_initial, "ms": match_state_dict})
				MSG_RETRIEVE_GAME_INFO: # Client retrieves info from server.
					var level: Level = get_tree().current_scene.get_node("Level")
					level.get_node("MatchState").from_dict(readable_data["ms"]) # Retrieve match state.
					var initial_registry: Dictionary = readable_data["ri"]
					for id in initial_registry:
						var new_scene = load(initial_registry[id]["path"]).instantiate()
						level.add_child(new_scene)

func get_host_id() -> int:
	return Steam.getLobbyOwner(lobby_id)


## Checks to see if host is still in the session. Otherwise, elect a new host.
func validate_host():
	host_id = Steam.getLobbyOwner(lobby_id)
	return
#	var ids := []
#	for m in lobby_members:
#		if m['steam_id'] == host_id: return
#		ids.append(m['steam_id'])
#	
#	# Set new host to the user with the lowest id.
#	print("Commencing host migration.")
#	ids.sort()
#	host_id = ids[0]
#	print(Steam.getFriendPersonaName(host_id)+" is the new host.")





# A list of constants to use 
const MSG_HANDSHAKE := 0 # Handshake
const MSG_HANDSHAKE_ACK := 1 # Handshake Acknowledgement
const MSG_SPAWN_CHAR := 2 # Spawn a character.
const MSG_CLIENT_CHAR_INPUT := 3 # Client to Server character input
const MSG_REGISTRY_UPDATE := 4 # Server sends up to date registry info to clients.
const MSG_REQUEST_GAME_INFO := 5 # Client requests server info when they first join the server.
const MSG_RETRIEVE_GAME_INFO := 6 # Server sends initial game info back to client.
