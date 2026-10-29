extends Node2D
const Profile = preload("res://game/profile.gd")
const Watch = preload("res://game/watch.gd")
const Store = preload("res://game/save_store.gd")
const INK = Color("102e40")
const CREAM = Color("fbefd4")
const GOLD = Color("f6c66d")
const TEAL = Color("74cdc4")
const CORAL = Color("ef967f")
var profile = Profile.new()
var watch = Watch.new()
var missions: Dictionary = {}
var catalog: Dictionary = {}
var services: Node
var ui: Control
var page_scroll: ScrollContainer
var page_column: VBoxContainer
var font: Font
var textures: Dictionary = {}
var audio: Dictionary = {}
var music: AudioStreamPlayer
var music_track=""
var environment: Dictionary={}
var screen = "home"
var clock = 0.0
var notice = ""
var notice_left = 0.0
var selected_mission = 0
var selected_coast = 0
var banked = false
var bank_receipt: Dictionary = {}
var reward_pending = false
var reward_serial=0
var application_suspended = false
var run_generation = 0
var save_path = "user://beacon-progress-v1.json"
var qa = false
var last_save_ok = true
var hud: Label
var life_icons: HBoxContainer
var horn_button: Button
var toast_panel: Panel
var toast_label: Label

func _ready() -> void:
	font = ThemeDB.fallback_font
	qa = "--qa-isolated" in OS.get_cmdline_user_args()
	if qa: save_path = "user://beacon-qa-isolated-%d.json" % OS.get_process_id()
	services = get_node_or_null("/root/Services")
	if is_instance_valid(services) and services.has_signal("menu_bottom_reserve_changed"):
		services.connect("menu_bottom_reserve_changed",_layout_page)
	get_viewport().size_changed.connect(_fit_stage)
	missions = JSON.parse_string(FileAccess.get_file_as_string("res://game/missions.json"))
	catalog = JSON.parse_string(FileAccess.get_file_as_string("res://game/catalog.json"))
	var loaded = Store.load_progress(save_path)
	if not loaded.data.is_empty(): profile.restore(loaded.data)
	profile.roll_day(_today())
	if loaded.recovered: _toast("Recovered your last good harbor save.")
	for key in Watch.KINDS: textures[key]=load("res://assets/ships/"+key+".png")
	textures["star-filled"]=load("res://assets/ui/star-filled.png")
	textures["star-empty"]=load("res://assets/ui/star-empty.svg")
	for entry in [["harbor","harbor-background-v2"],["lighthouse","lighthouse-v2"],["shoal","shoal-v2"]]:
		var path="res://assets/art/"+entry[1]+".png"
		if ResourceLoader.exists(path): environment[entry[0]]=load(path)
	if DisplayServer.get_name() != "headless": _setup_audio()
	_fit_stage()
	_show_home()
	set_process(true)

func _today() -> int:
	return int(floor(Time.get_unix_time_from_system()/86400.0))

func _fit_stage() -> void:
	var view = get_viewport().get_visible_rect().size
	var factor = minf(view.x/540.0,view.y/960.0)
	scale = Vector2.ONE*factor
	position = (view-Vector2(540,960)*factor)*0.5
	_layout_page()

func _ads_active() -> bool:
	return is_instance_valid(services) and services.has_method("fullscreen_ad_active") and bool(services.fullscreen_ad_active())

func gameplay_suspended() -> bool:
	return application_suspended or reward_pending or _ads_active() or screen != "watch"

func _process(delta: float) -> void:
	clock += delta
	notice_left = maxf(0.0,notice_left-delta)
	if is_instance_valid(toast_panel): toast_panel.visible=notice_left>0.0
	if screen == "watch" and not gameplay_suspended():
		if Input.is_physical_key_pressed(KEY_LEFT): watch.angle -= delta*1.2
		if Input.is_physical_key_pressed(KEY_RIGHT): watch.angle += delta*1.2
		watch.angle=clampf(watch.angle,-PI+.1,-.1)
		watch.step(delta)
		for event in watch.events:
			if event.event == "rescue": _sound("rescue")
			elif event.event == "lost": _sound("loss")
			elif event.event == "guided": _sound("guided")
			elif event.event == "arrival": _sound("arrival")
		watch.events.clear()
		_refresh_hud()
		if watch.done: _finish_watch()
	_sync_audio_state()
	queue_redraw()

func _setup_audio() -> void:
	for key in ["click","rescue","warning","finish","guided","arrival","horn","upgrade","continue","flare","loss"]:
		var player=AudioStreamPlayer.new()
		player.stream=load("res://assets/audio/"+key+".ogg")
		player.volume_db=-21 if key=="arrival" else -17
		add_child(player);audio[key]=player
	music=AudioStreamPlayer.new();music.volume_db=-10;add_child(music)

