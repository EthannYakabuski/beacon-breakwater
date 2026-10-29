extends SceneTree
## Actual Viewport GUI dispatch regression; service stub, isolated save, no native claim.
const Main=preload("res://game/main.gd")
const Harness=preload("res://tests/test_ui.gd")
var scene: Node2D
var checks=0
var failures=0
var paired=true
func _initialize() -> void: call_deferred("run_tests")
func check(value: bool,label: String) -> void:
	checks+=1
	if not value:failures+=1;push_error("Dispatch regression failed: "+label)
func frames(count: int=2) -> void:
	for index in range(count):await process_frame
func mouse(point: Vector2,pressed: bool) -> void:
	var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT
	event.position=point;event.global_position=point;event.pressed=pressed
	event.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.device=-1 if paired else 0
	root.push_input(event,true)
func screen_touch(point: Vector2,pressed: bool) -> void:
	var event=InputEventScreenTouch.new();event.index=0;event.position=point;event.pressed=pressed
	root.push_input(event,true)
func drag_body(start: Vector2, finish: Vector2) -> void:
	# Actual Viewport events follow the Android emulated-mouse/ScreenDrag pair.
	mouse(start,true);screen_touch(start,true);await frames(2)
	var previous=start
	for index in range(1,31):
		var point=start.lerp(finish,float(index)/30.0)
		var motion=InputEventMouseMotion.new();motion.position=point;motion.global_position=point
		motion.relative=point-previous;motion.button_mask=MOUSE_BUTTON_MASK_LEFT;motion.device=-1
		root.push_input(motion,true)
		var drag=InputEventScreenDrag.new();drag.index=0;drag.position=point;drag.relative=point-previous
		root.push_input(drag,true);previous=point;await frames(1)
	mouse(finish,false);screen_touch(finish,false);await frames(5)

func press(key: String,expected: String) -> void:
	var button=scene.find_child(key,true,false)
	check(is_instance_valid(button) and button.is_visible_in_tree(),"actual visible control "+key)
	if not is_instance_valid(button):return
	var previous_ui=scene.ui
	var activations={"count":0}
	button.pressed.connect(func():activations.count+=1)
	var point=button.get_global_transform_with_canvas()*(button.size*.5)
	print("BEACON_DISPATCH_BEGIN ",key," mode=",("paired-touch-mouse" if paired else "mouse-only"))
	# Input4.5.1 emits an emulated mouse event before the original ScreenTouch.
	# push_input receives that same ordinary pair; no signal is emitted by this test.
	mouse(point,true)
	if paired:screen_touch(point,true)
	await frames(2)
	mouse(point,false)
	if paired:screen_touch(point,false)
	print("BEACON_DISPATCH_RETURN ",key," screen=",scene.screen," old_in_tree=",previous_ui.is_inside_tree()," old_queued=",previous_ui.is_queued_for_deletion())
	check(scene.screen==expected,"ordinary GUI transition "+key+" -> "+expected)
	check(previous_ui.is_inside_tree() and previous_ui.is_queued_for_deletion() and not previous_ui.visible and previous_ui.mouse_filter==Control.MOUSE_FILTER_IGNORE,"retired input ancestry remains attached but hidden and noninteractive")
	check(activations.count==1,"paired release activates its button exactly once")
	await frames(3)
	check(not is_instance_valid(previous_ui),"previous UI freed at end of frame")
	check(is_instance_valid(scene.ui) and scene.ui.is_inside_tree() and scene.ui.visible,"one current UI remains usable")
	var live_interfaces=0
	for child in scene.get_children():
		if child is Control and child.name=="Interface":live_interfaces+=1
	check(live_interfaces==1,"exactly one current Interface after retirement")
func run_tests() -> void:
	if "--qa-isolated" not in OS.get_cmdline_user_args():
		push_error("Dispatch tests require isolated QA save");quit(1);return
	paired=not "--mouse-only" in OS.get_cmdline_user_args()
	var real=root.get_node_or_null("Services")
	if real!=null:root.remove_child(real);real.queue_free();await frames(1)
	var stub=Harness.FakeServices.new();stub.name="Services";root.add_child(stub)
	root.size=Vector2i(540,960);scene=Main.new();root.add_child(scene);await frames(4)
	var banked=scene.profile.data.duplicate(true)
	for _repeat in range(2):
		await press("BoatLog","log");await press("BackHome","home")
		await press("Settings","settings");await press("BackHome","home")
	await press("Campaign","coasts");await press("Coast0","missions")
	if paired:
		Input.set_emulate_touch_from_mouse(true)
		stub.reserve=180.0;stub.menu_bottom_reserve_changed.emit();await frames(4)
		var last=scene.find_child("Mission4",true,false)
		var old_ui=scene.ui;var before=scene.page_scroll.scroll_vertical
		check(last.get_global_rect().end.y>scene.page_scroll.get_global_rect().end.y,"last mission card is genuinely clipped before body drag")
		for drag in range(4):
			if last.get_global_rect().end.y<=scene.page_scroll.get_global_rect().end.y+.1: break
			await drag_body(scene.get_global_transform_with_canvas()*Vector2(425,600),scene.get_global_transform_with_canvas()*Vector2(425,325))
		check(scene.page_scroll.scroll_vertical>before,"ordinary card-body touch drag scrolls actual mission list")
		check(last.get_global_rect().end.y<=scene.page_scroll.get_global_rect().end.y+.1,"body drag reveals the complete last mission control")
		check(scene.screen=="missions" and scene.ui==old_ui,"drag never activates a watch or replaces the page")
		check(scene.profile.data==banked,"body drag does not mutate banked player progress")
		# Only fixture preparation returns to the first card; actual dispatch below
		# proves a single ordinary paired release directly launches the watch.
		scene.page_scroll.scroll_vertical=0;await frames(3)
	await press("Mission0","watch")
	check(scene.find_child("BeginWatch",true,false)==null,"ordinary mission release skips the removed briefing")
	if paired:
		Input.set_emulate_touch_from_mouse(false)
		stub.reserve=90.0;stub.menu_bottom_reserve_changed.emit()
	await press("PauseWatch","pause");await press("ResumeWatch","watch")
	await press("PauseWatch","pause")
	check(scene.profile.data==banked,"navigation and pause/resume never bank a result")
	print("BEACON UI DISPATCH CHECKS %d failures %d; actual viewport events; native acceptance unverified"%[checks,failures])
	if is_instance_valid(scene.music):scene.music.stop()
	for player in scene.audio.values():player.stop()
	scene.queue_free();await frames(6)
	if DisplayServer.get_name()!="headless":await RenderingServer.frame_post_draw
	quit(1 if failures else 0)
