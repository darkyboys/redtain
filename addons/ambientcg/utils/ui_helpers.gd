@tool
extends Node


func load_image_from_url(parent: Node, url: String) -> ImageTexture:
	var http = HTTPRequest.new()
	parent.add_child(http)
	http.request(url)
	var response = await http.request_completed
	parent.remove_child(http)
	http.queue_free()

	if response[1] != 200:
		return null

	var headers: PackedStringArray = response[2]
	var buffer: PackedByteArray = response[3]
	var img = Image.new()
	var err = FAILED

	var content_type = ""
	for header in headers:
		if header.to_lower().begins_with("content-type:"):
			content_type = header.to_lower()
			break

	if "webp" in content_type:
		err = img.load_webp_from_buffer(buffer)
	elif "png" in content_type:
		err = img.load_png_from_buffer(buffer)
	else:
		err = img.load_jpg_from_buffer(buffer)

	if err == OK:
		return ImageTexture.create_from_image(img)

	return null


func show_confirmation_dialog(
	parent: Node,
	title: String,
	message: String,
	ok_text: String = "Ok",
	cancel_text: String = "Cancel"
) -> bool:
	var dialog = ConfirmationDialog.new()
	dialog.title = title
	dialog.dialog_text = message
	dialog.ok_button_text = ok_text
	dialog.cancel_button_text = cancel_text
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_MOUSE_FOCUS

	parent.add_child(dialog)
	dialog.visible = true

	var confirmed = false
	dialog.confirmed.connect(func(): confirmed = true)
	dialog.canceled.connect(func(): confirmed = false)

	await dialog.close_requested
	dialog.queue_free()

	return confirmed