func _select_music(track: String) -> void:
	if not is_instance_valid(music): return
	if music_track!=track:
		music.stop();music_track=track
		var stream=load("res://assets/audio/music-"+track+".wav").duplicate()
		if stream is AudioStreamWAV:
			stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin=0;stream.loop_end=int(round(stream.get_length()*stream.mix_rate))
		music.stream=stream
	_sync_audio_state()

func _sync_audio_state() -> void:
	if not is_instance_valid(music): return
	if not bool(profile.data.settings.music): music.stop();return
	if music.stream!=null and not music.playing: music.play()
	var pause_music: bool = application_suspended or _ads_active()
	# Web samples restart their buffer on redundant unpause calls.
	if music.stream_paused != pause_music:
		music.stream_paused = pause_music

func _exit_tree() -> void:
	for player in audio.values():
		if is_instance_valid(player): player.stop();player.stream=null
	if is_instance_valid(music): music.stop();music.stream=null

func _sound(key: String) -> void:
	if bool(profile.data.settings.sound) and audio.has(key): audio[key].play()

func _toast(text: String) -> void:
	notice=text; notice_left=5.0
	if not is_instance_valid(toast_panel):
		toast_panel=Panel.new();toast_panel.name="KeeperNotice"
		toast_panel.position=Vector2(20,718);toast_panel.size=Vector2(500,72)
		toast_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
		toast_panel.clip_contents=true
		toast_panel.add_theme_stylebox_override("panel",_toast_style())
		toast_label=_label("",17,CREAM)
		toast_label.position=Vector2(14,10);toast_label.size=Vector2(472,52)
		toast_label.clip_text=true;toast_label.max_lines_visible=2
		toast_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		toast_panel.add_child(toast_label)
		add_child(toast_panel)
	toast_label.text=text;toast_panel.visible=true
	move_child(toast_panel,get_child_count()-1)
	_layout_page()
	if qa: print("BEACON_QA_NOTICE "+text)

func _save() -> void:
	last_save_ok=Store.save_progress(save_path,profile.data)
	if not last_save_ok: _toast("Could not save. Keep the app open and check available storage.")

func _menu(visible: bool) -> void:
	if is_instance_valid(services) and services.has_method("set_menu_visible"): services.set_menu_visible(visible)

func _clear_ui() -> void:
	if is_instance_valid(ui):
		# Touch release follows its emulated mouse callback in the same dispatch.
		# Keep retiring controls attached until deferred deletion completes.
		ui.hide();ui.mouse_filter=Control.MOUSE_FILTER_IGNORE
		ui.name="RetiredInterface-%d"%ui.get_instance_id();ui.queue_free()
	ui=Control.new();ui.name="Interface";ui.size=Vector2(540,960)
	ui.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	if is_instance_valid(toast_panel): move_child(toast_panel,get_child_count()-1)
	page_scroll=null;page_column=null

func _label(text: String, size: int = 20, color: Color = CREAM) -> Label:
	var label=Label.new();label.text=text
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return label

func _button(text: String, callback: Callable, key: String = "", disabled: bool = false) -> Button:
	var button=Button.new();button.text=text;button.custom_minimum_size=Vector2(0,58)
	button.name=key if not key.is_empty() else text.to_snake_case().validate_node_name()
	button.add_theme_font_size_override("font_size",19)
	button.add_theme_color_override("font_color",INK)
	button.add_theme_color_override("font_disabled_color",Color("81959c"))
	var normal=StyleBoxFlat.new();normal.bg_color=GOLD
	normal.corner_radius_top_left=14;normal.corner_radius_top_right=14
	normal.corner_radius_bottom_left=14;normal.corner_radius_bottom_right=14
	normal.content_margin_left=14;normal.content_margin_right=14
	button.add_theme_stylebox_override("normal",normal)
	var hover=normal.duplicate();hover.bg_color=Color("ffdda0")
	button.add_theme_stylebox_override("hover",hover)
	var pressed=normal.duplicate();pressed.bg_color=TEAL
	button.add_theme_stylebox_override("pressed",pressed)
	button.disabled=disabled
	button.pressed.connect(func():
		if _ads_active() or reward_pending: return
		_sound("click");callback.call())
	return button

