extends Node2D

@onready var flamethrowerProjectile = preload("res://scenes/flamethrowerProjectile.tscn")
@onready var timer: Timer = $timer

var player: CharacterBody2D # The player that fired the flamethrower
var thingy: float = 0.0 # Temp variable, will rename in the future
var fire = true # Whether or not the weapon should fire
var flames = true # Whether or not any flames are present
var hitObjects: Array = [] # All targets that were hit
var damage: float = 0.0 # The amount of damage dealt after 5.25s after firing
var projectilePool: Array = [] # Object pool for projectiles
var poolIncreaseThreshold = 10 # Threshold to increase pool size if it's running low
var maxPoolSize = 200 # Maximum size of the pool

func _ready() -> void:
	for i in range(100):
		var projectile = flamethrowerProjectile.instantiate()
		projectile.set_process(false)
		projectilePool.append(projectile)

func _process(delta: float) -> void:
	if fire:
		thingy += delta
		if thingy > 0.02:
			for i in range(int(thingy / 0.02)):
				var projectile: CharacterBody2D
				if projectilePool.size() > 0:
					projectile = projectilePool.pop_back()
				else:
					if projectilePool.size() < maxPoolSize:
						projectile = flamethrowerProjectile.instantiate()
					else:
						return

				projectile.global_position = self.global_position
				projectile.velocity = Vector2.from_angle(rotation + randf_range(-0.03, 0.03)) * 800
				get_tree().root.add_child(projectile)
				projectile.flamethrower = self
				projectile.set_process(true)
				thingy -= 0.02

func _onQueueFreeDelayTimeout() -> void:
	fire = false

func _onTimerTimeout() -> void:
	flames = false
	player.attackDamageF(damage, false)
	player.attackDamageF(0.0, true)
