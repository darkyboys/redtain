@tool
extends Node

var config: Script
var parser: Script
var logger: Node
var signals: Node
var manager: Node

var current_search_request: HTTPRequest = null
var user_agent := ""


func _ready() -> void:
	update_user_agent()


func update_user_agent() -> void:
	user_agent = (
		"AmbientCG Plugin (Godot %s)"
		% str(Engine.get_version_info().major, ".", Engine.get_version_info().minor)
	)


func http_request(
	url: String,
	custom_headers: PackedStringArray = PackedStringArray(),
	method: HTTPClient.Method = 0,
	request_data: String = "",
	track_as_search: bool = false
):
	if url.is_empty() or not url.begins_with("http"):
		logger.warn("Attempted to request invalid URL: '%s'" % url, "Network")
		return [1, 0, {}, PackedByteArray()]

	var http_request = HTTPRequest.new()
	add_child(http_request)
	if track_as_search:
		current_search_request = http_request

	if custom_headers.is_empty():
		custom_headers.append("User-Agent: %s" % user_agent)
	else:
		var has_ua = false
		for h in custom_headers:
			if h.to_lower().begins_with("user-agent:"):
				has_ua = true
				break
		if not has_ua:
			custom_headers.append("User-Agent: %s" % user_agent)

	http_request.request(url, custom_headers, method, request_data)
	var response = await http_request.request_completed

	if track_as_search and current_search_request == http_request:
		current_search_request = null

	remove_child(http_request)
	http_request.queue_free()
	return response


func cancel_current_search() -> void:
	if current_search_request:
		current_search_request.cancel()
		current_search_request = null


func http_request_download(url: String, path: String, file_size: int) -> void:
	if url.is_empty():
		return
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.download_file = path
	var request_status = {"finished": false, "success": false}
	http_request.request_completed.connect(
		func(result: int, _response_code: int, _headers: PackedStringArray, _body: PackedByteArray):
			request_status["finished"] = true
			request_status["success"] = (result == HTTPRequest.RESULT_SUCCESS)
	)

	http_request.request(url, ["User-Agent: %s" % user_agent], HTTPClient.METHOD_GET, "")

	while not request_status["finished"]:
		var downloaded = http_request.get_downloaded_bytes()
		if signals:
			var actual_total = max(file_size, downloaded) if file_size > 0 else max(1, downloaded)
			signals.download_progress_updated.emit(url, downloaded, actual_total)
		await get_tree().create_timer(0.1).timeout

	remove_child(http_request)
	http_request.queue_free()

	if request_status["success"]:
		if signals:
			signals.download_progress_updated.emit(url, file_size, file_size)
			signals.download_completed.emit(path)
	else:
		if signals:
			signals.download_failed.emit(url, "Download failed or connection lost")


func search_assets(
	query: String, type: String = "", override_uri: String = "", exact_id: String = ""
) -> Dictionary:
	var final_uri = ""
	if not override_uri.is_empty():
		final_uri = (
			override_uri if override_uri.begins_with("http") else config.BASE_DOMAIN + override_uri
		)
	else:
		final_uri = config.HOME_URL + "assets?limit=100&include=downloads,thumbnails"
		if not exact_id.is_empty():
			final_uri += "&id=" + exact_id.uri_encode()
		if not query.is_empty():
			final_uri += "&q=" + query.uri_encode()
		if not type.is_empty() and type != "Any":
			final_uri += "&type=" + type.to_lower().uri_encode()

	if not final_uri.is_empty():
		var response = await http_request(
			final_uri, PackedStringArray(), HTTPClient.METHOD_GET, "", true
		)
		if response[0] != HTTPRequest.RESULT_SUCCESS:
			return {}

		var json_string = response[3].get_string_from_utf8()
		return JSON.parse_string(json_string) if not json_string.is_empty() else {}

	return {}


func api_init() -> Dictionary:
	var types = ["Material", "HDRI", "Substance", "Decal", "Atlas", "3DModel", "Terrain"]
	var data = {"types": types}
	if manager:
		manager.api_information = data
	return data
