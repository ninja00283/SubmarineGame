extends Node

var nodes: Dictionary = {} # Dictionary to store nodes and their associated data
const TRAIL = preload("res://assets/trail.tres")

func _process(delta: float) -> void:
	for node in nodes.keys():
		var data = nodes[node]
		var line2D = data[0]
		nodes[node][3] -= delta
		if line2D and node.global_position and data[4]:
			var offsetPosition = node.global_position + (data[2].rotated(node.rotation))
			line2D.add_point(offsetPosition)
		if data[3] < 0:
			if line2D.points.size() > 0:
				line2D.remove_point(0)
		if line2D.get_point_count() <= 0:
			nodes.erase(node)
			line2D.queue_free()

func addNode(node, segments: int, offset: Vector2, delay: float):
	var newLine2D = Line2D.new()
	newLine2D.gradient = TRAIL
	get_tree().root.add_child(newLine2D)
	nodes[node] = [newLine2D, segments, offset, delay, true]
	var offsetPosition = node.global_position + (offset.rotated(node.rotation))
	newLine2D.add_point(offsetPosition)

func removeNode(node):
	if node in nodes.keys():
		nodes[node][4] = false
	await get_tree().create_timer(1.0).timeout
	if node in nodes:
		var data = nodes[node]
		var line2D = data[0]
		if line2D:
			line2D.queue_free()
		nodes.erase(node)
