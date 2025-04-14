extends Node2D

@onready var flamethrowerProjectile = preload("res://scenes/flamethrowerProjectile.tscn")
@onready var timer: Timer = $timer

var player: CharacterBody2D # The player that fired the flamethrower
var timeElapsed: float = 0.0 # Time passed since the weapon was fired
var thingy: float = 0.0 # Temp variable, will rename in the future
var fire = true # Whether or not the weapon should fire
var flames = true # Whether or not any flames are present
var hitObjects: Array = [] # All targets that were hit
var damage: float = 0.0 # The amount of damage dealt after 5.25s after firing

func _process(delta: float) -> void:
	if fire:
		timeElapsed += delta
		thingy += delta
		if thingy > 0.015:
			for i in range(int(thingy / 0.015)):
				var projectile: CharacterBody2D = flamethrowerProjectile.instantiate()
				projectile.global_position = self.global_position
				projectile.velocity = Vector2.from_angle(rotation + randf_range(-0.03, 0.03)) * 800
				get_tree().root.add_child(projectile)
				projectile.flamethrower = self
				thingy -= 0.015

func _onQueueFreeDelayTimeout() -> void:
	fire = false

func _onTimerTimeout() -> void:
	flames = false
	player.attackDamageF(damage, false)
	player.attackDamageF(0.0, true)
