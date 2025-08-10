extends AnimatedSprite2D

func _ready() -> void:
	idle()

func idle() -> void:
	animation = "idle"

func walk_up() -> void:
	flip_h = false
	animation = "walk_up"

func walk_right() -> void:
	flip_h = false
	animation = "walk_horizontal"

func walk_left() -> void:
	flip_h = true
	animation = "walk_horizontal"

func walk_down() -> void:
	flip_h = false
	animation = "walk_down"
