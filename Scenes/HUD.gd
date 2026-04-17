extends CanvasLayer


@export var fps: Label

func _process(delta: float) -> void:
	fps.text = str(Engine.get_frames_per_second())
