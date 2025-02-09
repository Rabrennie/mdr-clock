extends Node2D

const NumberScene = preload("res://Scenes/number.tscn") 

const rows = 50
const columns = 50
var current_time = null

var last_x = 0
var last_y = 0

var gap_x = 70
var gap_y = 70

var minutes_in_day = 1440.0
var max_bin_minutes = minutes_in_day / 5

func _ready() -> void:
    current_time = Time.get_datetime_dict_from_system()
    set_complete_label()
    distribute_minutes_to_bins()
    
    for x in range(columns):
        for y in range(rows):
            spawn_number(x, y)
    # Only spawn a new time if the second is less than 50
    # This is to prevent weirdness with the camera moving when the time is changing
    if current_time.second < 50:
        new_time()

func _process(_delta: float) -> void:
    var actual_time = Time.get_datetime_dict_from_system()
    
    if current_time.hour != actual_time.hour || current_time.minute != actual_time.minute:
        current_time = actual_time            
        box_time()
        
    #if Input.is_action_just_released("find_time"):
    #   box_time()

func spawn_number(x: int, y: int):
    var text_instance = NumberScene.instantiate()
    text_instance.position = Vector2(x * gap_x, y * gap_y)
    text_instance.name = "number_%s_%s" % [x,y]
    text_instance.x = x
    text_instance.y = y
    
    add_child(text_instance)
    
func get_time():
    return {
        'tens': current_time.hour / 10,
        'ones': current_time.hour % 10,
        'tens_minute': current_time.minute / 10,
        'ones_minute': current_time.minute % 10
    }
         
func scroll_to_time():
    var time_nodes = get_tree().get_nodes_in_group("time")
    var tween = create_tween()
    
    var new_position = Vector2(
        -time_nodes[0].position.x + randi_range(100, 800),
        -time_nodes[0].position.y + randi_range(250, 400)
    )
    
    var distance = new_position.distance_to(position)
    var time = distance / 500
    
    tween.tween_property(self, "position", new_position, time) \
            .set_ease(Tween.EASE_IN_OUT) \
            .set_trans(Tween.TRANS_QUAD)
            
func bin_the_node(node: Node, target_position: Vector2):
    node.remove_from_group("time")
    node.remove_from_group("big")
    node.z_index = 101
    node.z_as_relative = false
    var original_position = node.global_position
    var distance_to_target = original_position.distance_to(target_position)
    var delay = distance_to_target / 1200
    await get_tree().create_timer(delay).timeout
    var tween = create_tween()    
    tween.tween_method(
        func(t: float):
            var x_progress = min(t * (1.0/0.85), 1.0)
            var y_progress = min(t * 1.0, 1.0)
            var eased_x = ease(x_progress, 2)
            var eased_y = ease(y_progress, 2)
            node.global_position = Vector2(
                lerp(original_position.x, target_position.x, eased_x),
                lerp(original_position.y, target_position.y, eased_y)
            ),
        0.0, 1.0, 1.0
    )
    await tween.finished
    node.shake = false
    node.text_scale = 0.01
    node.position = node.original_position
    node.text = str(randi_range(0, 9))
    node.z_index = 0
    tween.kill()
    tween = create_tween()
    tween.tween_property(node, "text_scale", 0.5, 0.3)
    
func box_time():
    var time_nodes = get_tree().get_nodes_in_group("big")
    var target_position = Vector2.ZERO
    var target_node = get_random_bin()
    if target_node:
        target_position = target_node.global_position + Vector2(target_node.size.x / 2, target_node.size.y / 2)
        target_node.open_doors()
    for node in time_nodes:
        bin_the_node(node, target_position)
    await get_tree().create_timer(1.5).timeout
    target_node.minutes += 1
    if current_time.hour == 0 && current_time.minute == 0:
        reset_bins()
    set_complete_label()
    if target_node:
        target_node.close_doors()
    new_time()

func get_random_bin():
    var bin_nodes = get_tree().get_nodes_in_group("bin")
    if bin_nodes.size() > 0:
        var available_bins = bin_nodes.filter(func(bin): return bin.minutes < max_bin_minutes)
        if available_bins.size() > 0:
            return available_bins[randi() % available_bins.size()]
    
func reset_bins():
    var bin_nodes = get_tree().get_nodes_in_group("bin")
    for bin in bin_nodes:
        bin.minutes = 0

func set_number_to_time(node: Node, text: String):
    node.add_to_group("time")
    node.add_to_group("big")
    node.text = text
    node.text_scale = 1
    node.shake = true
    
func get_number_node(x: int, y: int):
    return get_node("number_%s_%s" % [x, y])
        
func new_time():
    var pos_x = randi_range(10, columns - 15)
    while abs(pos_x - last_x) <= 10:
        pos_x = randi_range(10, columns - 15)

    var pos_y = randi_range(10, rows - 10)
    while abs(pos_y - last_y) <= 10:
        pos_y = randi_range(10, rows - 10)
    
    last_x = pos_x
    last_y = pos_y
    var time = get_time()
    
    for x in range(-4, 2):
        for y in range(-1, 2):
            if randf() < 0.5:
                continue
            
            var node = get_number_node(pos_x + x, pos_y + y)
            if !node:
                continue
                
            node.text_scale = randf_range(0.7, 0.8)
            node.add_to_group("big")
    
    var tens = get_number_node(pos_x - 3, pos_y)
    set_number_to_time(tens, str(time['tens']))
    var ones = get_number_node(pos_x - 2, pos_y)
    set_number_to_time(ones, str(time['ones']))
    var tens_minute = get_number_node(pos_x - 1, pos_y)
    set_number_to_time(tens_minute, str(time['tens_minute']))
    var ones_minute = get_number_node(pos_x, pos_y)
    set_number_to_time(ones_minute, str(time['ones_minute']))
    
    await get_tree().create_timer(.5).timeout
    
    scroll_to_time()
    
func get_total_minutes():
    return current_time.hour * 60 + current_time.minute
    
func get_day_percentage() -> int:
    return int(get_total_minutes() / minutes_in_day * 100)

func set_complete_label():
    var node: Label = get_node("../TopUI/MarginContainer/Control/LabelsContainer/CompletionLabel")
    node.text = str(get_day_percentage()) + "% Complete"

func distribute_minutes_to_bins():
    var minutes_left = get_total_minutes()
    var bin_nodes = get_tree().get_nodes_in_group("bin")
    
    for bin in bin_nodes:
        bin.minutes = 0
    
    while minutes_left > 0:
        var available_bins = []
        for bin in bin_nodes:
            if bin.minutes < max_bin_minutes:
                available_bins.append(bin)
        
        if available_bins.is_empty():
            break
            
        var bin = available_bins[randi() % available_bins.size()]
        var space_in_bin = max_bin_minutes - bin.minutes
        var minutes_to_add = randi_range(1, min(5, minutes_left, space_in_bin))
        
        bin.minutes += minutes_to_add
        minutes_left -= minutes_to_add
