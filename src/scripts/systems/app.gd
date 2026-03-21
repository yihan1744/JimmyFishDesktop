extends Node
## Main app system. Window setup, pet container, and desktop integration.

@export var window_width: int = 400
@export var window_height: int = 400
@export var always_on_top: bool = true

@onready var app_container: Node = $App

var _drag_delta: Vector2i = Vector2i.ZERO


func _ready() -> void:
	_setup_window()
	_start_pet_animation()
	call_deferred("_ensure_main_camera_current")


func _ensure_main_camera_current() -> void:
	var cam := app_container.get_node_or_null("Camera3D") as Camera3D
	if cam != null:
		cam.make_current()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_drag_delta = DisplayServer.mouse_get_position() - DisplayServer.window_get_position()
			else:
				_drag_delta = Vector2i.ZERO
	elif event is InputEventMouseMotion and _drag_delta != Vector2i.ZERO:
		DisplayServer.window_set_position(DisplayServer.mouse_get_position() - _drag_delta)


func _setup_window() -> void:
	var wid: int = get_window().get_window_id()
	get_tree().root.transparent_bg = true
	get_viewport().transparent_bg = true
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true, wid)
	get_window().transparent = true
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, always_on_top)
	DisplayServer.window_set_size(Vector2i(window_width, window_height))


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
