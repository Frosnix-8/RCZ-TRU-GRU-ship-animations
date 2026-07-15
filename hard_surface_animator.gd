extends AnimationPlayer
##Animation player designed to tween multiple bones for repetitive movements.
class_name HardSurfaceAnimationPlayer
var deployed :bool = false
var busy := false
@export var skeleton : Skeleton3D
#func _process(delta: float) -> void:
	#deployed = get_playing_speed() > 0
func _ready() -> void:
	if !skeleton:
		push_error(self, " has no skeleton!")


var procedural_bone_tweens : Dictionary[String, Tween]
##Twists specified bones on the corresponding axis by a certain amount using a tween or snap.
func twist_bones(bones, rotation_axis: Vector3, rotation_amount : float, snap :bool = false, time := 0.4, _ease : Tween.EaseType = Tween.EASE_IN_OUT, trans : Tween.TransitionType = Tween.TRANS_CUBIC) -> void:
	var tween_id : String
	var skelly : Array[int]
	if rotation_axis == Vector3.ZERO:
		push_error("cannot rotate on a null axis")
		return
	
	if bones is Array[String] or bones is Array[StringName]:
		for x in bones:
			var id :int= skeleton.find_bone(x as String)
			skelly.append(id)
			tween_id = tween_id + str(id)
			
	elif bones is String or bones is StringName:
		var id : int = skeleton.find_bone(bones as String)
		skelly.append(id)
		tween_id = str(id)
	else:
		push_error("Did not recognize bones array or string, is it the right type?")
	
	if snap:
		for y in skelly.size():
			skeleton.set_bone_pose_rotation(skelly[y], Quaternion(rotation_axis, rotation_amount))
			return
	prints("tween id is", tween_id)
	
	var current_tween : Tween 
	if procedural_bone_tweens.has(tween_id):
		current_tween = procedural_bone_tweens[tween_id]
		current_tween.kill()
	current_tween = create_tween()
	procedural_bone_tweens[tween_id] = current_tween
		
	
	var initial_rotation : Quaternion = skeleton.get_bone_pose_rotation(skelly[0]).normalized()
	current_tween.tween_method(func(x):
		for y in skelly.size():
			skeleton.set_bone_pose_rotation(skelly[y], Quaternion(rotation_axis, x)),
		_get_signed_angle_around_axis(initial_rotation,rotation_axis),
		rotation_amount,
		time
		).set_ease(_ease).set_trans(trans)
		
##read the name
func _get_signed_angle_around_axis(q: Quaternion, axis: Vector3) -> float:
	var qv := Vector3(q.x, q.y, q.z)
	var sin_half := qv.dot(axis.normalized())
	return 2.0 * atan2(sin_half, q.w)
	
