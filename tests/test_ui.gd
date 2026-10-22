extends SceneTree
const Main=preload("res://game/main.gd")
const Profile=preload("res://game/profile.gd")
class FakeServices extends Node:
	signal menu_bottom_reserve_changed
	var fullscreen=false
	var available=true
	var pending=Callable()
	var rounds=0
	var menu=true
	var reserve=90.0
	func set_menu_visible(value: bool) -> void: menu=value
	func menu_bottom_reserve(_reference: CanvasItem=null) -> float: return reserve if menu else 0.0
	func fullscreen_ad_active() -> bool: return fullscreen
	func can_reward() -> bool: return available
	func reward_requested(_context: String, callback: Callable) -> void: fullscreen=true;pending=callback
	func round_finished() -> void: rounds+=1
	func status() -> String: return "Synthetic UI service stub; not native evidence."
	func unlock(_key: String) -> void: pass
	func submit(_key: String,_value: int) -> void: pass
	func sign_in() -> void: pass
	func open_achievements() -> void: pass
	func open_leaderboards(_key: String="") -> void: pass
	func privacy_options() -> void: pass
var checks=0
var failures=0
var scene: Node2D
var stub: FakeServices
func check(value: bool,label: String) -> void:
	checks+=1
	if not value: failures+=1;push_error("Assertion failed: "+label)
func _initialize() -> void: call_deferred("run_tests")
func frames(count: int=2) -> void:
	for index in range(count): await process_frame
func touch(button_name: String) -> void:
	var button=scene.find_child(button_name,true,false)
	check(is_instance_valid(button),"actual control exists "+button_name)
	if not is_instance_valid(button): return
	var point=button.get_global_transform_with_canvas()*(button.size*.5)
	# Android's ordinary touch-to-mouse GUI path, synthesized explicitly in a
	# headless viewport. Separate ScreenTouch input tests the real beam handler.
	var down=InputEventMouseButton.new();down.button_index=MOUSE_BUTTON_LEFT;down.pressed=true;down.position=point
	root.push_input(down,true);await frames()
	var up=InputEventMouseButton.new();up.button_index=MOUSE_BUTTON_LEFT;up.pressed=false;up.position=point
	root.push_input(up,true);await frames()
