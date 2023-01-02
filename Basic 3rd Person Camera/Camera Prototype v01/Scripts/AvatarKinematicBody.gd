extends KinematicBody

# How fast the player moves in meters per second. Most people walk about 1.4 meters per second.
export var speed = 1.5
# The downward acceleration when in the air, in meters per second squared.
export var fall_acceleration = 9.8
# How fast the camera rotates in any direction in degrees per second.
# Switch to radians later, solid advice from online.
export var look_speed = 270

var velocity = Vector3.ZERO
var rotate_final = Vector3.ZERO

func _physics_process(delta):
	# We create a local variable to store the input direction.
	var direction = Vector3.ZERO
	var avatar_rotation = Vector3.ZERO
	
	# We check for each move input and update the direction accordingly.
	direction.x += Input.get_action_strength("move_right")
	direction.x -= Input.get_action_strength("move_left")
	# Notice how we are working with the vector's x and z axes.
	# In 3D, the XZ plane is the ground plane.
	direction.z += Input.get_action_strength("move_back")
	direction.z -= Input.get_action_strength("move_forward")
	
	# We check for each look input and update the direction accordingly.
	avatar_rotation.y -= Input.get_action_strength("look_right")
	avatar_rotation.y += Input.get_action_strength("look_left")
	# Notice how we are using the Y value for looking left and right and the X value for up and down.
	avatar_rotation.x -= Input.get_action_strength("look_down")
	avatar_rotation.x += Input.get_action_strength("look_up")
	
	#This normalizes the vector length if it's not zero. This wont play nice with an analogue stick but it's fine for now since it's in the tutorial.
	#if direction != Vector3.ZERO:
		#direction = direction.normalized()
	
	# Ground velocity
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	# Vertical velocity
	velocity.y -= fall_acceleration * delta
	# Moving the character using the built in method that includeds colision and deflection.
	velocity = move_and_slide(velocity, Vector3.UP)
	
	# Rotation amount
	rotate_final.y = deg2rad(avatar_rotation.y * look_speed) * delta
	rotate_final.x = deg2rad(avatar_rotation.x * look_speed) * delta
	# Rotating the avatar root (yaw) and the camera pivot (pitch)
	rotate_y(rotate_final.y)
	$CameraPivotPoint.rotate_x(rotate_final.x)
