extends TileMap

var searchDist = 3
var rng = RandomNumberGenerator.new()
var edgeKeyAddress = 'res://assets/Tile Sets/Basic Tiles v01.00 Edge Key.txt'
var edgeKey: Array
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
		edgeKey.append(line)
		index += 1
	f.close()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	wfc()

func wfc():
	var playerPosition: Vector2 = world_to_map(get_node("../Player Icon").position) #This is Global TileMap coordinates.
	print("Player position: " + String(playerPosition))
	var wfcArray: Array
	wfcArray.resize((searchDist*2)+1)
	for x in range(0, searchDist*2+1):
		wfcArray[x] = []
		wfcArray[x].resize((searchDist*2)+1)
	var solutionCount: Array
	var setCount: int = 1
	#check to see if all cells within the search radius are set. If they are set then do nothing.
	var allSet: bool = true
	for x in range(playerPosition.x-searchDist,playerPosition.x+searchDist+1):
		for y in range(playerPosition.y-searchDist,playerPosition.y+searchDist+1):
			if get_cell(x,y) == -1:
				allSet = false
				print("Tile at (" + String(x) + "," + String(y) + ") is not set.")
	if allSet == false:
		while setCount != 0:
			setCount = 0
			var wfcItterateTemp: Array = wfcItterate(wfcArray, playerPosition, solutionCount)
			wfcArray = wfcItterateTemp[0]
			solutionCount = wfcItterateTemp[1]
			var randomDepth: int = 1
			while randomDepth < 14:
				if setCount != 0:
					break
				for x in range(0, solutionCount.size()):
					if setCount != 0:
						break
					for y in range(0, solutionCount[x].size()):
						if setCount != 0:
							break
						#if solutionCount[x][y].size() == 0:
							#print("Tile at (" + String(x) + "," + String(y) + ") in local array has no solution.")
							#print(String(solutionCount[x][y].size())) #For some reason the solutionCount[x][y].size() within wfcItterate is correct, but here it isnt.
						if solutionCount[x][y].size() == randomDepth:
							var chosenID: int = rng.randi_range(0, randomDepth-1)
							#print("Chosen tile ID: " + String(solutionCount[x][y][chosenID].x))
							#print("Chosen tile rotation: " + String(solutionCount[x][y][chosenID].y))
							flipTrans = calc_flip_trans(solutionCount[x][y][chosenID].y)
							#print("FlipX: " + String(flipTrans[0]) + ", FlipY: " + String(flipTrans[1]) + ", Trans: " + String(flipTrans[2]))
							set_cellv(array_to_world(Vector2(x, y), calc_offset(playerPosition, searchDist)), solutionCount[x][y][chosenID].x ,flipTrans[0], flipTrans[1], flipTrans[2])
							setCount += 1
				randomDepth += 1

func wfcItterate(var wfcArray: Array, var playerPosition: Vector2, var solutionCount: Array):
	var setCount: int = 1
	while setCount != 0:
		wfcArray = generate_wfc_array(playerPosition, searchDist) #Generate the array full of true/false values for every tile type and rotation of every tile within the search radius.
		setCount = 0
		solutionCount = []
		solutionCount.resize(wfcArray.size())
		for x in range(0, wfcArray.size()):
			solutionCount[x] = []
			solutionCount[x].resize(wfcArray[x].size())
		for x in range(0, wfcArray.size()):
			for y in range(0, wfcArray[x].size()):
				trueList.resize(0)
				if wfcArray[x][y] != null:
					for t in range(0, wfcArray[x][y].size()):
						for r in range(0, wfcArray[x][y][t].size()):
							if wfcArray[x][y][t][r] == true:
								trueList.append(Vector2(t, r)) #Records the tile type and rotations that are valid so that I can go back and check which one was true later.
				solutionCount[x][y] = trueList.duplicate()#Remember that thing about arrays being passed by refference? Yeah well arrays work just fine when you are passing them from one method to another, but when you are within the same method they need to be duplicated.
				#print("solutionCount[" + String(x) + "][" + String(y) + "] = " + String(solutionCount[x][y].size()))
		#print("solutionCount double check")
		#for x in range(0, wfcArray.size()):
			#for y in range(0, wfcArray[x].size()):
				#print("solutionCount[" + String(x) + "][" + String(y) + "] = " + String(solutionCount[x][y].size()))
	return [wfcArray, solutionCount] #This is the most disgusting thing I've done here yet. These should just be declared before Ready but this is only a proof of concept and nothing matters so meh.

