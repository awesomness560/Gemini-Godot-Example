extends ColorRect

var time = 0

func _process(delta: float) -> void:
	time += delta
	material.set("shader_parameter/iTime", time)
