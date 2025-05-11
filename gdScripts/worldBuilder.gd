extends Node

@onready var marker = preload("res://scenes/Marker.tscn") # Marker scene file

var array: Array = [] # The array that stores the points for the polygon2D
var markers: Dictionary = {} # Dictionary that stores all markers and their positions
var segments: int # Amount of segments composing the terrain, increase for higher resolution terrain
var step: float # Floating point to store default segment size in pixels on the X axis
var screenSizeX: int # Integer to store the size of the terrain on the X axis
var cliffs: bool = true # Experimental cliffs
var cliffPos: Array = [] # Array to store positions cliffs could start at
var cliffIndices: Array = [] # Stores at which index the position is in 'array' that each cliff was based on
var cliffCount: int = 0 # How many cliffs' positions have been picked out in the generation step
var color: Color = Color(0.6, 0.5, 0.25, 1) # The terrains' color in RGBA

func _ready() -> void:
	array.clear()
	markers.clear()
	cliffPos.clear()
	cliffIndices.clear()
	cliffCount = 0
	fill()
	build()

# Function to add the points to the array
func fill(offset: float = 0.0, terrainSegments: int = 256, terrainSizeX: int = 15360):
	segments = terrainSegments
	screenSizeX = terrainSizeX
	step = terrainSizeX / (terrainSegments - 1)
	for i in range(terrainSegments + 1):
		array.append(Vector2(((-terrainSizeX / 2) + step * i) + step * offset, randf_range(650, 800)))

# Function to move the points to resemble terrain
func build(Xrand: float = 0.15, Yrand: float = 0.55, cliffDistanceEdge: float = 0.75, maxCliffCount: int = 3, maxAlt: float = 100.0):
	var potentialCliffPos = array[randi_range(0, array.size()-1)]
	if cliffs:
		while cliffCount < maxCliffCount:
			while not evaluate(potentialCliffPos, cliffDistanceEdge):
				potentialCliffPos = array[randi_range(0, array.size()-1)]
			cliffPos.append(potentialCliffPos)
			cliffIndices.append(array.find(potentialCliffPos))
			cliffCount += 1
	for i in range(array.size()):
		var xRandomization: float = randf_range(-step * Xrand, step * Xrand)
		array[i].x += xRandomization
		for cliff in cliffPos:
			if cliff == array[i]:
				cliff.x += xRandomization
		if i == 0:
			continue
		array[i].y = array[i - 1].y
		var yRandomization = randf_range(-step * Yrand, step * Yrand)
		if i > 1:
			var diff = array[i - 1].y - array[i - 2].y
			array[i].y += diff * 0.2
		array[i].y += yRandomization
		if cliffIndices.has(i):
			array[i].y = clampf(cliffPos[cliffIndices.find(i)].y, -INF, maxAlt)
		else:
			array[i].y = clampf(array[i].y, -INF, maxAlt)
	array.append(Vector2(screenSizeX / 2, screenSizeX / 2))
	array.append(Vector2(-screenSizeX / 2, screenSizeX / 2))

	var newArray: Array = []
	for i in range(segments):
		var seg: Array = []
		var base = i
		if i == 0:
			seg.append(Vector2(-screenSizeX / 2, screenSizeX / 2))
			seg.append(array[base])
			seg.append(array[base + 1])
			seg.append(Vector2(array[base + 1].x, screenSizeX / 2))
		elif i == segments - 1:
			seg.append(Vector2(array[base].x, screenSizeX / 2))
			seg.append(array[base])
			seg.append(array[base + 1])
			seg.append(Vector2(screenSizeX / 2, screenSizeX / 2))
		else:
			seg.append(Vector2(array[base].x, screenSizeX / 2))
			seg.append(array[base])
			seg.append(array[base + 1])
			seg.append(Vector2(array[base + 1].x, screenSizeX / 2))
		newArray.append(seg)
	array = newArray



func evaluate(pos: Vector2, cliffDistanceEdge: float):
	if abs(pos.x) < (screenSizeX / 2) * cliffDistanceEdge:
		for position in cliffPos:
			if abs(pos.x - position.x) < 200.0:
				return false
				break
		return true
	else:
		return false

# Function to toggle markers at the points, meant for debugging
func mark():
	for pos in array:
		if not pos in markers.values():
			var markerScene = marker.instantiate()
			markerScene.position = pos
			markers[markerScene] = pos
			add_child(markerScene)
		else:
			markers.find_key(pos).queue_free()
			markers.erase(markers.find_key(pos))

func reset():
	array.clear()
	markers.keys().map(func(m): m.queue_free())
	markers.clear()
	cliffPos.clear()
	cliffIndices.clear()
	cliffCount = 0
	fill()
	build()
