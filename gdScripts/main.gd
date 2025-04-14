extends Node2D

@onready var playerScene = preload("res://scenes/player.tscn")
@onready var border: Polygon2D = $Border/Border
@onready var animationPlayer: AnimationPlayer = $AnimationPlayer
@onready var camera2D: Camera2D = $Camera2D
@onready var cameraZoomTimer: Timer = $cameraZoomTimer
@onready var mainMenu: Node2D = $MainMenu
@onready var settings: Node2D = $MainMenu/Settings
@onready var endTextLabel: Label = $UI/endTextLabel
@onready var ui: Node2D = $UI
@onready var line2D: Line2D = $line2d
@onready var terrainPolygon: Polygon2D = $terrain/terrainPolygon
@onready var terrainCollider: CollisionPolygon2D = $terrain/terrainCollider
@onready var lightOccluder2D: LightOccluder2D = $terrain/lightOccluder2d

var gameEnded: bool = false
var started: bool = false
var settingsShown: bool = false
var canSpawn: bool = false
var isSpawning: bool = false
var debugging: bool = false
var listening: bool = false
var spawnFrameCounter: float = 0.0
var spawnRate: float = 0.025
var holdTime: float = 0.5
var holdCounter: float = 0.0
var startPlayerCount: int = 2
var spawnPos: Array = [Vector2(-1600, 0), Vector2(1600, 0)]
var players: Array = []
var objects: Array = []
var heldObjects: Array = []

func _ready() -> void:
	terrainPolygon.polygon = PackedVector2Array(WorldBuilder.array)
	terrainCollider.polygon = PackedVector2Array(WorldBuilder.array)
	lightOccluder2D.occluder.polygon = PackedVector2Array(WorldBuilder.array)
	for player in range(startPlayerCount):
		var playerInstance = playerScene.instantiate()
		playerInstance.position = spawnPos[0]
		playerInstance.root = self
		players.append(playerInstance)
		add_child(playerInstance)
		move_child(playerInstance, 0)
		spawnPos.remove_at(0)
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

	if Input.is_action_just_pressed("Reload") and started:
		terrainPolygon.polygon = PackedVector2Array(WorldBuilder.array)
		terrainCollider.polygon = PackedVector2Array(WorldBuilder.array)
		lightOccluder2D.occluder.polygon = PackedVector2Array(WorldBuilder.array)
		animationPlayer.stop()
		animationPlayer.play("RESET")
		animationPlayer.stop()
		for player in players:
			if is_instance_valid(player):
				player.queue_free()
				players.erase(player)
		for object in objects:
			if is_instance_valid(object):
				object.queue_free()
		get_tree().reload_current_scene()

	if debugging:
		if Input.is_action_pressed("LMB"):
			var worldMousePos = get_viewport().get_camera_2d().get_global_mouse_position()
			var query = PhysicsPointQueryParameters2D.new()
			query.position = worldMousePos
			query.collide_with_bodies = true
			for body in get_world_2d().direct_space_state.intersect_point(query):
				heldObjects.append(body["collider"])
			for object in heldObjects:
				if is_instance_valid(object):
					object.global_position = worldMousePos
		else:
			heldObjects.clear()
		if Input.is_action_just_pressed("MMB"):
			var playerInstance = playerScene.instantiate()
			playerInstance.position = get_global_mouse_position()
			playerInstance.root = self
			players.append(playerInstance)
			get_tree().root.add_child(playerInstance)
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

func _input(event: InputEvent) -> void:
	if listening:
		pass

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

func borderHit(body: Node2D) -> void:
	if "velocity" in body:
		var velocityMagnitude = body.velocity.length()
		var startPosition = 0.0
		if velocityMagnitude < 600.0:
			startPosition = lerp(0.2,0.0,clamp(velocityMagnitude/600.0,0.0,1.0))
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
	for player in players:
		player.radarAltimeter.force_raycast_update()
		if player.radarAltimeter.is_colliding():
			print("Player: ", players.find(player), " Radar altitude: ", player.radarAltimeter.get_collision_point().y)
			player.position.y = player.radarAltimeter.get_collision_point().y - 100

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
	ui.morseClear()
	for player in players:
		if is_instance_valid(player):
			player.queue_free()
			players.erase(player)
	for object in objects:
		if is_instance_valid(object):
			object.queue_free()
	get_tree().reload_current_scene()

func _onSubmitButtonPressed() -> void:
	var ev = InputEventAction.new()
	ev.action = "Submit"
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().process_frame
	var evUp = InputEventAction.new()
	evUp.action = "Submit"
	evUp.pressed = false
	Input.parse_input_event(evUp)


func _onReloadButtonPressed() -> void:
	var ev = InputEventAction.new()
	ev.action = "Reload"
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().process_frame
	var evUp = InputEventAction.new()
	evUp.action = "Reload"
	evUp.pressed = false
	Input.parse_input_event(evUp)