func _page(title: String, subtitle: String = "", back: bool = true) -> VBoxContainer:
	_clear_ui();_menu(true)
	var heading=_label(title,30,CREAM);heading.position=Vector2(24,35);heading.size=Vector2(492,74);ui.add_child(heading)
	var description=_label(subtitle,16,TEAL);description.position=Vector2(26,112);description.size=Vector2(488,53);ui.add_child(description)
	page_scroll=ScrollContainer.new();page_scroll.position=Vector2(24,180);page_scroll.size=Vector2(492,600)
	page_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	ui.add_child(page_scroll)
	page_column=VBoxContainer.new();page_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	page_column.add_theme_constant_override("separation",14)
	page_scroll.add_child(page_column)
	if back:
		var home=_button("Back to harbor",_show_home,"BackHome")
		home.position=Vector2(24,809);home.size=Vector2(492,58);ui.add_child(home)
	_layout_page()
	_select_music("coast-%02d"%int(watch.config.get("coast",0)) if screen in ["pause","results"] else "menu")
	return page_column

func _layout_page() -> void:
	if not is_instance_valid(ui): return
	var reserve=0.0
	if is_instance_valid(services) and services.has_method("menu_bottom_reserve"):
		reserve=float(services.menu_bottom_reserve(self))
	var bottom=minf(883.0,936.0-reserve)
	if is_instance_valid(toast_panel): toast_panel.position.y=minf(718.0,bottom-toast_panel.size.y-8.0)
	if is_instance_valid(page_scroll): page_scroll.size.y=maxf(280.0,bottom-180.0-(76.0 if ui.has_node("BackHome") else 0.0))
	var back=ui.get_node_or_null("BackHome")
	if is_instance_valid(back): back.position.y=bottom-58.0

func _card(column: VBoxContainer, title: String, description: String, action: String = "", callback: Callable = Callable(), key: String = "", disabled: bool = false) -> VBoxContainer:
	var panel=PanelContainer.new();panel.mouse_filter=Control.MOUSE_FILTER_PASS
	var style=StyleBoxFlat.new();style.bg_color=Color("183f50")
	style.border_color=Color("3a6570");style.set_border_width_all(1);style.set_corner_radius_all(15)
	style.content_margin_left=17;style.content_margin_right=17;style.content_margin_top=15;style.content_margin_bottom=15
	panel.add_theme_stylebox_override("panel",style)
	column.add_child(panel)
	var box=VBoxContainer.new();box.add_theme_constant_override("separation",9);panel.add_child(box)
	box.add_child(_label(title,23,GOLD));box.add_child(_label(description,17,CREAM))
	if not action.is_empty(): box.add_child(_button(action,callback,key,disabled))
	return box

func _star_row(column: VBoxContainer, earned: int, total: int=3) -> void:
	var row=HBoxContainer.new();row.name="StarRating";row.add_theme_constant_override("separation",4);column.add_child(row)
	for index in range(total):
		var icon=TextureRect.new();icon.texture=textures["star-filled" if index<earned else "star-empty"]
		icon.custom_minimum_size=Vector2(22 if total==3 else 17,22 if total==3 else 17)
		icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.tooltip_text="Earned star" if index<earned else "Empty star";row.add_child(icon)

func _show_home() -> void:
	screen="home";profile.roll_day(_today())
	var column=_page("BEACON BREAKWATER","A small lighthouse. A coast worth keeping.",false)
	var metrics="Keeper %d   |   %d coins   |   %d XP" % [profile.level(),profile.data.coins,profile.data.xp]
	_card(column,metrics,"%d boats home  Â·  %d perfect watches\nNext: %s" % [profile.data.rescued,profile.data.perfect_watches,missions.missions[profile.unlocked_mission()].name],"Keep the light",_show_coasts,"Campaign")
	var row=HBoxContainer.new();row.add_theme_constant_override("separation",12);column.add_child(row)
	for entry in [["Endless watch",_start_endless,"Endless"],["Daily watch",_show_daily,"Daily"]]:
		var b=_button(entry[0],entry[1],entry[2]);b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(b)
	column.add_child(_button("The workshop  Â·  improve your beacon",_show_workshop,"Workshop"))
	column.add_child(_button("Boat log & records",_show_log,"BoatLog"))
	column.add_child(_button("Settings, privacy & Play Games",_show_settings,"Settings"))
	column.add_child(_label("Drag the light, hold a boat in its beam, bring it home.\nLocal play works offline. Optional Android test ads need a connection.",16,TEAL))

func _show_coasts() -> void:
	screen="coasts"
	var column=_page("The twelve coasts","Sixty authored watches. A different score in every pack.")
	for index in range(missions.coasts.size()):
		var coast=index;var unlocked=profile.unlocked_mission()>=coast*5;var stars=0
		for mission in range(coast*5,coast*5+5): stars+=int(profile.data.missions.get(str(mission),0))
		var card=_card(column,str(missions.coasts[index].name),str(missions.coasts[index].tagline),"Open coast" if unlocked else "Clear the previous coast",func():_show_missions(coast),"Coast%d"%coast,not unlocked)
		_star_row(card,stars,15)