func generate_wfc_array(var centerCell: Vector2, var arrayRadius: int): #tilemap coordinates
	#This method should really be part of a custom 4D array class, do that later
	#Same with update_cell_status
	var currentCell: Vector2 = centerCell
	var arrayOffset: Vector2 = calc_offset(currentCell, arrayRadius)
	print("Generating array at player location " + String(centerCell) + ", search radius " + String(arrayRadius) + ", with array offset " + String(arrayOffset))
	var wfcArray: Array = []
	wfcArray.resize((arrayRadius*2)+1) #Set array's X dimension length
	for x in range(0, arrayRadius*2+1):
		#add a new Y dimension array to each X index and set the Y dimension length
		wfcArray[x] = []
		wfcArray[x].resize((arrayRadius*2)+1)
		for y in range(0, arrayRadius*2+1):
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
	for t in range(0, 13):
		cellStatus[t] = []
		cellStatus[t].resize(4) #Sets the array within each cell type to be 4 to represent the 4 rotational positions
		for r in range(0, 4):
			cellStatus[t][r] = true #Sets the value of all possible tile types and rotations as true, in preperation for options to be eliminated later
	var tileMatches: Array = []
	#WARNING: The coordinate system for godot has 0,0 at the top left of the grid. I have adjusted the north/south neighbor indexes to account for the grid being inverted. Origionally I had assumed the origin was bottom left.
	var neighborIndex: int = get_cellv(worldCell+vert) #North
	if neighborIndex != -1:
		tileMatches = get_tile_matches(worldCell+vert, neighborIndex, 0) #titleMatches should be the same exact format as cellStatus, and so i can look at every cell in tile matches that is false and set that same tile in cellStatus as false too.
		eliminate_tiles(tileMatches, cellStatus)
	neighborIndex = get_cellv(worldCell-horiz) #West
	if neighborIndex != -1:
		tileMatches = get_tile_matches(worldCell-horiz, neighborIndex, 3)
		eliminate_tiles(tileMatches, cellStatus)
	neighborIndex = get_cellv(worldCell-vert) #South
	if neighborIndex != -1:
		tileMatches = get_tile_matches(worldCell-vert, neighborIndex, 2)
		eliminate_tiles(tileMatches, cellStatus)
	neighborIndex = get_cellv(worldCell+horiz) #East
	if neighborIndex != -1:
		tileMatches = get_tile_matches(worldCell+horiz, neighborIndex, 1)
		eliminate_tiles(tileMatches, cellStatus)
	#for t in range(0, 13):
		#for r in range(0, 4):
			#print("cellStatus [" + String(t) + "][" + String(r) + "]: " + String(cellStatus[t][r]))
	return cellStatus

func eliminate_tiles(var tileMatches: Array, var cellStatus: Array): #Suposedly arrays are passed by refference and so I don't need to return them, we'll see
	for t in range(0, 13):
		for r in range(0, 4):
			if tileMatches[t][r] == false:
				cellStatus[t][r] = false
	
func get_tile_matches(var worldCell: Vector2, var worldCellIndex: int, var tileEdge: int):
	#tileEdge uses the same logic as the edge key. A 0 represents the north edge, and every increase increments the edges counter clockwise menaing 1 is west, 2 is south, and 3 is east.
	#print("- - -")
	#print("Getting tile matches for global tile (" + String(worldCell.x) + "," + String(worldCell.y) + ") on side " + String(tileEdge))
	var rot: int = get_tile_rotation(worldCell) #Rot uses the same logic as the edge key.
	var edgeCode: String = edgeKey[(worldCellIndex*4)+rot]
	#print("The edgeCode line for rotation " + String(rot) + " reads: " + String(edgeKey[(worldCellIndex*4)+rot]))
	match edgeCode[5+(4*tileEdge)]:
		"1":
			edgeCode[5+(4*tileEdge)] = "2"
		"2":
			edgeCode[5+(4*tileEdge)] = "1"
		"0":
			edgeCode[5+(4*tileEdge)] = "0"
	#print("Looking for " + String(edgeCode.substr(5+(4*tileEdge), 3)) + " after mirroring. (position " + String(tileEdge) + ")")
	var matches: Array = [] #This is the array object that will ultimately be returned
	matches.resize(13) #Sets the length of the cell status array equal to the number of tile types I'm using
	for t in range(0, 13):
		matches[t] = []
		matches[t].resize(4) #Sets the array within each cell type to be 4 to represent the 4 rotational positions
		for r in range(0, 4):
			if edgeKey[(4*t)+r].substr(5+(4*posmod(tileEdge+2, 4)), 3) == edgeCode.substr(5+(4*tileEdge), 3):
				matches[t][r] = true
				#print("Found a match at edgeKeyLine [" + String(t) + "][" + String(r) + "] in position " + String(posmod(tileEdge+2, 4)) + ": " + edgeKey[(4*t)+posmod(r+tileEdge+2, 4)])
			else:
				matches[t][r] = false
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
