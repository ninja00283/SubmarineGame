extends Node2D

@onready var playerScene = preload("res://scenes/player.tscn")
@onready var border: Polygon2D = $Border/Border
@onready var animationPlayer: AnimationPlayer = $AnimationPlayer
@onready var camera2D: Camera2D = $Camera2D
@onready var cameraZoomTimer: Timer = $cameraZoomTimer
@onready var mainMenu: Node2D = $MainMenu
@onready var settings: Node2D = $MainMenu/Settings
@onready var endTextLabel: Label = $UI/endTextLabel

var gameEnded: bool = false
var started: bool = false
var settingsShown: bool = false
var spawnFrameCounter: float = 0.0
var spawnRate: float = 0.025
var holdTime: float = 0.5
var holdCounter: float = 0.0
var canSpawn: bool = false
var isSpawning: bool = false
var debugging: bool = false
var startPlayerCount: int = 2
var spawnPos: Array = [Vector2(800, 0), Vector2(-800, 0)]
var players: Array = []
var objects: Array = []

func _ready() -> void:
	for player in range(startPlayerCount):
		var arrayIndex = randi_range(0, spawnPos.size() - 1)
		var pos = spawnPos[arrayIndex]
		var playerInstance = playerScene.instantiate()
		playerInstance.position = pos
		playerInstance.root = self
		players.append(playerInstance)
		add_child(playerInstance)
		spawnPos.remove_at(arrayIndex)
	get_tree().paused = true

func _process(delta: float) -> void:
	if not debugging and players.size() < 2 and not gameEnded:
		gameWon()
	if players.size() > 0 and not started:
		for player in players:
			if settingsShown:
				player.commandInput.hide()
			else:
				player.commandInput.show()   
	if debugging:
		if Input.is_action_just_pressed("MMB"):
			var playerInstance = playerScene.instantiate()
			playerInstance.position = get_global_mouse_position()
			playerInstance.root = self
			players.append(playerInstance)
			get_tree().root.add_child(playerInstance)
			
	if Input.is_action_just_pressed("Reload") and started:
		for player in players:
			if is_instance_valid(player):
				player.queue_free()
		for object in objects:
			if is_instance_valid(object):
				object.queue_free()
		get_tree().reload_current_scene()
			
	if debugging:
		if Input.is_action_just_pressed("Spawn"):
			holdCounter = 0.0
			canSpawn = false
			isSpawning = true
			spawnPlayerRing(100, 600)
			
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
			playerInstance.root = self
			playerInstance.position = spawnPosition
			players.append(playerInstance)
			get_tree().root.add_child(playerInstance)


func _borderHit(body: Node2D) -> void:
	if "velocity" in body:
		var velocityMagnitude = body.velocity.length()
		var startPosition = 0.0
		if velocityMagnitude < 400.0:
			startPosition = lerp(0.2,0.0,clamp(velocityMagnitude/400.0,0.0,1.0))
		animationPlayer.stop()
		animationPlayer.play("borderHit")
		animationPlayer.seek(startPosition, true)
		print("Body collided with world border. Velocity: ", velocityMagnitude, " Start position: ", startPosition)

func positionCamera(pos):
	camera2D.position = pos
	animationPlayer.play("cameraZoom")
	cameraZoomTimer.start()

func _on_camera_zoom_timer_timeout() -> void:
	await get_tree().create_timer(0.6).timeout
	camera2D.position = Vector2(0, 0)
	animationPlayer.play("cameraZoomPost")

func _on_quit_button_pressed() -> void:
	mainMenu.hide()
	get_tree().quit()

func _on_start_button_pressed() -> void:
	started = true
	if players.size() > 0:
		for player in players:
			player.commandInput.show()
	mainMenu.hide()
	get_tree().paused = false


func _on_settings_button_pressed() -> void:
	if settingsShown:
		settings.hide()
		settingsShown = false
	else:
		settings.show()
		settingsShown = true


func _on_debug_button_pressed() -> void:
	started = true
	if players.size() > 0:
		for player in players:
			player.commandInput.show()
	mainMenu.hide()
	get_tree().paused = false
	debugging = true


func gameWon() -> void:
	gameEnded = true
	await get_tree().create_timer(5).timeout
	if players.size() > 0:
		print("We have a winner!: ", players[0])
		endTextLabel.text = str("We have a winner!: ", players[0])
	else:
		print("No players lived to tell the tale.")
		endTextLabel.text = str("No players lived to tell the tale.")
	await get_tree().create_timer(5.5).timeout
	for player in players:
		if is_instance_valid(player):
			player.queue_free()
	for object in objects:
		if is_instance_valid(object):
			object.queue_free()
	get_tree().reload_current_scene()
	