func _show_missions(coast: int) -> void:
	selected_coast=coast;screen="missions"
	var column=_page(str(missions.coasts[coast].name),"Filled stars mark your best watch. Replays remain available.")
	for index in range(coast*5,coast*5+5):
		var mission=index;var definition=missions.missions[index];var available=index<=profile.unlocked_mission()
		var card=_card(column,"%02d  %s"%[index+1,definition.name],_mission_summary(definition),"Start watch" if available else "Follow the previous light",func():_start_watch(mission),"Mission%d"%mission,not available)
		_star_row(card,int(profile.data.missions.get(str(index),0)))

func _mission_summary(definition: Dictionary) -> String:
	var summary="%d boats to save"%int(definition.target)
	var required=str(definition.get("required_kind",""))
	if not required.is_empty():
		summary+="\nInclude %d %s"%[int(definition.get("required_count",1)),str(Watch.KINDS[required].label).to_lower()]
	return summary

func _show_brief(index: int, mode: String = "campaign") -> void:
	# Compatibility for old callers: there is no intermediate briefing screen.
	_start_watch(index,mode)

func _start_endless() -> void:
	_start_watch(0,"endless")

func _start_watch(index: int, mode: String = "campaign") -> void:
	if _ads_active() or reward_pending: return
	run_generation+=1;banked=false;bank_receipt={}
	selected_mission=index
	watch=Watch.new();watch.start(missions.missions[index],profile.data.upgrades,mode)
	screen="watch";_build_watch_ui();_menu(false)

func _build_watch_ui() -> void:
	_clear_ui();_menu(false)
	_select_music("coast-%02d"%int(watch.config.get("coast",0)))
	var title=_label("ENDLESS WATCH" if watch.mode=="endless" else str(watch.config.name).to_upper(),22,GOLD)
	title.position=Vector2(24,28);title.size=Vector2(400,40);ui.add_child(title)
	hud=_label("",18,CREAM);hud.name="WatchHUD";hud.position=Vector2(24,82);hud.size=Vector2(490,64);ui.add_child(hud)
	life_icons=HBoxContainer.new();life_icons.name="WatchChances";life_icons.position=Vector2(352,77)
	life_icons.add_theme_constant_override("separation",7);life_icons.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var life_caption=_label("CHANCES",13,CREAM);life_caption.custom_minimum_size=Vector2(63,31)
	life_caption.autowrap_mode=TextServer.AUTOWRAP_OFF;life_caption.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	life_icons.add_child(life_caption)
	for index in range(int(watch.config.get("lives",3))):
		var slot=Control.new();slot.name="Chance%d"%index;slot.custom_minimum_size=Vector2(23,31)
		slot.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var icon=TextureRect.new();icon.name="Boat";icon.texture=textures["skiff"];icon.size=Vector2(23,31)
		icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;slot.add_child(icon)
		var cross=_label("×",25,CORAL);cross.name="Spent";cross.position=Vector2(3,-1);cross.size=Vector2(23,31)
		cross.mouse_filter=Control.MOUSE_FILTER_IGNORE;slot.add_child(cross);life_icons.add_child(slot)
	ui.add_child(life_icons)
	horn_button=_button("Foghorn",_horn,"Foghorn");horn_button.position=Vector2(24,808);horn_button.size=Vector2(240,62);ui.add_child(horn_button)
	var pause=_button("Pause / assistance",_pause,"PauseWatch");pause.position=Vector2(276,808);pause.size=Vector2(240,62);ui.add_child(pause)
	var hint=_label("DRAG THE LIGHT  Â·  HOLD UNTIL THE RING FILLS",15,TEAL)
	hint.position=Vector2(24,892);hint.size=Vector2(492,35);hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;ui.add_child(hint)
	_refresh_hud()

func _refresh_hud() -> void:
	if not is_instance_valid(hud): return
	hud.text="%d HOME   /   %s\n%02d:%02d   ·   %d points   ·   chain %d" % [watch.rescued,"∞" if watch.mode=="endless" else str(int(watch.config.target)),int(watch.time)/60,int(watch.time)%60,watch.score,watch.chain]
	if is_instance_valid(life_icons):
		var lives=int(watch.config.get("lives",3))
		life_icons.tooltip_text="%d chances remaining. Each lost boat spends one; the watch ends when none remain."%maxi(0,lives-watch.lost)
		for index in range(lives):
			var slot=life_icons.get_node("Chance%d"%index)
			var available=index>=watch.lost
			slot.set_meta("available",available)
			slot.get_node("Boat").modulate=TEAL if available else Color(.30,.40,.47,.60)
			slot.get_node("Spent").visible=not available
	if is_instance_valid(horn_button):
		horn_button.text="Foghorn  Â·  %d / %d" % [watch.horn_charges,watch.max_horn_charges()]
		horn_button.disabled=watch.horn_charges<=0

