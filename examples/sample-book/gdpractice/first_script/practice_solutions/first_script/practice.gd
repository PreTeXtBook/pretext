extends Sprite2D

var speed = 400
var angular_speed = PI

func _init():
	pass
	
	
func _process(delta):
	rotation += angular_speed * delta
