extends Node2D

var font = preload("res://NotoSans-Regular.ttf")
var font_color = Color.from_string('#777', Color.DODGER_BLUE)

var tween: Tween

var x: int
var y: int

var base_text_size = 50

@export var text: String = str(randi_range(0, 9)):
    set(value):
        text = value
        queue_redraw()
    get:
        return text
 
var text_scale: float = 0.5:
    set(value):
        text_scale = value
        queue_redraw()
    get:
        return text_scale       

var shake = false
var original_position: Vector2
var noise

func _ready():
    original_position = position
    noise = FastNoiseLite.new()
    noise.seed = 100
    noise.fractal_octaves = 4
    noise.frequency = 0.015
    
func _draw() -> void:
    draw_char(
        font,
        Vector2(0,0),
        text,
        base_text_size * text_scale,
        font_color.lightened(text_scale - 0.5)
    )

func _process(delta: float) -> void:
    var t = 0
    if shake:
        t = Time.get_ticks_msec() / 5
    else:
        t = Time.get_ticks_msec() / (100 - ((text_scale - 0.5) * 200))
    var noise_x = float(x * 10)
    var noise_y = float(y * 10)
    var a = noise.get_noise_3d(noise_x, noise_y, t)
    var b = noise.get_noise_3d(noise_x, noise_y, t + 1000)
    position = original_position + Vector2(a, b) * 5
