extends TileMap

var searchDist = 3
var playerLoc = Vector2()
var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	clear()
	rng.randomize()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	playerLoc = world_to_map(get_node("../Player Icon").position)
	for cellX in range(playerLoc.x-searchDist,playerLoc.x+searchDist):
		for cellY in range(playerLoc.y-searchDist,playerLoc.y+searchDist):
			get_cell(cellX,cellY)
			if get_cell(cellX,cellY) == -1:
				set_cell(cellX,cellY,rng.randi_range(0, 12))
