extends Camera2D

var defaultZoom = .1
var zoomStep = .01
var maxZoom = .05
var minZoom = .5

# Called when the node enters the scene tree for the first time.
func _ready():
	zoom.x = defaultZoom
	zoom.y = defaultZoom

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_pressed("Zoom_In"):
		zoom.x -= zoomStep
		zoom.y -= zoomStep
	if Input.is_action_pressed("Zoom_Out"):
		zoom.x += zoomStep
		zoom.y += zoomStep
		
	if zoom.x > minZoom:
		zoom.x = minZoom
		zoom.y = minZoom
	if zoom.x < maxZoom:
		zoom.x = maxZoom
		zoom.y = maxZoom
