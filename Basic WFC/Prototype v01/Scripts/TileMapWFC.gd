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
			if get_cell(cellX,cellY) == -1:
				set_cell(cellX,cellY,rng.randi_range(0, 12))

func WFC():
	Get the range of tiles I care about
		(create a 4d array where the first two
		indexes represent the tile location, and the other two indexes represent
		the tile ids and all 4 rotations of that id. Each cell fo the array will
		have a true/false value representing whether the tile configuration is
		possible or not)
		(Generating this array will have to be its own function that will be called regualrly)
	Itterate through the array and count the number of cells that: are already 
		set, have zero solutions, have 1 solution, or have 2 or more solutions
	If a tile has zero solutions throw an error, we messed up
	for every tile represented by the array that has only 1 valid configuration 
		that is not yet set, set them and return to itterating through the array
	else if all tiles have 2 or more solutions, 

func generate_wfc_array(Vector2 centerCell, int arrayRadius): #tilemap coordinates
	#This method should really be part of a custom 4D array class, do that later
	#Same with update_cell_status
	var currentCell = centerCell
	var wfcArray = []
	wfcArray.resize((arrayRadius*2)+1)
	for cellX in range(centerCell.x-arrayRadius,centerCell.x+arrayRadius):
		wfcArray[cellX] = []
		wfcArray[cellX].resize((arrayRadius*2)+1)
		for cellY in range(centerCell.y-arrayRadius,centerCell.y+arrayRadius):
			currentCell = Vector2(cellX, cellY) #Array coordinates
			Use offset to convert from array to tilemap coordinates
			wfcArray[cellX][cellY]update_cell_status(centerCell)

func update_cell_status(Vector2 cell): #tilemap coordinates
	use the get_cell() function to deturmine the cell id and rotation of all adjacent cells using the 
		flip_x, flip_y, and transpose values
	use that information to eliminate valid configurations for the main cell
	return a 2D array that contains the valid and invalid configurations
