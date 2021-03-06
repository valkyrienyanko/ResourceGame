extends KinematicBody2D

onready var camera = get_node("Camera2D")

var speed = 100
var velocity = Vector2()
var zoom = 1

func _ready():
	add_to_group("Player")
	scale = Vector2(0.5, 0.5)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			pass
		if event.button_index == BUTTON_WHEEL_DOWN:
			zoom += 0.1
		if event.button_index == BUTTON_WHEEL_UP:
			zoom -= 0.1

func _physics_process(delta):
	zoom = clamp(zoom, 0.2, 1)
	camera.zoom = Vector2(lerp(camera.zoom.x, zoom, 0.02), lerp(camera.zoom.y, zoom, 0.02))
	
	velocity = Vector2()
	if Input.is_action_pressed("left"):
		velocity.x -= speed
	if Input.is_action_pressed("right"):
		velocity.x += speed
	if Input.is_action_pressed("up"):
		velocity.y -= speed
	if Input.is_action_pressed("down"):
		velocity.y += speed
	position += velocity * delta
