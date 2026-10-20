extends RefCounted
## Checksummed JSON with backup recovery and staged atomic replacement.
static func read_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var file = FileAccess.open(path,FileAccess.READ)
	if file == null: return {}
	var parser = JSON.new()
	if parser.parse(file.get_as_text()) != OK: return {}
	var envelope = parser.data
	if not envelope is Dictionary or envelope.get("schema") != 1: return {}
	var payload = envelope.get("payload",null)
	if not payload is String or envelope.get("checksum") != payload.sha256_text(): return {}
	var body = JSON.new()
	if body.parse(payload) != OK: return {}
	var parsed = body.data
	return parsed if parsed is Dictionary else {}

static func load_progress(path: String) -> Dictionary:
	var primary = read_file(path)
	if not primary.is_empty(): return {"data":primary,"recovered":false}
	var backup = read_file(path+".backup")
	return {"data":backup,"recovered":not backup.is_empty()}

static func save_progress(path: String, data: Dictionary) -> bool:
	var payload = JSON.stringify(data)
	var envelope = JSON.stringify({"schema":1,"payload":payload,"checksum":payload.sha256_text()})
	var temp = path+".temporary"
	var file = FileAccess.open(temp,FileAccess.WRITE)
	if file == null: return false
	file.store_string(envelope)
	file.flush()
	file.close()
	if read_file(temp).is_empty(): return false
	var directory = DirAccess.open(path.get_base_dir())
	if directory == null: return false
	var name = path.get_file()
	# Only a validated primary may replace the previous good backup.
	if not read_file(path).is_empty():
		if directory.file_exists(name+".backup"): directory.remove(name+".backup")
		if directory.rename(name,name+".backup") != OK: return false
	elif directory.file_exists(name):
		if directory.remove(name) != OK: return false
	return directory.rename(name+".temporary",name) == OK