func _horn() -> void:
	if gameplay_suspended(): return
	if watch.foghorn(): _sound("horn")

func _pause() -> void:
	if screen != "watch": return
	screen="pause"
	var column=_page("A quiet moment","Watch paused at %02d:%02d  Â·  %d boats home" % [int(watch.time)/60,int(watch.time)%60,watch.rescued],false)
	_card(column,"The light will wait","Your watch stays frozen while this page or a fullscreen ad is open. Returning from an ad never resumes the watch automatically.","Resume the watch",_resume,"ResumeWatch")
	var available=is_instance_valid(services) and services.has_method("can_reward") and bool(services.can_reward())
	var explanation="Guide every boat currently on the water. Once per watch; marks this watch assisted, so it cannot replace your unassisted endless best."
	if not available: explanation+="\nNo optional ad is ready. Ordinary play and the free foghorn remain available."
	if not watch.can_flare(): explanation+="\nNo endangered boat needs a flare right now, or this watch's flare is already used."
	_card(column,"Rescue flare  Â·  optional ad",explanation,"Request rescue flare" if available and watch.can_flare() else "Flare not needed" if not watch.can_flare() else "Ad unavailable",_request_flare,"RewardFlare",not available or not watch.can_flare())
	_card(column,"Return to harbor","This unfinished watch is not a resumable save. Leaving discards its unbanked boats and points; your existing harbor progress is kept.","Leave this watch",_abandon,"AbandonWatch")
	_menu(false)

func _resume() -> void:
	if screen != "pause" or _ads_active() or reward_pending or application_suspended: return
	screen="watch";_build_watch_ui()

func _abandon() -> void:
	if _ads_active() or reward_pending: return
	run_generation+=1;_show_home()

func _request_flare() -> void:
	if screen != "pause" or reward_pending or not watch.can_flare() or not is_instance_valid(services): return
	if not services.has_method("can_reward") or not bool(services.can_reward()):
		_toast("No ad is ready. You can resume normally.");return
	reward_pending=true;reward_serial+=1
	var request_id=reward_serial
	var generation=run_generation
	var requested_watch=watch
	services.reward_requested("one breakwater rescue flare",func(granted: bool):
		if generation != run_generation or requested_watch != watch or request_id!=reward_serial or not reward_pending: return
		reward_pending=false
		if granted and screen=="pause" and not watch.done and watch.rescue_flare():
			_sound("flare");_toast("Rescue flare earned. Resume when you are ready.")
		else: _toast("No flare granted. Your watch remains paused.")
		# Never enter the simulation here: earned may arrive behind an open endcard.
		if screen=="pause": _pause_refresh())

func _pause_refresh() -> void:
	if screen!="pause": return
	screen="watch";_pause()

func _bank_watch() -> void:
	if banked: return
	banked=true;bank_receipt=profile.bank(watch.result(),_today())
	_sync_progress();_save()
	if is_instance_valid(services) and services.has_method("round_finished"): services.round_finished()

func _finish_watch() -> void:
	if screen=="results": return
	_sound("finish" if watch.won else "loss")
	if watch.won or not watch.can_continue(): _bank_watch()
	_show_results()

func _show_results() -> void:
	screen="results"
	var column=_page("A coast kept warm" if watch.won else "A second light?","Watch complete  Â·  %d boats home  Â·  %d lost"%[watch.rescued,watch.lost],false)
	if banked:
		_card(column,"%d points  Â·  best chain %d"%[watch.score,watch.best_chain],"Banked +%d coins / +%d XP\nLevel bonus %d coins  Â·  daily bonus %d coins"%[bank_receipt.coins,bank_receipt.xp,bank_receipt.level_bonus,bank_receipt.daily_bonus])
		_star_row(column,int(bank_receipt.stars))
	else:
		_card(column,"Your rescue crew is standing by","One optional earned ad recovers lost vessels and extends this same watch. Nothing is banked until you finish or leave this result.")
	if watch.can_continue() and not banked:
		var ready=is_instance_valid(services) and services.has_method("can_reward") and bool(services.can_reward())
		column.add_child(_button("Continue this watch Â· optional ad" if ready else "Continue ad unavailable",_request_continue,"RewardContinue",not ready))
	if watch.assisted: column.add_child(_label("This watch is assisted. Unassisted endless records are preserved; a second chance cannot earn a perfect-watch record.",16,TEAL))
	if watch.mode=="campaign" and watch.won and watch.mission<missions.missions.size()-1:
		column.add_child(_button("Follow the next light",func():_leave_results(func():_start_watch(watch.mission+1)),"NextWatch"))
	column.add_child(_button("Keep this watch again",func():_leave_results(func():_start_watch(watch.mission,watch.mode)),"RetryWatch"))
	column.add_child(_button("Return to harbor",func():_leave_results(_show_home),"ResultsHome"))

