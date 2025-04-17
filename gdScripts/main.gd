extends Node2D

@onready var playerScene = preload("res://scenes/player.tscn")
@onready var border: Polygon2D = $Border/Border
@onready var animationPlayer: AnimationPlayer = $AnimationPlayer
@onready var camera2D: Camera2D = $Camera2D
@onready var cameraZoomTimer: Timer = $cameraZoomTimer
@onready var mainMenu: Node2D = $MainMenu
@onready var settings: Node2D = $MainMenu/Settings
@onready var endTextLabel: Label = $UI/endTextLabel
@onready var line2D: Line2D = $line2d
@onready var terrain: StaticBody2D = $terrain
@onready var terrainPolygon: Polygon2D = $terrain/terrainPolygon
@onready var terrainCollider: CollisionPolygon2D = $terrain/terrainCollider
@onready var lightOccluder2D: LightOccluder2D = $terrain/lightOccluder2d
@onready var inputPrompt: Label = $UI/vBoxContainer/inputPrompt
@onready var inputPromptCover: ColorRect = $UI/inputPromptCover
@onready var keyInUse: Label = $UI/vBoxContainer/keyInUse
@onready var keyInUseTimer: Timer = $UI/vBoxContainer/keyInUseTimer

var gameEnded: bool = false
var started: bool = false
var settingsShown: bool = false
var canSpawn: bool = false
var isSpawning: bool = false
var debugging: bool = false
var listening: bool = false
var listeningSubmit: bool = false
var spawnFrameCounter: float = 0.0
var spawnRate: float = 0.025
var holdTime: float = 0.5
var holdCounter: float = 0.0
var startPlayerCount: int = 2
var keybinds: int = 0
var keybindsSubmit: int = 0
var spawnPos: Array = [Vector2(-1600, 0), Vector2(1600, 0)]
var players: Array = []
var objects: Array = []
var heldObjects: Array = []
var keysAsText: Array = []

func _ready() -> void:
	if not terrain.is_in_group("Terrain"):
		terrain.add_to_group("Terrain")
	for action in InputMap.get_actions():
		if action.begins_with("P") and (action.ends_with("MorseInput") or action.ends_with("TextSubmit")):
			InputMap.erase_action(action)
	for child in terrain.get_children():
		if child is Polygon2D or child is CollisionPolygon2D:
			child.queue_free()
	for polygonPoints in WorldBuilder.array:
		var poly = Polygon2D.new()
		poly.polygon = PackedVector2Array(polygonPoints)
		terrain.add_child(poly)
		var collider = CollisionPolygon2D.new()
		collider.polygon = PackedVector2Array(polygonPoints)
		terrain.add_child(collider)
		var lightOccluder = LightOccluder2D.new()
		var lightOccluderPolygon = OccluderPolygon2D.new()
		lightOccluder.occluder = lightOccluderPolygon
		lightOccluder.occluder.polygon = PackedVector2Array(polygonPoints)
		terrain.add_child(lightOccluder)
	for player in range(startPlayerCount):
		var playerInstance = playerScene.instantiate()
		playerInstance.position = spawnPos[0]
		playerInstance.root = self
		players.append(playerInstance)
		playerInstance.index = player
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
		for child in terrain.get_children():
			if child is Polygon2D or child is CollisionPolygon2D:
				child.queue_free()
		for i in range(WorldBuilder.array.size()):
			var polygonPoints = WorldBuilder.array[i]
			var poly = Polygon2D.new()
			poly.polygon = PackedVector2Array(polygonPoints)
			terrain.add_child(poly)
			var collider = CollisionPolygon2D.new()
			collider.polygon = PackedVector2Array(polygonPoints)
			terrain.add_child(collider)
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
	if listening and not started:
		for i in range(players.size()):
			if not str("P", i, "MorseInput") in InputMap.get_actions():
				if event.is_action_type() and event.is_released() and not event.is_echo():
					if not event.as_text() in keysAsText:
						addKeybind(event, true, i)
						keybinds += 1
						print("Keybind set, action: ", str("P", i, "MorseInput"), " Event: ", event)
						keysAsText.append(event.as_text())
						if i == players.size() - 1:
							listening = false
							listeningSubmit = true
						break
					else:
						keyInUse.show()
						keyInUseTimer.stop()
						keyInUseTimer.start()
						break
	elif listeningSubmit and not started:
		for i in range(players.size()):
			if not str("P", i, "TextSubmit") in InputMap.get_actions():
				if event.is_action_type() and event.is_released() and not event.is_echo():
					if not event.as_text() in keysAsText:
						addKeybind(event, false, i)
						keybindsSubmit += 1
						print("Keybind set, action: ", str("P", i, "TextSubmit"), " Event: ", event)
						keysAsText.append(event.as_text())
						if i == players.size():
							listeningSubmit = false
						break
					else:
						keyInUse.show()
						keyInUseTimer.stop()
						keyInUseTimer.start()
						break
	if keybinds < 2:
		inputPrompt.text = str("Player ", keybinds + 1, ": Press any key to set as morse input")
	elif keybindsSubmit < 2:
		inputPrompt.text = str("Player ", keybindsSubmit + 1, ": Press any key to set as text submit")

func addKeybind(key: InputEvent, morseInput: bool, index: int):
	if morseInput:
		if not str("P", index, "MorseInput") in InputMap.get_actions():
			InputMap.add_action(str("P", index, "MorseInput"))
			InputMap.action_add_event(str("P", index, "MorseInput"), key)
	else:
		if not str("P", index, "TextSubmit") in InputMap.get_actions():
			InputMap.add_action(str("P", index, "TextSubmit"))
			InputMap.action_add_event(str("P", index, "TextSubmit"), key)

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
	listening = true
	inputPrompt.show()
	inputPromptCover.show()
	mainMenu.hide()
	await waitForPlayers()
	inputPrompt.hide()
	inputPromptCover.hide()
	started = true
	if players.size() > 0:
		for player in players:
			player.commandInput.show()
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
	for player in players:
		if is_instance_valid(player):
			player.queue_free()
			players.erase(player)
	for object in objects:
		if is_instance_valid(object):
			object.queue_free()
	get_tree().reload_current_scene()

func waitForPlayers():
	while players.size() > keybinds or players.size() > keybindsSubmit:
		await get_tree().create_timer(0.1).timeout

func _onKeyInUseTimerTimeout() -> void:
	keyInUse.hide()

func clip(poly):
	for child in terrain.get_children():
		if "polygon" in child:
			if abs(poly.global_position.x - child.polygon[0].x) < 200:
				poly.scale *= 1.2
				var offsetPoly = Polygon2D.new()
				var transformed_points = []
				for point in poly.polygon:
					transformed_points.append(poly.to_global(point))
				offsetPoly.polygon = transformed_points
				var res = Geometry2D.clip_polygons(child.polygon, offsetPoly.polygon)
				child.set_deferred("polygon", res[0])
				offsetPoly.queue_free()
				poly.scale *= 0.83333333333
