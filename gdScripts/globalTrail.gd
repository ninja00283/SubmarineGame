extends Node

var nodes: Array = [] # Array to store all nodes that should have a trail
var line2Ds: Array = [] # Array to store all line2D nodes
var segmentCounts: Array = [] # Array to store segment count for each line2D node
const TRAIL = preload("res://assets/trail.tres")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	for i in range(nodes.size()):
		if nodes[i]:
			line2Ds[i].add_point(nodes[i].global_position)
	for line in line2Ds:
		var index = line2Ds.find(line)
		if line2Ds[index].points.size() > segmentCounts[index]:
			line2Ds[index].remove_point(0)
	for line in line2Ds:
		if line.get_point_count() <= 0:
			line2Ds.remove_at(line2Ds.find(line))
			line.queue_free()

func addNode(node, segments: int):
	var newLine2D = Line2D.new()
	nodes.append(node)
	newLine2D.gradient = TRAIL
	line2Ds.append(newLine2D)
	get_tree().root.add_child(newLine2D)
	segmentCounts.append(segments)
	
func removeNode(node):
	var index = nodes.find(node)
	await get_tree().create_timer(0.5).timeout
	if index != -1:
		if index < nodes.size() and nodes.size() != -1:
			nodes.remove_at(index)
		if index < line2Ds.size() and line2Ds.size() != -1:
			line2Ds.remove_at(index)
		if index < segmentCounts.size() and segmentCounts.size() != -1:
			segmentCounts.remove_at(index)
