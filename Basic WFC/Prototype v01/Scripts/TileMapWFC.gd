extends TileMap

var searchDist = 3
var playerLoc = Vector2()
var rng = RandomNumberGenerator.new()
var edgeKeyAddress = 'res://assets/Tile Sets/Basic Tiles v01.00 Edge Key.txt'
var edgeKey = []

# Called when the node enters the scene tree for the first time.
func _ready():
	clear()
	rng.randomize()
	#Apparently it's easier to just load every line of the edge key text file into an array and read them that way. It's only less than 1kb so it's honestly probably faster than reading from disk every frame anyway.
	var f = File.new()
	f.open(edgeKeyAddress, File.READ)
	var index: int = 0 #In the online help I borrowed this started at index 1, not sure why, 0 seems like it makes more sense
	while not f.eof_reached():
		var line = f.get_line()
		if edgeKey.size() == index:
			edgeKey.append(line)
		else:
			edgeKey[index] = line
		#This is such a bad way to double check the length of the array, oh well
		index += 1
	f.close()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	playerLoc = world_to_map(get_node("../Player Icon").position)
	for cellX in range(playerLoc.x-searchDist,playerLoc.x+searchDist):
		for cellY in range(playerLoc.y-searchDist,playerLoc.y+searchDist):
			if get_cell(cellX,cellY) == -1:
				set_cell(cellX,cellY,rng.randi_range(0, 12))

func WFC():
	var wfcArray: Array = generate_wfc_array(world_to_map(get_node("../Player Icon").position), searchDist)
	#Itterate through the array and count the number of cells that: are already set, have zero solutions, have 1 solution, or have 2 or more solutions
	#If a tile has zero solutions throw an error, we messed up
	#For every tile represented by the array that has only 1 valid configuration that is not yet set, set them and return to itterating through the array
	#else if all tiles have 2 or more solutions,

func generate_wfc_array(var centerCell: Vector2, var arrayRadius: int): #tilemap coordinates
	#This method should really be part of a custom 4D array class, do that later
	#Same with update_cell_status
	var currentCell: Vector2 = centerCell
	var arrayOffset: Vector2 = calcOffset(currentCell, arrayRadius)
	var wfcArray: Array = []
	wfcArray.resize((arrayRadius*2)+1) #Set array's X dimension length
	for cellX in range(0, arrayRadius*2):
		#add a new Y dimension array to each X index and set the Y dimension length
		wfcArray[cellX] = []
		wfcArray[cellX].resize((arrayRadius*2)+1)
		for cellY in range(0, arrayRadius*2):
			#Use the update_cell_ctatus for each XY cell
			currentCell = Vector2(cellX, cellY) #Array coordinates
			wfcArray[cellX][cellY] = update_cell_status(currentCell, arrayOffset) #This receives a 2D array listing the true/flase posibilities of the actual array tile.
	return wfcArray

func update_cell_status(var arrayCell: Vector2, var offset: Vector2): #arguments assume array coordinates, converts to world coordinates locally and then returns the 2D array
	var worldCell: Vector2 = array_to_world(arrayCell, offset)
	var horiz: Vector2 = Vector2(1,0)
	var vert: Vector2 = Vector2(0,1)
	var cellStatus: Array = [] #This is the array object that will ultimately be returned
	cellStatus.resize(13) #Sets the length of the cell status array equal to the number of tile types I'm using
	for cellType in range(0, 12):
		cellStatus[cellType] = []
		cellStatus[cellType].resize(4) #Sets the array within each cell type to be 4 to represent the 4 rotational positions
		for cellBool in range(0, 3):
			cellStatus[cellType][cellBool] = true #Sets the value of all possible tile types and rotations as true, in preperation for options to be eliminated later
	var tileMatches: Array = []
	var neighborIndex: int = get_cellv(worldCell+vert) #North
	if neighborIndex != -1:
		tileMatches = get_tile_matches(worldCell, neighborIndex, 0) #titleMatches should be the same exact format as cellStatus, and so i can look at every cell in tile matches that is false and set that same tile in cellStatus as false too.
		eliminate_tiles(tileMatches, cellStatus)
	neighborIndex = get_cellv(worldCell-horiz) #West
	if neighborIndex != -1:
		tileMatches = get_tile_matches(worldCell, neighborIndex, 1)
		eliminate_tiles(tileMatches, cellStatus)
	neighborIndex = get_cellv(worldCell-vert) #South
	if neighborIndex != -1:
		tileMatches = get_tile_matches(worldCell, neighborIndex, 2)
		eliminate_tiles(tileMatches, cellStatus)
	neighborIndex = get_cellv(worldCell+horiz) #East
	if neighborIndex != -1:
		tileMatches = get_tile_matches(worldCell, neighborIndex, 3)
		eliminate_tiles(tileMatches, cellStatus)
	return cellStatus

