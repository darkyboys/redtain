@tool
extends Node


static func format_file_size(bytes: int) -> String:
	if bytes < 1024:
		return "%d B" % bytes
	if bytes < 1024 * 1024:
		return "%.2f KiB" % (float(bytes) / 1024.0)
	if bytes < 1024 * 1024 * 1024:
		return "%.2f MiB" % (float(bytes) / (1024.0 * 1024.0))
	return "%.2f GiB" % (float(bytes) / (1024.0 * 1024.0 * 1024.0))


static func ensure_dir(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_recursive_absolute(path)


static func clean_dir_content(path: String) -> void:
	if DirAccess.dir_exists_absolute(path):
		var dir = DirAccess.open(path)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if not dir.current_is_dir():
					dir.remove(file_name)
				file_name = dir.get_next()


static func get_resource_name_clean(path: String) -> String:
	return path.get_file().get_basename()


static func save_buffer(path: String, buffer: PackedByteArray) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_buffer(buffer)
		file.close()
