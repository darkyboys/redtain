@tool
extends Node

var config: Script
var logger: Node
var signals: Node
var api: Node
var utils: Script


func download_file_from_data(file_information: Dictionary, _source_window: Node) -> void:
	var download_path: String = config.get_setting(
		config.SETTING_DOWNLOAD_PATH, config.DEFAULT_DOWNLOAD_PATH
	)
	var path: String = download_path.path_join(file_information.get("local_file_name", ""))
	var file_uri = file_information.get("uri", "")

	_log_info("Initiating download to Project: %s" % file_uri)

	var text = (
		"File will be Downloaded to %s and is Approx. %s.\nDownload?"
		% [path, utils.format_file_size(file_information.get("file_size", 0))]
	)

	var confirmed = true
	if config.get_setting(config.SETTING_ASK_BEFORE_DOWNLOAD, true):
		confirmed = await confirm_file_path(path, text)

	if not confirmed:
		_log_info("Download cancelled by user.")
		return

	if signals:
		signals.download_started.emit(file_uri, file_information.get("local_file_name", ""))
	if api:
		await api.http_request_download(file_uri, path, file_information.get("file_size", 0))


func confirm_file_path(_path: String, dialog_text: String) -> bool:
	if not Engine.is_editor_hint():
		return true

	var confirmation_dialog = ConfirmationDialog.new()
	add_child(confirmation_dialog)
	confirmation_dialog.exclusive = false
	confirmation_dialog.title = "Confirm Download"
	confirmation_dialog.dialog_text = dialog_text

	var state = [false, false]  # [finished, confirmed]

	confirmation_dialog.confirmed.connect(
		func():
			state[0] = true
			state[1] = true
	)

	confirmation_dialog.canceled.connect(func(): state[0] = true)

	confirmation_dialog.popup_centered()

	while not state[0]:
		await get_tree().process_frame

	confirmation_dialog.queue_free()
	return state[1]


func _log_info(message: String) -> void:
	if logger:
		logger.info(message, "Downloader")
