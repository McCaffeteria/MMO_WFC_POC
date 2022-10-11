extends TileMap

var searchDist = 3
var playerLoc = Vector2()
var rng = RandomNumberGenerator.new()
var edgeKeyAddress = 'res://assets/Tile Sets/Basic Tiles v01.00 Edge Key.txt'
var edgeKey = []
#flipTrans and trueList are used in two different methods
var flipTrans: Array
var trueList: Array

# Called when the node enters the scene tree for the first time.
func _ready():
	#clear()
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
	wfc()

func wfc():
	var playerPosition: Vector2 = world_to_map(get_node("../Player Icon").position) #This is Global TileMap coordinates.
	var wfcArray: Array
	wfcArray.resize((searchDist*2)+1)
	for x in range(0, searchDist*2):
		wfcArray[x] = []
		wfcArray[x].resize((searchDist*2)+1)
	var solutionCount: Array
	var setCount: int = 1
	#check to see if all cells within the search radius are set. If they are set then do nothing.
	var allSet: bool = true
	for x in range(playerLoc.x-searchDist,playerLoc.x+searchDist):
		for y in range(playerLoc.y-searchDist,playerLoc.y+searchDist):
			if get_cell(x,y) == -1:
				allSet = false
	if allSet == false:
		while setCount != 0:
			setCount = 0
			wfcItterate(wfcArray, playerPosition, solutionCount)
			var randomDepth: int = 2
			while randomDepth < 14:
				if setCount != 0:
					break
				for x in range(0, solutionCount.size()-1):
					if setCount != 0:
						break
					for y in range(0, solutionCount[x].size()-1):
						if setCount != 0:
							break
						if solutionCount[x][y] == randomDepth:
							flipTrans = calc_flip_trans(trueList[rng.randi_range(0, randomDepth-1)].y)
							set_cellv(array_to_world(Vector2(x, y), calc_offset(playerPosition, searchDist)), trueList[rng.randi_range(0, randomDepth-1)].x ,flipTrans[0], flipTrans[1], flipTrans[2])
							setCount += 1
				randomDepth += 1

func setTileRand(var x: int, var y: int, var playerPosition: Vector2, var flipTrans: Array):
	set_cellv(array_to_world(Vector2(x, y), calc_offset(playerPosition, searchDist)),flipTrans[0], flipTrans[1], flipTrans[2])

func wfcItterate(var wfcArray: Array, var playerPosition: Vector2, var solutionCount: Array):
	var setCount: int = 1
	var solutionCountClean: Array = [] #This is just a copy of the empty array structure that I can copy every time I need to reconstruct it. The way I made this I don't actually know what cells are empty or not, so instead of just itterating through them all and brute force cleaning them it's easier to just replace it.
	solutionCountClean.resize(wfcArray.size())
	for x in range(0, solutionCountClean.size()-1):
		solutionCountClean[x] = []
		solutionCountClean[x].resize(wfcArray[x].size())
	while setCount != 0:
		wfcArray = generate_wfc_array(playerPosition, searchDist) #Generate the array full of true/false values for every tile type and rotation of every tile within the search radius.
		setCount = 0
		solutionCount = solutionCountClean #If arrays are passed by refference, this might fuck everything up honestly. I might need to use Array duplicate(). In lots of places.
		for x in range(0, wfcArray.size()-1):
			for y in range(0, wfcArray[x].size()-1):
				if wfcArray[x][y] != null:
					trueList.resize(0)
					for t in range(0, wfcArray[x][y].size()-1):
						for r in range(0, wfcArray[x][y][t].size()-1):
							if wfcArray[x][y][t][r] == true:
								trueList.append(Vector2(t, r)) #Records the tile type and rotations that are valid so that I can go back and check which one was true later.
					if trueList.size() == 1:
						flipTrans = calc_flip_trans(trueList[0].y)
						set_cellv(array_to_world(Vector2(x, y), calc_offset(playerPosition, searchDist)), trueList[0].x ,flipTrans[0], flipTrans[1], flipTrans[2])
						setCount += 1
					else:
						#Record the number of valid options in the list so that I can pick the cell with the fewest options to set randomly
						solutionCount[x][y] = trueList.size()

func generate_wfc_array(var centerCell: Vector2, var arrayRadius: int): #tilemap coordinates
	#This method should really be part of a custom 4D array class, do that later
	#Same with update_cell_status
	var currentCell: Vector2 = centerCell
	var arrayOffset: Vector2 = calc_offset(currentCell, arrayRadius)
	var wfcArray: Array = []
	wfcArray.resize((arrayRadius*2)+1) #Set array's X dimension length
	for x in range(0, arrayRadius*2):
		#add a new Y dimension array to each X index and set the Y dimension length
		wfcArray[x] = []
		wfcArray[x].resize((arrayRadius*2)+1)
		for y in range(0, arrayRadius*2):
			#Use the update_cell_ctatus for each XY cell
			currentCell = Vector2(x, y) #Array coordinates
			wfcArray[x][y] = update_cell_status(currentCell, arrayOffset) #This receives a 2D array listing the true/flase posibilities of the actual array tile.
	return wfcArray

