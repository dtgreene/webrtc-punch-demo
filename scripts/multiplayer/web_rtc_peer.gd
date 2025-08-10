extends "web_socket_peer.gd"

var rtc = WebRTCMultiplayerPeer.new()
var sealed = false

func _init() -> void:
	join_lobby_success.connect(_handle_join_lobby_success)
	lobby_sealed.connect(_handle_lobby_sealed)
	
	peer_connected.connect(_handle_peer_connected)
	peer_disconnected.connect(_handle_peer_disconnected)
	
	offer_received.connect(_handle_offer_received)
	answer_received.connect(_handle_answer_received)
	candidate_received.connect(_handle_candidate_received)
	
	disconnected.connect(_handle_disconnected)

func start(url: String, code: String = "") -> void:
	stop()
	
	sealed = false
	lobby_code = code
	
	connect_to_url(url)

func stop() -> void:
	multiplayer.multiplayer_peer = null
	rtc.close()
	close()

func _create_peer(id: int) -> WebRTCPeerConnection:
	var peer: WebRTCPeerConnection = WebRTCPeerConnection.new()
	
	peer.initialize({
		"iceServers": [{ "urls": ["stun:stun.l.google.com:19302"] }]
	})
	peer.session_description_created.connect(_offer_created.bind(id))
	peer.ice_candidate_created.connect(_new_ice_candidate.bind(id))
	
	rtc.add_peer(peer, id)
	
	if id < rtc.get_unique_id():
		peer.create_offer()
	
	return peer

func _new_ice_candidate(mid_name: String, index_name: int, sdp_name: String, id: int) -> void:
	send_candidate(id, mid_name, index_name, sdp_name)

func _offer_created(type: String, data: String, id: int) -> void:
	if not rtc.has_peer(id):
		return
	
	rtc.get_peer(id).connection.set_local_description(type, data)

	if type == "offer": 
		send_offer(id, data)
	else: 
		send_answer(id, data)

func _handle_join_lobby_success(id: int, code: String) -> void:
	#if use_mesh:
		#rtc_mp.create_mesh(id)
	
	if id == 1:
		rtc.create_server()
	else:
		rtc.create_client(id)
	
	multiplayer.multiplayer_peer = rtc

func _handle_lobby_sealed() -> void:
	sealed = true

func _handle_peer_connected(id: int) -> void:
	_create_peer(id)

func _handle_peer_disconnected(id: int) -> void:
	if rtc.has_peer(id):
		rtc.remove_peer(id)

func _handle_offer_received(id: int, offer: String) -> void:
	if rtc.has_peer(id):
		rtc.get_peer(id).connection.set_remote_description("offer", offer)

func _handle_answer_received(id: int, answer: String) -> void:
	if rtc.has_peer(id):
		rtc.get_peer(id).connection.set_remote_description("answer", answer)

func _handle_candidate_received(id: int, mid: String, index: int, sdp: String) -> void:
	if rtc.has_peer(id):
		rtc.get_peer(id).connection.add_ice_candidate(mid, index, sdp)

func _handle_disconnected() -> void:
	if not sealed:
		stop()