func _leave_results(action: Callable) -> void:
	if reward_pending or _ads_active(): return
	_bank_watch();action.call()

func _request_continue() -> void:
	if screen!="results" or banked or reward_pending or not watch.can_continue() or not is_instance_valid(services): return
	if not services.has_method("can_reward") or not bool(services.can_reward()): _toast("No continue ad is ready. Your result remains available.");return
	reward_pending=true;reward_serial+=1
	var request_id=reward_serial
	var generation=run_generation
	var requested_watch=watch
	services.reward_requested("one breakwater second chance",func(granted: bool):
		if generation!=run_generation or requested_watch!=watch or request_id!=reward_serial or not reward_pending: return
		reward_pending=false
		if granted and screen=="results" and not banked and watch.continue_watch():
			_sound("continue");screen="watch";_pause();_toast("Second chance earned. Resume when you are ready.")
		else:
			_toast("No second chance granted. Your result is unchanged.")
			if screen=="results": _show_results())

func _sync_progress() -> void:
	var metrics=profile.metrics()
	for achievement in catalog.achievements:
		if int(metrics.get(achievement.metric,0)) >= int(achievement.target) and achievement.key not in profile.data.unlocked:
			profile.data.unlocked.append(achievement.key)
			if is_instance_valid(services) and services.has_method("unlock"): services.unlock(achievement.key)
	for board in catalog.leaderboards:
		if is_instance_valid(services) and services.has_method("submit"): services.submit(board.key,int(metrics.get(board.metric,0)))

func _show_workshop() -> void:
	screen="workshop"
	var column=_page("The workshop","%d coins  Â·  equipment stays with your keeper" % profile.data.coins)
	var descriptions={"lens":"A wider beam can guide neighboring boats together. +0.024 radians total width per level.","focus":"A steady light establishes guidance 13% faster per level.","harbor":"Clearer navigation buys each boat 1.35 extra seconds per level.","horn":"Longer foghorn protection, faster recharge, and another charge every two levels.","breakwater":"Better coastal markers reduce extra danger close to shoals."}
	for key in Profile.UPGRADE_KEYS:
		var upgrade=key;var level=int(profile.data.upgrades[key]);var cost=profile.upgrade_cost(key)
		_card(column,str(key).capitalize()+"  %d / 6" % level,descriptions[key],"Maximum reached" if level>=6 else "Upgrade  Â·  %d coins" % cost,func():
			if profile.buy_upgrade(upgrade):
				_sound("upgrade");_sync_progress();_save();_show_workshop()
			else: _toast("Keep a few more watches to afford that upgrade."),"Upgrade_"+key,level>=6 or int(profile.data.coins)<cost)

func _show_daily() -> void:
	screen="daily";profile.roll_day(_today())
	var column=_page("A new dawn","Daily progress uses the device's UTC day. Local clocks are not anti-cheat secure.")
	var claimed=_today()<=int(profile.data.login_day)
	_card(column,"Seven days of light","Next login gift: day %d of 7. Gifts give coins and 12 XP; the seventh adds a 75-coin bonus." % (int(profile.data.streak)%7+1),"Gift already collected" if claimed else "Collect today's gift",func():
		var paid=profile.claim_login(_today())
		if not paid.is_empty(): _sync_progress();_save();_show_daily();_toast("Gift: +%d coins / 12 XP"%paid.coins),"LoginGift",claimed)
	var daily_index=_today()%missions.missions.size()
	_card(column,"Today's watch: "+str(missions.missions[daily_index].name),"Complete this curated watch for a once-per-day 45-coin bonus. Replays keep their ordinary rescue rewards.","Start daily watch",func():_start_watch(daily_index,"daily"),"DailyWatch")
	for key in Profile.QUESTS:
		var quest=key;var ready=int(profile.data.daily[key])>=int(Profile.QUESTS[key]) and key not in profile.data.daily_claimed
		_card(column,str(key).capitalize()+"  %d / %d" % [profile.data.daily[key],Profile.QUESTS[key]],"Quest reward: 40 coins / 20 XP. Claim once each UTC day.","Collect quest" if ready else "Already claimed" if key in profile.data.daily_claimed else "Keep the light",func():
			var paid=profile.claim_quest(quest)
			if not paid.is_empty(): _sync_progress();_save();_show_daily(),"Quest_"+key,not ready)