func eliminate_tiles(var tileMatches: Array, var cellStatus: Array): #Suposedly arrays are passed by refference and so I don't need to return them, we'll see
	for cellType in range(0, 12):
		for cellBool in range(0, 3):
			if tileMatches[cellType][cellBool] == false:
				cellStatus[cellType][cellBool] = false
	
func get_tile_matches(var worldCell: Vector2, var worldCellIndex: int, var tileEdge: int):
	#tileEdge uses the same logic as the edge key. A 0 represents the north edge, and every increase increments the edges counter clockwise menaing 1 is west, 2 is south, and 3 is east.
	var rot: int = get_tile_rotation(worldCell) #Rot uses the same logic as the edge key.
	var newEdge: int = posmod(tileEdge+rot, 4) #The posmod modulo function wraps the resuts to be 0-3
	var edgeCode: String = edgeKey[(worldCellIndex*4)+1+newEdge]
	if edgeCode[5] == "1": #The way I coded the edge types, the 1 and 2 types mate together because their match is inverted. I have to look for the oposite kind.
		edgeCode[5] = "2"
	else:
		if edgeCode[5] == "2":
			edgeCode[5] = "1"
	var matches: Array = [] #This is the array object that will ultimately be returned
	matches.resize(13) #Sets the length of the cell status array equal to the number of tile types I'm using
	var edgeKeyLine: int = 0 #this tracks what line of edge key im on, and it will be incremented every time i write to matchesY
	for x in range(0, 12):
		matches[x] = []
		matches[x].resize(4) #Sets the array within each cell type to be 4 to represent the 4 rotational positions
		for y in range(0, 3):
			if edgeKey[edgeKeyLine].substr(5, -1) == edgeCode.substr(5, -1): #characters 5 6 and 7 contain the edge type and color code, so reading all characters from position 5 onward should work.
				matches[x][posmod(y+tileEdge, 4)] = true
			else:
				matches[x][posmod(y+tileEdge, 4)] = false
			#The posmod is there because the codes being written to the array are assuming the matching edge is facing north, but I need to rotate them acording to the tileEdge.
			#This should result in an array full of true/false values coresoponding to the codes in edgeKey
			
	for i in range(0, matches.size()-1):
		matches[i][3] = String(posmod(int(matches[i][3])+3, 4)) #Reads the character into an int, adds 3, does a modulo 4 on that int, then casts that back to a string to overwrite itself. Now the list of matches should all be valid for the worldCell tile.
	return matches #Matches should only contain an array of the 4 character tile index/rotation codes.

func get_tile_rotation(var worldCell: Vector2):
	#Calculate the number of clockwise rotations from default the tile has been rotated. This requires interpriting the flip/transpose signals from the tile. Should return an integer from 0-3
	#The valid tile configurations I care about are: zero flips or transposiitons (north), both flips and no transposition (south), transposed and one flip (east/west), Depending on whether the transpose is calculated before the flip or not will deturmine which one it is. double check this later. Anything else should result in a tile that doesn't actually exist and cant be rorated normally."
	var rot: int
	if is_cell_x_flipped(worldCell.x, worldCell.y) == true:
		if is_cell_y_flipped(worldCell.x, worldCell.y) == true:
			rot = 2
		else:
			rot = 1 or 3
	else:
		if is_cell_y_flipped(worldCell.x, worldCell.y) == true:
			rot = 3 or 1
		else:
			rot = 0
	#Consider putting a thing in here to also check for transpose before each rot assignment, just to double check there's no errors
	return rot

#Honestly these aren't nescesary, they are just here so I don't forget which way the vectors need to be added/subtracted
func calcOffset(var centerCell: Vector2, var arrayRadius: int):
	return Vector2(centerCell.x-arrayRadius, centerCell.y-arrayRadius)
func world_to_array(var worldLoc: Vector2, var offset: Vector2):
	return worldLoc-offset
func array_to_world(var arrayLoc: Vector2, var offset: Vector2):
	return arrayLoc+offset
