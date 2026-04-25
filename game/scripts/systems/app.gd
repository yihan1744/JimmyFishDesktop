extends Node
## Main app system. Window setup, pet container, and desktop integration.

@export var window_width: int = 400
@export var window_height: int = 400
@export var always_on_top: bool = true
## When off, per-pixel transparency and clear alpha are disabled so the window bounds are easy to see (for testing).
@export var transparent_background: bool = true
@export var min_window_size: int = 64

@onready var app_container: Node = $App

var _drag_delta: Vector2i = Vector2i.ZERO

func _ready() -> void:
	_setup_window()
	_start_pet_animation()
	call_deferred("_ensure_main_camera_current")

func _is_running_in_embedded_game_view() -> bool:
	# When false: separate OS window (e.g. `tools/run_desktop_pet.sh` or "Embed" off in Game tab).
	if Engine.is_embedded_in_editor():
		return true
	if OS.has_feature("embedded_in_editor"):
		return true
	return false

func _ensure_main_camera_current() -> void:
	var cam := app_container.get_node_or_null("Camera3D") as Camera3D
	if cam != null:
		cam.make_current()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if not _is_running_in_embedded_game_view():
					_drag_delta = DisplayServer.mouse_get_position() - DisplayServer.window_get_position()
			else:
				_drag_delta = Vector2i.ZERO
	elif event is InputEventMouseMotion and _drag_delta != Vector2i.ZERO and not _is_running_in_embedded_game_view():
		DisplayServer.window_set_position(DisplayServer.mouse_get_position() - _drag_delta)

func _should_use_per_pixel_transparency() -> bool:
	if not (ProjectSettings.get_setting("display/window/per_pixel_transparency/allowed", false) as bool):
		return false
	# macOS / Windows: always enable when the project allows it. On Windows,
	# is_window_transparency_available() is often false with Vulkan (e.g. hybrid /
	# NVIDIA swapchain alpha), which made us skip WINDOW_FLAG_TRANSPARENT entirely
	# and left an opaque gray window instead of the desktop showing through.
	if OS.get_name() == "macOS" or OS.get_name() == "Windows":
		return true
	# Linux: compositing may be off; respect runtime availability when exposed.
	if DisplayServer.has_method("is_window_transparency_available"):
		return DisplayServer.is_window_transparency_available()
	return true

func _apply_environment_for_transparent_toggle(use_transparent: bool) -> void:
	var we := app_container.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if we == null or we.environment == null:
		return
	var env: Environment = we.environment
	env.background_mode = Environment.BG_CLEAR_COLOR
	if use_transparent:
		env.background_color = Color(0, 0, 0, 0)
	else:
		# Opaque: visible window bounds for testing
		env.background_color = Color(0.12, 0.12, 0.16, 1.0)

func _setup_window() -> void:
	var wid: int = get_window().get_window_id()
	var win := get_window()
	var use_transparent: bool = transparent_background and _should_use_per_pixel_transparency()
	if use_transparent:
		get_tree().root.transparent_bg = true
		get_viewport().transparent_bg = true
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true, wid)
		win.transparent = true
	else:
		get_tree().root.transparent_bg = false
		get_viewport().transparent_bg = false
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, false, wid)
		win.transparent = false
	_apply_environment_for_transparent_toggle(use_transparent)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true, wid)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, always_on_top, wid)
	# Godot "embedded" / floating game view: OS window position & resize are not applied; use a normal run window to test.
	if not _is_running_in_embedded_game_view():
		DisplayServer.window_set_size(
			Vector2i(maxi(min_window_size, window_width), maxi(min_window_size, window_height))
		)

func _start_pet_animation() -> void:
	var pet := _find_jimmy_fish()
	if pet == null:
		return
	var anim_player := _find_animation_player(pet)
	if anim_player == null:
		return
	var anim_name := _get_first_animation(anim_player)
	if anim_name.is_empty():
		return
	var anim := anim_player.get_animation(anim_name)
	if anim:
		anim.loop_mode = Animation.LOOP_LINEAR
	anim_player.play(anim_name)

func _find_jimmy_fish() -> Node:
	var container := app_container.get_node_or_null("PetContainer")
	if container == null or container.get_child_count() == 0:
		return null
	return container.get_child(0)

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found:
			return found
	return null

func _get_first_animation(anim_player: AnimationPlayer) -> String:
	var anims := anim_player.get_animation_list()
	if anims.size() > 0:
		return anims[0]
	return ""