func _show_log() -> void:
	screen="log"
	var column=_page("The boat log","%d boats home Â· endless best %d Â· %d / %d local achievements"%[profile.data.rescued,profile.data.best_endless,profile.data.unlocked.size(),catalog.achievements.size()])
	for key in Watch.KINDS:
		var stats=Watch.KINDS[key]
		_card(column,str(stats.label),"Normal %.0f Â· full light %.0f speed\n%.0f points Â· ring budget %.2f Â· focus %.2fs"%[stats.speed,stats.lit_speed,stats.value,stats.life,stats.focus] if key in profile.data.seen else "A silhouette on the horizon. Follow the coasts to meet this vessel.")
	for achievement in catalog.achievements:
		_card(column,("âœ“  " if achievement.key in profile.data.unlocked else "â€¢  ")+str(achievement.title),str(achievement.description))

func _show_settings() -> void:
	screen="settings"
	var status="Local progress is available."
	if is_instance_valid(services) and services.has_method("status"): status=str(services.status())
	var column=_page("Keeper's desk",status)
	for key in ["sound","music","reduced_motion"]:
		var setting=key
		column.add_child(_button(str(key).replace("_"," ").capitalize()+": "+("On" if profile.data.settings[key] else "Off"),func():
			profile.data.settings[setting]=not bool(profile.data.settings[setting]);_save()
			if is_instance_valid(music):
				_sync_audio_state()
			_show_settings(),"Setting_"+key))
	column.add_child(_button("Play Games sign-in",func():
		if is_instance_valid(services): services.sign_in(),"PlaySignIn"))
	column.add_child(_button("Achievements",func():
		if is_instance_valid(services): services.open_achievements(),"PlayAchievements"))
	column.add_child(_button("Leaderboards",func():
		if is_instance_valid(services): services.open_leaderboards("best_endless"),"PlayLeaderboards"))
	column.add_child(_button("Advertising privacy options",func():
		if is_instance_valid(services): services.privacy_options(),"PrivacyOptions"))
	_card(column,"Local and optional","Progress is saved on this device. Android test ads and Play Games are optional. Backend IDs are owner configuration. Web never simulates rewarded assistance. Audio can be disabled. Original project work: Apache-2.0. Kenney boats/SFX: CC0; plugin and engine notices are retained.")

func _back() -> void:
	if reward_pending or _ads_active(): return
	match screen:
		"watch": _pause()
		"pause": _resume()
		"home": pass
		"results": _leave_results(_show_home)
		_: _show_home()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_back();get_viewport().set_input_as_handled();return
	if screen!="watch" or gameplay_suspended(): return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_SPACE:
		_horn();get_viewport().set_input_as_handled();return
	var point=Vector2.ZERO;var aiming=false
	if event is InputEventScreenTouch and event.pressed:
		point=get_global_transform_with_canvas().affine_inverse()*event.position;aiming=true
	elif event is InputEventScreenDrag:
		point=get_global_transform_with_canvas().affine_inverse()*event.position;aiming=true
	elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		point=get_global_transform_with_canvas().affine_inverse()*event.position;aiming=true
	elif event is InputEventMouseMotion and event.button_mask&MOUSE_BUTTON_MASK_LEFT:
		point=get_global_transform_with_canvas().affine_inverse()*event.position;aiming=true
	if aiming and Rect2(20,155,500,600).has_point(point): watch.aim(point);get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_PAUSED:
		application_suspended=true
		if screen=="watch": _pause()
		if is_node_ready(): _save()
	elif what==NOTIFICATION_APPLICATION_RESUMED:
		application_suspended=false
	elif what==NOTIFICATION_WM_GO_BACK_REQUEST:
		_back()

func _draw() -> void:
	draw_rect(Rect2(0,0,540,960),Color("0a2334"))
	if environment.has("harbor"):
		draw_texture_rect(environment.harbor,Rect2(0,0,540,960),false)
		if screen not in ["watch","pause"]: draw_rect(Rect2(0,0,540,960),Color(0.02,0.08,0.12,.56))
	for index in range(28):
		var y=150.0+float(index)*26.0
		var offset=sin(clock*.3+float(index))*9.0 if not profile.data.settings.reduced_motion else 0.0
		draw_line(Vector2(0,y),Vector2(540,y+offset),Color(.16,.42,.48,.18),1)
	if screen in ["watch","pause"]:
		_draw_water()
		draw_rect(Rect2(0,0,540,148),Color(.025,.08,.12,.86))
		draw_rect(Rect2(16,886,508,44),Color(.025,.08,.12,.82))
	else:
		draw_circle(Vector2(490,55),26,Color(.96,.78,.42,.10))
		draw_line(Vector2(470,70),Vector2(500,30),GOLD,3)
		draw_circle(Vector2(490,54),6,GOLD)

