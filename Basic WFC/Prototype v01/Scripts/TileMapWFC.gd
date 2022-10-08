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
	"Get the range of tiles I care about
		(create a 4d array where the first two indexes represent the tile location, and the other two indexes represent the tile ids and all 4 rotations of that id. Each cell fo the array will have a true/false value representing whether the tile configuration is possible or not)
		(Generating this array will have to be its own function that will be called regualrly)
	Itterate through the array and count the number of cells that: are already set, have zero solutions, have 1 solution, or have 2 or more solutions
	If a tile has zero solutions throw an error, we messed up
	For every tile represented by the array that has only 1 valid configuration that is not yet set, set them and return to itterating through the array
	else if all tiles have 2 or more solutions, "

func generate_wfc_array(Vector2 centerCell, int arrayRadius): #tilemap coordinates
	#This method should really be part of a custom 4D array class, do that later
	#Same with update_cell_status
	Vector2 currentCell = centerCell
	Vector2 arrayOffset = calcOffset(currentCell, arrayRadius)
	Array wfcArray = []
	wfcArray.resize((arrayRadius*2)+1) #Set array's X dimension length
	for cellX in range(0, arrayRadius*2):
		#add a new Y dimension array to each X index and set the Y dimension length
		wfcArray[cellX] = []
		wfcArray[cellX].resize((arrayRadius*2)+1)
		for cellY in range(0, arrayRadius*2):
			#Use the update_cell_ctatus for each XY cell
			currentCell = Vector2(cellX, cellY) #Array coordinates
			wfcArray[cellX][cellY] = update_cell_status(currentCell, arrayOffset)

func update_cell_status(Vector2 arrayCell, Vector2 offset): #arguments assume array coordinates, converts to world coordinates locally and then returns the 2D array
	Vector2 worldCell = array_to_world(arrayCell, offset)
	"use the get_cell() function to deturmine the cell id and rotation of all adjacent cells using the flip_x, flip_y, and transpose values
	use that information to eliminate valid configurations for the main cell
	return a 2D array that contains the valid and invalid configurations"

#Honestly these aren't nescesary, they are just here so I don't forget which way the vectors need to be added/subtracted
func calcOffset(Vector2 centerCell, Vector2 arrayRadius):
	return centerCell-arrayRadius
func world_to_array(Vector2 worldLoc, Vector2 offset):
	return worldLoc-offset
func array_to_world(Vector2 arrayLoc, Vector2 offset):
	return arrayLoc+offset
