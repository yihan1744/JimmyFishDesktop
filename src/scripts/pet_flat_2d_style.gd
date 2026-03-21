extends Node3D
## Optional: true 2D-style look — albedo only, ignores scene lights (no shading, no light shadows).
## Disable if you use only "studio" ambient in WorldEnvironment and want slight PBR depth.
@export var unshaded_albedo_only: bool = false

enum InteractionRotateAxis { YAW_Y, ROLL_Z, PITCH_X }

## YAW_Y: obvious left/right from the current camera. ROLL_Z: spin in the screen plane (often subtle on a 3/4 view).
@export var interaction_rotate_axis: InteractionRotateAxis = InteractionRotateAxis.YAW_Y

## Maximum spin speed (deg/s) on interaction_rotate_axis while **A** or **D** is held.
@export_range(0.0, 21600.0, 30.0, "suffix:°/s") var z_rotate_keyboard_speed_deg: float = 2160.0
## Ramp rate: how fast spin velocity approaches target or zero (deg/s²).
@export_range(0.0, 86400.0, 60.0, "suffix:°/s²") var interaction_spin_accel_deg_s2: float = 8640.0

var _spin_velocity_rad: float = 0.0


func _ready() -> void:
	if unshaded_albedo_only:
		_apply_unshaded_recursive(self)


func _process(delta: float) -> void:
	if z_rotate_keyboard_speed_deg <= 0.0:
		_spin_velocity_rad = 0.0
		return
	var max_spin := deg_to_rad(z_rotate_keyboard_speed_deg)
	var target_spin := 0.0
	var left := Input.is_key_pressed(KEY_A)
	var right := Input.is_key_pressed(KEY_D)
	if left and not right:
		target_spin = -max_spin
	elif right and not left:
		target_spin = max_spin
	if interaction_spin_accel_deg_s2 <= 0.0:
		_spin_velocity_rad = target_spin
	else:
		var ramp := deg_to_rad(interaction_spin_accel_deg_s2) * delta
		_spin_velocity_rad = move_toward(_spin_velocity_rad, target_spin, ramp)
	_spin_velocity_rad = clampf(_spin_velocity_rad, -max_spin, max_spin)
	if not is_zero_approx(_spin_velocity_rad):
		_apply_interaction_rotation(_spin_velocity_rad * delta)


func _apply_interaction_rotation(delta_rad: float) -> void:
	match interaction_rotate_axis:
		InteractionRotateAxis.YAW_Y:
			rotation.y += delta_rad
		InteractionRotateAxis.ROLL_Z:
			rotation.z += delta_rad
		InteractionRotateAxis.PITCH_X:
			rotation.x += delta_rad


func _apply_unshaded_recursive(n: Node) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		var mesh := mi.mesh
		if mesh:
			for i in range(mesh.get_surface_count()):
				var mat := mi.get_active_material(i)
				if mat is BaseMaterial3D:
					var dup := (mat as BaseMaterial3D).duplicate() as BaseMaterial3D
					dup.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
					mi.set_surface_override_material(i, dup)
	for child in n.get_children():
		_apply_unshaded_recursive(child)