func run_tests() -> void:
	if "--qa-isolated" not in OS.get_cmdline_user_args():
		push_error("UI tests require --qa-isolated; no production save opened");quit(1);return
	var real=root.get_node_or_null("Services")
	if real!=null: root.remove_child(real);real.queue_free()
	stub=FakeServices.new();stub.name="Services";root.add_child(stub)
	root.size=Vector2i(540,960)
	scene=Main.new();root.add_child(scene);await frames(4)
	check(scene.qa and scene.save_path.contains("qa-isolated"),"explicit isolated UI storage")
	scene.profile=Profile.new();scene._show_home();await frames()
	check(scene.screen=="home","actual main scene home")
	await touch("Campaign");check(scene.screen=="coasts","touch opens coast list")
	await touch("Coast0");check(scene.screen=="missions","touch opens first coast")
	await touch("Mission0");check(scene.screen=="brief","touch opens real briefing")
	await touch("BeginWatch");check(scene.screen=="watch","touch launches actual scene watch")
	if scene.screen!="watch": quit(1);return
	var aim_before=scene.watch.angle
	var aim_touch=InputEventScreenTouch.new();aim_touch.index=1;aim_touch.pressed=true
	aim_touch.position=scene.get_global_transform_with_canvas()*Vector2(80,380)
	root.push_input(aim_touch,true);await frames()
	check(scene.watch.angle<aim_before,"actual ScreenTouch reaches beam geometry")
	aim_touch.pressed=false;root.push_input(aim_touch,true)
	await frames(8)
	check(scene.watch.time>0,"ordinary active simulation advances")
	await touch("PauseWatch");check(scene.screen=="pause","touch pauses watch")
	var before=scene.watch.time
	await frames(10);check(scene.watch.time==before,"pause freezes model")
	if scene.watch.boats.is_empty(): scene.watch.spawn("skiff",200)
	var ring_fixture=scene.watch.boats[0].duplicate(true)
	ring_fixture.guided=true;ring_fixture.lit=true;ring_fixture.life=ring_fixture.max_life
	check(scene._boat_ring_color(ring_fixture)==scene.TEAL,"actual draw helper shows completed currently lit ring green")
	ring_fixture.lit=false
	check(scene._boat_ring_color(ring_fixture)==scene.GOLD,"actual draw helper returns completed off-beam ring to non-illuminated color")
	ring_fixture.life=ring_fixture.max_life*.2
	check(scene._boat_ring_color(ring_fixture)==scene.CORAL,"completed off-beam urgent ring shows urgency")
	ring_fixture.guided=false;ring_fixture.lit=true
	check(scene._boat_ring_color(ring_fixture)==scene.CORAL,"partial first illumination does not falsely show completed green ring")
	var paused_life=float(scene.watch.boats[0].life)
	var bank=scene.profile.data.duplicate(true)
	scene._request_flare();check(scene.reward_pending and stub.fullscreen,"request pending/SDK fullscreen stub")
	if not stub.pending.is_valid(): quit(1);return
	stub.pending.call(true);await frames(8)
	check(scene.watch.assisted and scene.screen=="pause","earned assistance preserves explicit pause")
	check(scene.watch.time==before and scene.profile.data==bank,"earned behind endcard has no time/banked payout")
	check(scene.watch.boats[0].life==paused_life,"new guided ring drain stays frozen behind earned endcard")
	check(scene.toast_panel.get_index()>scene.ui.get_index() and scene.toast_panel.visible,"earned notice above opaque page children")
	check(scene.toast_panel.mouse_filter==Control.MOUSE_FILTER_IGNORE and scene.toast_label.autowrap_mode==TextServer.AUTOWRAP_WORD_SMART,"notice wraps without intercepting controls")
	scene._resume();check(scene.screen=="pause","resume blocked while fullscreen remains")
	stub.fullscreen=false;await frames(8)
	check(scene.screen=="pause" and scene.watch.time==before,"dismissal never auto resumes")
	check(scene.watch.boats[0].life==paused_life,"dismissed ad awaits explicit Resume before spending ring life")
	scene._resume();await frames(8)
	check(scene.screen=="watch" and scene.watch.time>before,"explicit resume restores usable gameplay")
	scene._pause();stub.pending.call(true)
	check(scene.watch.assisted,"late repeated grant cannot apply a second flare")
	stub.fullscreen=false;scene.reward_pending=false;scene._abandon()
	check(scene.screen=="home" and scene.profile.data==bank and stub.rounds==0,"abandon discards unbanked watch, no cadence")
	scene._start_watch(0);scene.watch.spawn("rescue",260);scene._pause()
	before=scene.watch.time;scene._request_flare();stub.pending.call(false);stub.fullscreen=false;await frames(4)
	check(not scene.watch.assisted and scene.watch.time==before and scene.screen=="pause","unearned callback grants nothing and remains paused")
	stub.available=false;scene._request_flare()
	check(not scene.reward_pending and not scene.watch.assisted,"unavailable/Web fallback cannot fake entitlement")
	stub.available=true
	for boat in scene.watch.boats: boat.guided=true
	scene._pause_refresh();await frames()
	check(scene.find_child("RewardFlare",true,false).disabled,"already-guided fleet cannot offer a useless ad")
	scene._request_flare();check(not scene.reward_pending and not scene.watch.assisted,"direct request cannot bypass useful-assistance eligibility")
	scene._abandon();scene._start_watch(0)
	# Synthetic accounting fixture only, not native progression or capture evidence.
	scene.watch.done=true;scene.watch.won=true;scene.watch.rescued=4
	scene._finish_watch();await frames()
	bank=scene.profile.data.duplicate(true);scene._finish_watch()
	check(scene.profile.data==bank and stub.rounds==1,"natural result bank and cadence once")
	# Round Two second-chance lifecycle. Synthetic fixture, not native evidence.
	scene._show_home();scene._start_watch(0)
	for index in range(3): scene.watch.spawn("rescue",100+index*100);scene.watch.boats[index].life=.001
	scene.watch.step(.05);scene._finish_watch();await frames()
	bank=scene.profile.data.duplicate(true);before=scene.watch.time
	check(scene.screen=="results" and not scene.banked and scene.watch.can_continue(),"loss retains unbanked same-watch second chance")
	check(stub.rounds==1,"offering continue neither banks nor advances interstitial cadence")
	scene._request_continue();stub.pending.call(false);stub.fullscreen=false;await frames()
	check(scene.watch.done and not scene.watch.continued and scene.profile.data==bank,"unearned continue preserves result and bank")
	scene._request_continue();var repeated_continue: Callable=stub.pending
	stub.pending.call(true);await frames(8)
	check(scene.screen=="pause" and scene.watch.continued and scene.watch.assisted and not scene.banked,"earned continue enters explicit pause without banking")
	check(scene.watch.time==before and scene.profile.data==bank,"covered continue does not advance simulation or rewards")
	check(scene.watch.boats.all(func(boat): return boat.life==boat.max_life),"continued rings remain at restored real model budgets behind endcard")
	scene._resume();check(scene.screen=="pause","continue cannot resume behind fullscreen endcard")
	stub.fullscreen=false;await frames(8)
	check(scene.screen=="pause" and scene.watch.time==before,"continue dismissal still requires explicit resume")
	scene._resume();await frames(8)
	check(scene.screen=="watch" and scene.watch.time>before,"explicit continue resume is usable")
	var continued_life=float(scene.watch.boats[0].life)
	repeated_continue.call(true)
	check(scene.watch.continued and not scene.reward_pending,"duplicate continue callback is consumed once")
	check(scene.watch.boats[0].life==continued_life,"duplicate continue callback cannot restore spent ring life")
	scene._pause();scene._abandon()
	check(scene.profile.data==bank and stub.rounds==1,"abandoning continued unfinished watch grants no fictitious bank")
	scene._start_watch(0);scene.watch.done=true;scene.watch.won=false
	scene.watch.lost_boats=[{"kind":"skiff","x":200.0,"drift":0.0}]
	scene._finish_watch();scene._back();await frames()
	check(scene.screen=="home" and scene.banked and stub.rounds==2,"Back from uncontinued natural loss banks/cadences once")
	var after_loss=scene.profile.data.duplicate(true);scene._bank_watch()
	check(scene.profile.data==after_loss and stub.rounds==2,"loss banking remains idempotent")
	scene.profile.data.missions={}
	scene._show_missions(0);await frames()
	var stars=scene.find_children("StarRating","HBoxContainer",true,false)
	check(stars.size()==5 and stars[0].get_child_count()==3,"mission cards use three actual Kenney star textures")
	check(stars[0].get_child(0).texture is Texture2D,"filled/empty rating is rendered artwork")
	check(stars[0].get_child(0).texture==scene.textures["star-empty"] and stars[1].get_child(0).texture==scene.textures["star-empty"],"fresh and locked watches contain empty ratings")
	var empty_image=scene.textures["star-empty"].get_image()
	var filled_image=scene.textures["star-filled"].get_image()
	check(empty_image.get_pixel(empty_image.get_width()/2,empty_image.get_height()/2).a<.01,"empty vector star has genuinely transparent center")
	check(filled_image.get_pixel(filled_image.get_width()/2,filled_image.get_height()/2).a>.99,"earned Kenney star has filled center")
	scene.profile.data.missions["0"]=2;scene._show_missions(0);await frames()
	stars=scene.find_children("StarRating","HBoxContainer",true,false)
	check(stars[0].get_child(0).texture==scene.textures["star-filled"] and stars[0].get_child(1).texture==scene.textures["star-filled"] and stars[0].get_child(2).texture==scene.textures["star-empty"],"two-earned rating uses exactly two gold-filled and one hollow texture")
	for id in range(60): scene.profile.data.missions[str(id)]=3
	scene._show_coasts();await frames()
	check(scene.find_child("Coast11",true,false)!=null,"twelfth level pack is reachable in real scene")
	scene._show_workshop();await frames()
	check(scene.find_child("Upgrade_horn",true,false)!=null and scene.find_child("Upgrade_breakwater",true,false)!=null,"new lighthouse upgrades have real controls")

	scene._show_home();scene._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(scene.screen=="home","Home Back safe no-op")
	scene._show_workshop();scene._back();check(scene.screen=="home","subpage Back returns Home")
	scene._start_watch(0);scene.watch.spawn("skiff",270);scene.watch.boats[0].guided=true
	paused_life=float(scene.watch.boats[0].life)
	scene._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	before=scene.watch.time;await frames(4)
	check(scene.application_suspended and scene.screen=="pause" and scene.watch.time==before,"background lifecycle freezes and pauses")
	scene._notification(Node.NOTIFICATION_APPLICATION_RESUMED);await frames(4)
	check(not scene.application_suspended and scene.screen=="pause" and scene.watch.time==before,"foreground lifecycle awaits explicit resume")
	check(scene.watch.boats[0].life==paused_life,"background and foreground transitions spend no guided ring life")
	scene._show_home();await frames(2)
	check(scene.page_scroll.position.y+scene.page_scroll.size.y<=846.1,"measured banner reserve bounds content")
	stub.reserve=161.0;stub.menu_bottom_reserve_changed.emit();scene._toast("Measured native banner reserve keeps this notice clear.");await frames(2)
	check(scene.toast_panel.position.y+scene.toast_panel.size.y<=775.0,"notice remains above measured 161-unit banner reserve")
	check(scene.toast_panel.get_index()>scene.ui.get_index() and scene.toast_panel.mouse_filter==Control.MOUSE_FILTER_IGNORE,"repositioned notice remains topmost and noninteractive")
	print("BEACON UI CHECKS %d failures %d; actual scene/touch + synthetic service lifecycle; no native acceptance"%[checks,failures])
	stub.pending=Callable();repeated_continue=Callable()
	scene.queue_free();await frames()
	quit(1 if failures else 0)