func update_cell_status(var arrayCell: Vector2, var offset: Vector2): #arguments assume array coordinates, converts to world coordinates locally and then returns the 2D array
	var worldCell: Vector2 = array_to_world(arrayCell, offset)
	if get_cellv(worldCell) != -1:
		return #If the tile is already set then just bail, there's no point in checking it's possible states.
	var horiz: Vector2 = Vector2(1,0)
	var vert: Vector2 = Vector2(0,1)
	var cellStatus: Array = [] #This is the array object that will ultimately be returned
	cellStatus.resize(13) #Sets the length of the cell status array equal to the number of tile types I'm using
	for t in range(0, 12):
		cellStatus[t] = []
		cellStatus[t].resize(4) #Sets the array within each cell type to be 4 to represent the 4 rotational positions
		for r in range(0, 3):
			cellStatus[t][r] = true #Sets the value of all possible tile types and rotations as true, in preperation for options to be eliminated later
	var tileMatches: Array = []
	var neighborIndex: int = get_cellv(worldCell+vert) #North
	if neighborIndex != -1:
		tileMatches = get_tile_matches(worldCell, neighborIndex, 2) #titleMatches should be the same exact format as cellStatus, and so i can look at every cell in tile matches that is false and set that same tile in cellStatus as false too.
		eliminate_tiles(tileMatches, cellStatus)
	neighborIndex = get_cellv(worldCell-horiz) #West
	if neighborIndex != -1:
		tileMatches = get_tile_matches(worldCell, neighborIndex, 3)
		eliminate_tiles(tileMatches, cellStatus)
	neighborIndex = get_cellv(worldCell-vert) #South
	if neighborIndex != -1:
		tileMatches = get_tile_matches(worldCell, neighborIndex, 0)
		eliminate_tiles(tileMatches, cellStatus)
	neighborIndex = get_cellv(worldCell+horiz) #East
	if neighborIndex != -1:
		tileMatches = get_tile_matches(worldCell, neighborIndex, 1)
		eliminate_tiles(tileMatches, cellStatus)
	return cellStatus

func eliminate_tiles(var tileMatches: Array, var cellStatus: Array): #Suposedly arrays are passed by refference and so I don't need to return them, we'll see
	for t in range(0, 12):
		for r in range(0, 3):
			if tileMatches[t][r] == false:
				cellStatus[t][r] = false
	
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
	for t in range(0, 12):
		matches[t] = []
		matches[t].resize(4) #Sets the array within each cell type to be 4 to represent the 4 rotational positions
		for r in range(0, 3):
			if edgeKey[edgeKeyLine].substr(5, -1) == edgeCode.substr(5, -1): #characters 5 6 and 7 contain the edge type and color code, so reading all characters from position 5 onward should work.
				matches[t][posmod(r+tileEdge, 4)] = true
			else:
				matches[t][posmod(r+tileEdge, 4)] = false
			#The posmod is there because the codes being written to the array are assuming the matching edge is facing north, but I need to rotate them acording to the tileEdge.
			#This should result in an array full of true/false values coresoponding to the codes in edgeKey
	return matches #Matches should only contain an array of the 4 character tile index/rotation codes.

func get_tile_rotation(var worldCell: Vector2):
	#Calculate the number of clockwise rotations from default the tile has been rotated. This requires interpriting the flip/transpose signals from the tile. Should return an integer from 0-3
	#The valid tile configurations I care about are: zero flips or transposiitons (north), both flips and no transposition (south), transposed and one flip (east/west), Depending on whether the transpose is calculated before the flip or not will deturmine which one it is. double check this later. Anything else should result in a tile that doesn't actually exist and cant be rorated normally."
	var rot: int
	if is_cell_x_flipped(worldCell.x, worldCell.y) == true:
		if is_cell_y_flipped(worldCell.x, worldCell.y) == true:
			rot = 2
		else:
			rot = 1 #50% chance this is wrong
	else:
		if is_cell_y_flipped(worldCell.x, worldCell.y) == true:
			rot = 3 #50% chance this is wrong
		else:
			rot = 0
	#Consider putting a thing in here to also check for transpose before each rot assignment, just to double check there's no errors
	return rot

func calc_flip_trans(var rot: int):
	var flipTrans: Array = [false, false, false] #[flipX, flipY, trans] in that order
	match rot:
		0:
			return flipTrans
		1:
			flipTrans = [true, false, true]
		2:
			flipTrans = [true, true, false]
		3:
			flipTrans = [false, true, true]
	return flipTrans

#Honestly these aren't nescesary, they are just here so I don't forget which way the vectors need to be added/subtracted
func calc_offset(var centerCell: Vector2, var arrayRadius: int):
	return Vector2(centerCell.x-arrayRadius, centerCell.y-arrayRadius)
func world_to_array(var worldLoc: Vector2, var offset: Vector2):
	return worldLoc-offset
func array_to_world(var arrayLoc: Vector2, var offset: Vector2):
	return arrayLoc+offset
