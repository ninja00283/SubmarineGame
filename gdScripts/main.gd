extends Node2D

@onready var playerScene = preload("res://scenes/player.tscn")
var spawnFrameCounter = 0.0
var spawnRate = 0.025
var holdTime = 0.5
var holdCounter = 0.0
var canSpawn = false
var isSpawning = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Spawn"):
		holdCounter = 0.0
		canSpawn = false
		isSpawning = true
		spawnPlayerRing(300, 400)
	if Input.is_action_pressed("Spawn"):
		holdCounter += delta
		if holdCounter >= holdTime:
			canSpawn = true
	if Input.is_action_just_released("Spawn"):
		isSpawning = false
	if isSpawning and canSpawn:
		spawnFrameCounter += delta
		if spawnFrameCounter >= spawnRate:
			spawnPlayerRing(100, 600)
			spawnFrameCounter = 0

func spawnPlayerRing(innerOffset: float, outerOffset: float):
	var spawnCount = 1
	for i in range(spawnCount):
		var angleRadians = randf() * TAU
		var radius = randf_range(innerOffset, outerOffset)
		var spawnPosition = Vector2(cos(angleRadians), sin(angleRadians)) * radius - Vector2(0, outerOffset - 200)
		var pointQueryParams = PhysicsPointQueryParameters2D.new()
		pointQueryParams.position = spawnPosition
		var collision = get_world_2d().direct_space_state.intersect_point(pointQueryParams)
		if collision != null:
			var playerInstance = playerScene.instantiate()
			playerInstance.position = spawnPosition
			get_tree().root.add_child(playerInstance)
