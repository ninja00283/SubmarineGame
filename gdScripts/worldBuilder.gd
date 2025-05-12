extends Node

@onready var marker = preload("res://scenes/Marker.tscn")

var array: Array = []
var markers: Dictionary = {}
var segments: int
var step: float
var screenSizeX: int
var cliffs: bool = true
var cliffPos: Array = []
var cliffIndices: Array = []
var cliffCount: int = 0
var color: Color = Color(0.1, 0.5, 0.5, 1)
var stalactites: bool = true
var stalactiteResolution: int = 8
var stalactiteMaxHeight: float = -200.0
var stalactiteMinHeight: float = -100.0

func _ready() -> void:
	array.clear()
	markers.clear()
	cliffPos.clear()
	cliffIndices.clear()
	cliffCount = 0
	fill()
	build()

func fill(offset: float = 0.0, terrainSegments: int = 192, terrainSizeX: int = 3840):
	segments = terrainSegments
	screenSizeX = terrainSizeX
	step = terrainSizeX / (terrainSegments - 1)
	for i in range(terrainSegments + 1):
		array.append(Vector2(((-terrainSizeX / 2) + step * i) + step * offset, randf_range(300, 800)))

func build(Xrand: float = 0.15, Yrand: float = 0.35, cliffDistanceEdge: float = 0.8, maxCliffCount: int = 12):
	var upSlope: bool = true
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
				cliffPos[i].x += xRandomization
		array[i].y = array[i-1].y
		var yRandomization
		if randf_range(0.0, 1.0) > 0.7:
			upSlope = !upSlope
		if upSlope:
			yRandomization = randf_range(-step * Yrand, step * (Yrand * randf_range(-16.0, 16.0)))
		else:
			yRandomization = randf_range(-step * (Yrand * randf_range(-16.0, 16.0)), step * Yrand)
		randomize()
		var diff = array[i-1].y - array[i-2].y
		array[i].y += diff * randf_range(-0.2, 0.2)
		randomize()
		array[i].y += yRandomization
		if cliffs:
			if cliffIndices.has(i):
				array[i].y = cliffPos[cliffIndices.find(i)].y
	for i in range(array.size()):
		if randf_range(0.0, 1.0) > 0.9 and i < array.size()-1 and stalactites:
			array[i].y += randf_range(stalactiteMinHeight, stalactiteMaxHeight)
			array[i+1].y = array[i].y
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
			if abs(pos.x - position.x) < 120.0:
				return false
				break
		return true
	else:
		return false

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
