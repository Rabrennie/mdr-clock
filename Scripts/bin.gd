extends Node

@export var label = "01"

var left_door: Panel
var right_door: Panel
var inside: ReferenceRect

@export var minutes: int = 0:
    get:
        return minutes
    set(value):
        minutes = value
        var percentage = int((minutes / 288.0) * 100)
        $LabelsContainer/ProgressContainer/ProgressBar.value = percentage
        $LabelsContainer/ProgressContainer/ProgressLabel.text = str(percentage) + "%"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    $LabelsContainer/BinNumberLabel.text = label
    left_door = $DoorContainer/Control/ColorRect
    right_door = $DoorContainer/Control2/ColorRect
    inside = $InsideContainer/Control/ReferenceRect
    
    left_door.pivot_offset = Vector2(0, 1)
    

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass

func open_doors():
    right_door.pivot_offset = Vector2(right_door.size.x, 1)
    var tween = create_tween()
    var ease_type = Tween.EASE_OUT
    var trans_type = Tween.TRANS_CUBIC
    
    tween.parallel().tween_property(left_door, "rotation_degrees", -135, 0.5).set_ease(ease_type).set_trans(trans_type)
    tween.parallel().tween_property(right_door, "rotation_degrees", 135, 0.5).set_ease(ease_type).set_trans(trans_type)
    tween.parallel().tween_property($DoorContainer, "offset_bottom", inside.size.y + 1, 0.5).set_ease(ease_type).set_trans(trans_type)
    tween.parallel().tween_property(inside, "position:y", -inside.size.y, 0.5).set_ease(ease_type).set_trans(trans_type)
func close_doors():
    var tween = create_tween()
    tween.parallel().tween_property(left_door, "rotation_degrees", 0, 0.5)
    tween.parallel().tween_property(right_door, "rotation_degrees", 0, 0.5)
    tween.parallel().tween_property($DoorContainer, "offset_bottom", 2, 0.5)
    tween.parallel().tween_property(inside, "position:y", 0, 0.5)
    
