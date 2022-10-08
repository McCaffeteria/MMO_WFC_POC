extends TileMap

var searchDist = 3
var playerLoc = Vector2()
var rng = RandomNumberGenerator.new()
var edgeKeyAddress = 'res://assets/Tile Sets/Basic Tiles v01.00 Edge Key.txt'

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
	var edgeKey = File.new()
	edgeKey.open(edgeKeyAddress, File.READ)
	Vector2 worldCell = array_to_world(arrayCell, offset)
	Vector2 horiz = Vector2(1,0)
	Vector2 vert = Vector2(0,1)
	Array cellStatus = [] #This is the array object that will ultimately be returned
	cellStatus.resize(13) #Sets the length of the cell status array equal to the number of tile types I'm using
	for cellType in range(0, 12):
		cellStatus[cellType] = []
		cellStatus[CellType].resize(4) #Sets the array within each cell type to be 4 to represent the 4 rotational positions
		for cellBool in range(0, 3):
			cellStatus[cellType][cellBool] = true #Sets the value of all possible tile types and rotations as true, in preperation for options to be eliminated later
	int neighborIndex = get_cell(worldCell+horiz) #This should get the tile ID of the tile to the east of the target cell
	if neighborIndex != -1:
		"Find tile rotation."
		
		get_tile_info(neighborIndex, tileRot) #I don't know what format this will return yet, but it will be a list of valid tile IDs and the ENSW edges of that ID that match.
		
		"Once you have a list of valid tile edges, call" get_tile_rotation() "for each tile edge in the list.
		
		Once I have the list of valid tiles and their rotations, I have to ELIMINATE all of the OTHER options from the existing array.
		If I just itterate through the array I can check each array cell ID to see if it's on the list and if it isn't then I can autimatically set all 4 rotations to be false. If the tile ID is on the list, i can check each of the 4 rotation array cells and mark them flase if their cell ID/rotation combo isn't on the list.
		
		Once I have eliminated every cell that doesn't work for this neighbor I can move on to the next neighbor cell"
	int neighborIndex = get_cell(worldCell+Vert) #North
	int neighborIndex = get_cell(worldCell-Vert) #South
	int neighborIndex = get_cell(worldCell-horiz) #West
	return cellStatus
	
func get_tile_info(int tileID, var tileRot):
	"Check 'Basic Tiles v01.00 Edge Key.txt' to figure out what edge of the tile faces the target cell.
	Itterate through the text key looking for instances of the edge code, and whenever you find one keep track of the tile/edge combo that comes directly before it on the same line.
	Return that list of tile/edge combos."

func get_tile_rotation(int tileID, int tileEdge, int neighborDirection):
	"calculate the rotation that would be required for that tile edge to line up (for example, if tile edge 06,W were a valid choice it would need to be rotated 180 degrees, so that the western edge of tile 06 is now facing east).
	return that tile id and rotation, potentially as 2 integers that corespond to the array index that will stay true."

#Honestly these aren't nescesary, they are just here so I don't forget which way the vectors need to be added/subtracted
func calcOffset(Vector2 centerCell, Vector2 arrayRadius):
	return centerCell-arrayRadius
func world_to_array(Vector2 worldLoc, Vector2 offset):
	return worldLoc-offset
func array_to_world(Vector2 arrayLoc, Vector2 offset):
	return arrayLoc+offset
