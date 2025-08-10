extends Node

enum InMessageType {
	JOIN_LOBBY_SUCCESS,
	LOBBY_SEALED,
	PEER_CONNECTED,
	PEER_DISCONNECTED,
	OFFER_RECEIVED,
	ANSWER_RECEIVED,
	CANDIDATE_RECEIVED,
}

enum OutMessageType {
	JOIN_LOBBY,
	SEAL_LOBBY,
	OFFER,
	ANSWER,
	CANDIDATE,
}

var ws = WebSocketPeer.new()
var close_code = 1000
var close_reason = "Unknown"
var prev_state = WebSocketPeer.STATE_CLOSED
var lobby_code = ""

signal join_lobby_success(id: int, code: String)
signal lobby_sealed()
signal peer_connected(id: int)
signal peer_disconnected(id: int)
signal offer_received(id: int, offer: String)
signal answer_received(id: int, answer: String)
signal candidate_received(id: int, mid: String, index: int, sdp: String)
signal disconnected()

func connect_to_url(url: String) -> void:
	close()
	
	close_code = 1000
	close_reason = "Unknown"
	
	ws.connect_to_url(url)

func close() -> void:
	ws.close()

func _process(_delta: float) -> void:
	ws.poll()
	
	var state = ws.get_ready_state()
	var state_mismatch = state != prev_state
	
	if state_mismatch and state == WebSocketPeer.STATE_OPEN:
		join_lobby(lobby_code)
	
	while state == WebSocketPeer.STATE_OPEN and ws.get_available_packet_count():
		if not _parse_message():
			print("Error parsing message from server.")
	
	if state_mismatch and state == WebSocketPeer.STATE_CLOSED:
		close_code = ws.get_close_code()
		close_reason = ws.get_close_reason()
		disconnected.emit()
	
	prev_state = state

func _parse_message() -> bool:
	var parsed: Dictionary = JSON.parse_string(ws.get_packet().get_string_from_utf8())
	
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	
	if not parsed.has("type") or not parsed.has("data"):
		return false
	
	var data = parsed.get("data")
	
	if typeof(data) != TYPE_DICTIONARY:
		return false
	
	var type = int(parsed.type)
	var id = int(data.id) if data.has("id") else -1
	
	match type:
		InMessageType.JOIN_LOBBY_SUCCESS:
			join_lobby_success.emit(id, data.code)
		InMessageType.LOBBY_SEALED:
			lobby_sealed.emit()
		InMessageType.PEER_CONNECTED:
			peer_connected.emit(id)
		InMessageType.PEER_DISCONNECTED:
			peer_disconnected.emit(id)
		InMessageType.OFFER_RECEIVED:
			var offer = data.offer if data.has("offer") else ""
			offer_received.emit(id, offer)
		InMessageType.ANSWER_RECEIVED:
			var answer = data.answer if data.has("answer") else ""
			answer_received.emit(id, answer)
		InMessageType.CANDIDATE_RECEIVED:
			if not data.has("mid") or not data.has("index") or not data.has("sdp"):
				return false
			
			var mid = data.get("mid")
			var index = int(data.get("index"))
			var sdp = data.get("sdp")
			
			candidate_received.emit(id, mid, index, sdp)
		_:
			return false
	
	return true

func _send_message(type: OutMessageType, data: Dictionary = {}) -> Error:
	return ws.send_text(JSON.stringify({
		"type": type,
		"data": data,
	}))

func join_lobby(_lobby_code: String) -> Error:
	var data = {
		"lobby_code": _lobby_code
	}
	return _send_message(OutMessageType.JOIN_LOBBY, data)

func seal_lobby() -> Error:
	return _send_message(OutMessageType.SEAL_LOBBY)

func send_candidate(id: int, mid: String, index: int, sdp: String) -> Error:
	var data = {
		"mid": mid,
		"index": index,
		"sdp": sdp,
		"id": id
	}
	return _send_message(OutMessageType.CANDIDATE, data)

func send_offer(id: int, offer: String) -> Error:
	var data = { 
		"offer": offer, 
		"id": id 
	}
	return _send_message(OutMessageType.OFFER, data)

func send_answer(id: int, answer: String) -> Error:
	var data = {
		"answer": answer,
		"id": id
	}
	return _send_message(OutMessageType.ANSWER, data)