func _toast_style() -> StyleBoxFlat:
	var box=StyleBoxFlat.new();box.bg_color=Color("284b59");box.set_corner_radius_all(12);return box

func _boat_ring_color(boat: Dictionary) -> Color:
	if watch.ring_phase(boat)=="guided_lit": return TEAL
	return CORAL if float(boat.life)/float(boat.max_life)<0.35 else GOLD

func _draw_water() -> void:
	draw_style_box(_water_style(),Rect2(16,153,508,626))
	var fog=float(watch.config.get("fog",0.0))
	if fog>0.0:
		for band in range(5):
			var offset=sin(clock*.18+float(band))*25.0 if not profile.data.settings.reduced_motion else 0.0
			draw_ellipse(Vector2(270+offset,225+band*95),Vector2(230,26),Color(.75,.83,.85,fog*.09))
	if float(watch.config.get("storm",0.0))>0.0 and fmod(watch.time,15.0)>10.0:
		for rain in range(20):
			var at=Vector2(35+float((rain*97)%470),180+fmod(clock*110+rain*79,530))
			draw_line(at,at+Vector2(-7,19),Color(.58,.8,.85,.28),1)
	for reef in watch.config.get("reefs",[]):
		var point=Vector2(float(reef[0]),float(reef[1]));var radius=float(reef[2])
		draw_circle(point,radius,Color(.30,.64,.57,.18))
		draw_arc(point,radius,0,TAU,30,Color(.58,.80,.63,.55),1.4)
		if environment.has("shoal"): draw_texture_rect(environment.shoal,Rect2(point-Vector2(radius*1.5,radius),Vector2(radius*3.0,radius*2.0)),false)
	var polygon=PackedVector2Array([Watch.BEACON])
	for index in range(31):
		var angle=watch.angle-watch.beam_half_width()+watch.beam_half_width()*2.0*float(index)/30.0
		polygon.append(_beam_end(angle))
	draw_colored_polygon(polygon,Color(.97,.82,.45,.16))
	for side in [-1.0,1.0]: draw_line(Watch.BEACON,_beam_end(watch.angle+watch.beam_half_width()*side),Color(.98,.84,.53,.4),1.5)
	for boat in watch.boats:
		var point: Vector2=boat.pos
		var color=_boat_ring_color(boat)
		draw_circle(point,37,Color(color,.10))
		draw_arc(point,35,-PI/2.0,-PI/2.0+TAU*clampf(float(boat.life)/float(boat.max_life),.001,1),32,color,3)
		if float(boat.guidance)>0: draw_arc(point,29,-PI/2.0,-PI/2.0+TAU*float(boat.guidance),32,CREAM,4)
		if boat.guided: draw_line(point,Watch.BEACON,Color(.45,.8,.77,.18),1)
		draw_set_transform(point,float(boat.rotation))
		if textures.has(boat.kind): draw_texture_rect(textures[boat.kind],Rect2(-18,-28,36,56),false)
		draw_set_transform(Vector2.ZERO)
		if boat.kind=="rescue" and not boat.guided:
			draw_string(font,point+Vector2(-5,-43),"!",HORIZONTAL_ALIGNMENT_LEFT,-1,23,CORAL)
	if watch.horn_effect>0:
		draw_arc(Watch.BEACON,60.0+(3.3-watch.horn_effect)*55.0,PI,TAU,60,Color(.5,.9,.84,.7),3)
	if environment.has("lighthouse"):
		draw_texture_rect(environment.lighthouse,Rect2(Watch.BEACON-Vector2(66,25.08),Vector2(132,132)),false)

func _water_style() -> StyleBoxFlat:
	var style=StyleBoxFlat.new();style.bg_color=Color(.07,.25,.34,.32 if environment.has("harbor") else .8);style.set_corner_radius_all(25);return style

func _beam_end(angle: float) -> Vector2:
	var direction=Vector2.from_angle(angle)
	var distance=650.0
	if direction.x<-.001: distance=minf(distance,(18.0-Watch.BEACON.x)/direction.x)
	elif direction.x>.001: distance=minf(distance,(522.0-Watch.BEACON.x)/direction.x)
	if direction.y<-.001: distance=minf(distance,(155.0-Watch.BEACON.y)/direction.y)
	return Watch.BEACON+direction*distance

func draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points=PackedVector2Array()
	for index in range(48): points.append(center+Vector2(cos(TAU*index/48.0)*radius.x,sin(TAU*index/48.0)*radius.y))
	draw_colored_polygon(points,color)
