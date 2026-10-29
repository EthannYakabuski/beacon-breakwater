extends SceneTree
## Presentation fixtures only; no genuine profiles or native-service evidence.
const Main = preload("res://game/main.gd")
const Profile = preload("res://game/profile.gd")
var checks = 0
var failures = 0
var scene: Node2D

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("Assertion failed: " + message)

func _initialize() -> void:
	call_deferred("run_tests")

func frames() -> void:
	await process_frame
	await process_frame

func collect_text(node: Node) -> String:
	var text = ""
	if node is Label or node is Button:
		text += str(node.text) + "\n"
	for child in node.get_children():
		text += collect_text(child)
	return text

func check_page(page: String, minimum_separators: int) -> void:
	var text = collect_text(scene.ui)
	check(not text.contains(String.chr(0x00c2) + String.chr(0x00b7)), page + " has no double-decoded separator")
	check(not text.contains(String.chr(0xfffd)), page + " has no replacement character")
	check(text.count("\u00b7") >= minimum_separators, page + " retains its intended middle-dot separators")

func run_tests() -> void:
	if "--qa-isolated" not in OS.get_cmdline_user_args():
		push_error("Display fixtures require --qa-isolated; no production save opened")
		quit(1)
		return
	root.size = Vector2i(540, 960)
	scene = Main.new()
	root.add_child(scene)
	await frames()
	scene.set_process(false)
	check(scene.qa, "display fixture uses isolated progress")
	check(ThemeDB.fallback_font.has_char(0x00b7), "existing fallback font supports the intended separator")
	var source = FileAccess.get_file_as_string("res://game/main.gd")
	check(not source.contains(String.chr(0x00c2) + String.chr(0x00b7)), "no corrupted separator literal remains in the UI source")
	scene.profile = Profile.new()
	scene._show_home()
	await frames()
	check_page("Home", 2)
	check(scene.find_child("Workshop", true, false).text == "The workshop  \u00b7  improve your beacon", "workshop button renders the single intended separator")
	scene._start_watch(0)
	await frames()
	check_page("Watch", 4)
	check(scene.horn_button.text.begins_with("Foghorn  \u00b7  "), "live horn label uses the same correct separator")
	scene._pause()
	await frames()
	check_page("Pause", 2)
	# Synthetic banked result only: no gameplay result or reward is manufactured.
	scene.watch.done = true
	scene.watch.won = true
	scene.banked = true
	scene.bank_receipt = {"coins": 1, "xp": 2, "level_bonus": 0, "daily_bonus": 0, "stars": 1}
	scene._show_results()
	await frames()
	check_page("Results", 4)
	scene._show_workshop()
	await frames()
	check_page("Workshop", 6)
	scene.profile.data.seen = scene.Watch.KINDS.keys()
	scene._show_log()
	await frames()
	check_page("Boat log", 5)
	scene.queue_free()
	await frames()
	print("BEACON DISPLAY CHECKS %d failures %d; isolated presentation fixtures only" % [checks, failures])
	quit(1 if failures else 0)
