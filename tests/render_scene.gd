extends SceneTree
## Actual GPU-rendered development scene/input QA. Never native/store screenshots.
const Main=preload("res://game/main.gd")
const Harness=preload("res://tests/test_ui.gd")
var scene: Node2D
var captures: Array=[]
func _initialize() -> void: call_deferred("run_render")
func frames(count: int=3) -> void:
	for index in range(count): await process_frame
func click(key: String) -> bool:
	var button=scene.find_child(key,true,false)
	if not is_instance_valid(button): push_error("Missing actual UI control "+key);return false
	var point=button.get_global_transform_with_canvas()*(button.size*.5)
	var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true;event.position=point
	root.push_input(event,true);await frames(2)
	event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=false;event.position=point
	root.push_input(event,true);await frames(3)
	return true
func capture(key: String,width: int=540,height: int=960) -> bool:
	root.size=Vector2i(width,height);await frames(5)
	await RenderingServer.frame_post_draw
	var image=root.get_texture().get_image()
	if image==null or image.is_empty(): push_error("Actual viewport image absent");return false
	var path="res://tests/evidence/dev-render-"+key+".png"
	if image.save_png(path)!=OK: push_error("Cannot save development render");return false
	captures.append({"key":key,"path":path,"pixels":[image.get_width(),image.get_height()],
		"requested_window_pixels":[width,height],"actual_window_pixels":[root.size.x,root.size.y],
		"scene":scene.screen,"actual_watch_seconds":scene.watch.time,
		"qa_isolated":scene.qa,"source":"Actual Godot OpenGL development viewport; synthetic unavailable Services; not Android/native/store evidence."})
	return true
func run_render() -> void:
	if DisplayServer.get_name()=="headless" or "--qa-isolated" not in OS.get_cmdline_user_args():
		push_error("GPU development render requires real display driver and isolated QA flag");quit(1);return
	root.size=Vector2i(540,960)
	var real=root.get_node_or_null("Services")
	if real!=null: root.remove_child(real);real.queue_free()
	var stub=Harness.FakeServices.new();stub.available=false;stub.name="Services";root.add_child(stub)
	scene=Main.new();root.add_child(scene);await frames(6)
	if not await capture("home-phone"): quit(1);return
	await click("Campaign");await click("Coast0")
	if not await capture("mission-cards"): quit(1);return
	await click("Mission0");await frames(250)
	var aim=InputEventScreenTouch.new();aim.index=1;aim.pressed=true
	aim.position=scene.get_global_transform_with_canvas()*Vector2(140,250)
	root.push_input(aim,true);await frames(35)
	aim.pressed=false;root.push_input(aim,true)
	if not await capture("ordinary-watch"): quit(1);return
	await click("PauseWatch")
	scene._toast("Your watch is paused. No optional ad is ready; resume normally.")
	if not await capture("pause-notice"): quit(1);return
	scene._show_home()
	stub.reserve=161.0;stub.menu_bottom_reserve_changed.emit()
	scene._toast("The harbor is saved locally. Notices remain above the measured banner reserve.")
	if not await capture("home-resize-request",600,960): quit(1);return
	stub.reserve=90.0;stub.menu_bottom_reserve_changed.emit()
	scene._show_workshop()
	if not await capture("workshop-resize-request",600,960): quit(1);return
	scene._show_daily()
	if not await capture("daily",540,960): quit(1);return
	scene._show_settings()
	if not await capture("settings",540,960): quit(1);return
	var report={"scope":"ACTUAL GODOT GPU DEVELOPMENT SCENES AND INPUT; NOT NATIVE/STORE/PHYSICAL EVIDENCE",
		"display_driver":DisplayServer.get_name(),"renderer":RenderingServer.get_video_adapter_name(),
		"captures":captures,"native_services_verified":false,"gameplay_state_injected":false,
		"progress_scope":"Fresh per-process isolated QA save; ordinary first-watch input and natural simulation only. No result/XP/coins/save injection.",
		"notice_scope":"Explicit synthetic unavailable notice text tests its UI layer; no ad benefit or native callback is represented."}
	report["home_notice_synthetic_banner_reserve_units"]=161.0
	var file=FileAccess.open("res://tests/evidence/dev-render-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "));file.close()
	print("BEACON ACTUAL GPU DEVELOPMENT RENDERS %d; not native screenshots"%captures.size())
	if is_instance_valid(scene.music): scene.music.stop()
	for player in scene.audio.values(): player.stop()
	scene.queue_free();await frames(6)
	await RenderingServer.frame_post_draw
	quit(0)
