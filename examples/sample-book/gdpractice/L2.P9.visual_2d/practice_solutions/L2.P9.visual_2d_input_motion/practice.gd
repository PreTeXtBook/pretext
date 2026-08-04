extends Node2D

const SPEED := 200.0


func _physics_process(delta: float) -> void:
    if Input.is_action_pressed("move_right"):
        position.x += SPEED * delta # position.x += 0
