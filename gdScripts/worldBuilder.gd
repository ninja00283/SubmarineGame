extends Node

@onready var marker = preload("res://scenes/Marker.tscn") # Marker scene file

var array: Array = [] # The array that stores the points for the polygon2D
var markers: Dictionary = {} # Dictionary that stores all markers and their positions
var segments: int # Amount of segments composing the terrain, increase for higher resolution terrain (figuratively)
var step: float # Floating point to store default segment size in pixels on the X axis
var screenSizeX: int # Integer to store the size of the terrain on the X axis
var cliffs: bool = true # Experimental cliffs
var cliffPos: Array = [] # Array to store positions cliffs could start at
var cliffIndices: Array = [] # Stores at which index the position is in 'array' that each cliff was based on
var cliffCount: int = 0 # How many cliffs have currently been selected in the generation step

func _ready() -> void:
	array.clear()
	markers.clear()
	cliffPos.clear()
	cliffIndices.clear()
	cliffCount = 0
	fill()
	build()

# Function to add the points to the array
func fill(offset: float = 0.0, terrainSegments: int = 64, terrainSizeX: int = 3840):
	segments = terrainSegments
	screenSizeX = terrainSizeX
	step = terrainSizeX / (terrainSegments - 1)
	for i in range(terrainSegments + 1):
		array.append(Vector2(((-terrainSizeX / 2) + step * i) + step * offset, randf_range(200, 800)))

# Function to move the points to resemble terrain
func build(Xrand: float = 0.15, Yrand: float = 0.25, cliffDistanceEdge: float = 0.85, maxCliffCount: int = 3):
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
		array[i].y = array[i-1].y
		var yRandomization: float = randf_range(-step * Yrand, step * Yrand)
		array[i].y += yRandomization
		if cliffIndices.has(i):
			array[i].y = cliffPos[cliffIndices.find(i)].y
	array.append(Vector2(screenSizeX / 2, screenSizeX / 2))
	array.append(Vector2(-screenSizeX / 2, screenSizeX / 2))

func evaluate(pos: Vector2, cliffDistanceEdge: float):
	if abs(pos.x) < (screenSizeX / 2) * cliffDistanceEdge:
		for position in cliffPos:
			if abs(pos.x - position.x) < 300.0:
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
