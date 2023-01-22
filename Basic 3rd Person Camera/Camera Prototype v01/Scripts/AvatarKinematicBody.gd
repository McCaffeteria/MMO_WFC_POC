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
	
	# Rotation amount
	rotate_final.y = deg2rad(avatar_rotation.y * look_speed) * delta
	rotate_final.x = deg2rad(avatar_rotation.x * look_speed) * delta
	# Rotating the avatar root (yaw) and the camera pivot (pitch)
	rotate_y(rotate_final.y)
	$CameraPivotPoint.rotate_x(rotate_final.x)
	
	#Simple line to rotate the direction vector by the same amount that the AvatarKinematicBody object is rotated. Without this line the direction input moves the object in world space, but we want it to move relative to the camera.
	direction = direction.rotated(Vector3(0, 1, 0), get_rotation().y)
	
	# Ground velocity
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	# Vertical velocity
	velocity.y -= fall_acceleration * delta
	# Moving the character using the built in method that includeds colision and deflection.
	velocity = move_and_slide(velocity, Vector3.UP) #The reason this is setting the velocity variable while also refferencing the velocity variable is because the method returns the modified velocity which can be usefull in case the object collides. If you expected it to move 1 unit but it only moves .5 units then the vaslue of valocity is now .5 and you can refference the correct distance if you have new calculations to do within the same frame.
