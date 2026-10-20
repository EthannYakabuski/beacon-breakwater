extends SceneTree
## Synthetic cold-scene regression only; no native ad or gameplay acceptance.
const Main=preload("res://game/main.gd")
class NoticeServices extends Node:
	signal menu_bottom_reserve_changed
	var reserve=0.0
	var fullscreen=false
	var pending=Callable()
	func set_menu_visible(_value: bool) -> void: pass
	# Force both measured geometry cases independently of native menu visibility.
	# Actual native pause remains banner-free; this is a geometry stress stub.
	func menu_bottom_reserve(_reference: CanvasItem=null) -> float: return reserve
	func fullscreen_ad_active() -> bool: return fullscreen
	func can_reward() -> bool: return true
	func reward_requested(_context: String,callback: Callable) -> void:
		fullscreen=true;pending=callback
var checks=0
var failures=0
var scene: Node2D
var stub: NoticeServices
func check(value: bool,label: String) -> void:
	checks+=1
	if not value: failures+=1;push_error("Notice regression failed: "+label)
func _initialize() -> void: call_deferred("run_tests")
func frames(count: int=1) -> void:
	for index in range(count): await process_frame
func bounds(label: String,reserve: float) -> void:
	check(scene.toast_panel is Panel and not scene.toast_panel is Container,label+" plain panel without child-minimum feedback")
	check(scene.toast_panel.size==Vector2(500,72),label+" exact500x72 panel")
	check(scene.toast_panel.position.x==20 and scene.toast_panel.position.y>=0,label+" nonnegative panel placement")
	check(scene.toast_panel.position.y+scene.toast_panel.size.y<=minf(883,936-reserve)-8,label+" measured reserve respected")
	check(scene.toast_label.position==Vector2(14,10) and scene.toast_label.size==Vector2(472,52),label+" bounded472x52 label")
	check(scene.toast_panel.get_index()>scene.ui.get_index(),label+" topmost above rebuilt pause cards")
	check(scene.toast_panel.mouse_filter==Control.MOUSE_FILTER_IGNORE and scene.toast_label.mouse_filter==Control.MOUSE_FILTER_IGNORE,label+" both controls ignore input")
func cold_case(granted: bool,reserve: float) -> void:
	stub=NoticeServices.new();stub.name="Services";stub.reserve=reserve;root.add_child(stub)
	scene=Main.new();root.add_child(scene);await frames(3)
	check(not is_instance_valid(scene.toast_panel),"fresh scene has no previously laid-out notice")
	scene._start_watch(0)
	# Explicit unbanked synthetic test boat, not capture/native progress evidence.
	scene.watch.spawn("skiff",260);scene._pause()
	var before_time=scene.watch.time
	var before_save=scene.profile.data.duplicate(true)
	scene._request_flare();check(stub.pending.is_valid(),"ordinary request callback installed")
	if not stub.pending.is_valid(): return
	if not granted: stub.fullscreen=false
	stub.pending.call(granted)
	await frames(1);bounds("first frame",reserve)
	await frames(12);bounds("settled",reserve)
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		var image=root.get_texture().get_image()
		var proof="res://tests/evidence/toast-fixed-panel-reserve%d-%s.png"%[int(reserve),"earned" if granted else "unearned"]
		check(image!=null and not image.is_empty() and image.save_png(proof)==OK,"actual GPU synthetic cold notice proof written")
	check(scene.toast_panel.visible and scene.notice_left>0,"first callback notice visible")
	check(scene.watch.time==before_time and scene.screen=="pause","callback preserves simulation pause")
	check(scene.watch.assisted==granted and scene.profile.data==before_save,"callback benefit and banked state remain distinct")
	if granted:
		scene._resume();check(scene.screen=="pause","earned fullscreen still blocks resume")
	stub.fullscreen=false
	# Exercise actual Viewport GUI hit-testing while the notice is visible.
	var button=scene.find_child("ResumeWatch",true,false)
	var point=button.get_global_transform_with_canvas()*(button.size*.5)
	var down=InputEventMouseButton.new();down.button_index=MOUSE_BUTTON_LEFT;down.pressed=true;down.position=point
	root.push_input(down,true);await frames(1)
	var up=InputEventMouseButton.new();up.button_index=MOUSE_BUTTON_LEFT;up.pressed=false;up.position=point
	root.push_input(up,true);await frames(2)
	check(scene.screen=="watch","visible notice does not intercept Resume control")
	scene._pause();scene._process(5.1);await frames(1)
	check(scene.notice_left==0 and not scene.toast_panel.visible,"notice expires after its five-second timer")
	check(scene.toast_panel.size==Vector2(500,72),"expired notice has no size feedback")
	if is_instance_valid(scene.music):scene.music.stop()
	for player in scene.audio.values():player.stop()
	scene.queue_free();stub.queue_free();await frames(6)
	if DisplayServer.get_name()!="headless":await RenderingServer.frame_post_draw
func run_tests() -> void:
	if "--qa-isolated" not in OS.get_cmdline_user_args():
		push_error("Notice tests require isolated QA storage");quit(1);return
	var real=root.get_node_or_null("Services")
	if real!=null:root.remove_child(real);real.queue_free();await frames(1)
	root.size=Vector2i(540,960)
	for reserve in [0.0,161.0]:
		for granted in [false,true]:await cold_case(granted,reserve)
	print("BEACON COLD NOTICE CHECKS %d failures %d; synthetic callbacks/reserve0and161; not native acceptance"%[checks,failures])
	quit(1 if failures else 0)
