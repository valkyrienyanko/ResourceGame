extends KinematicBody2D

const Utils = preload("res://Scripts/Utils.gd")

onready var mining_sprite = preload("res://Sprites/worker_mining.png")
onready var base_sprite = preload("res://Sprites/worker_return_to_base.png")
onready var tree_sprite = preload("res://Sprites/tree.png")
onready var townhall_sprite = preload("res://Sprites/townhall.png")
onready var worker_sprite = preload("res://Sprites/worker_mining.png")
onready var buildzone_sprite = preload("res://Sprites/build_zone.png")
onready var resources = get_tree().get_nodes_in_group("Resources")[0]

var velocity = Vector2();
var speed = 30
var find_resources = true
var harvest_resource_timer = 0
var harvest_time = 0.5
var dump_resource_timer = 0
var dump_resource_time_length = 0.5
var nearest_target = null
var nearest_townhall = null
var command = "find_nearest_tree"
var wood = 0

#woodcutter
#farmer
#scholar
#hunter
#miner

func _ready():
	add_to_group("Workers")
	
func move(delta):
	velocity = Vector2()
	
	var workers = get_tree().get_nodes_in_group("Workers")
	var close_workers = Array()
	for i in range(workers.size()):
		if position.distance_to(workers[i].position) < worker_sprite.get_width():
			close_workers.append(workers[i])
			
	var alignment = compute_alignment(close_workers)
	var cohesion = compute_cohesion(close_workers)
	var separation = compute_separation(close_workers)
	
	var allignment_weight = 30
	var cohesion_weight = 1
	var separation_weight = 3
	
	velocity += Utils.calc_target_velocity(position, nearest_target.position, speed)
	velocity.x += alignment.x * allignment_weight + cohesion.x * cohesion_weight + separation.x * separation_weight
	velocity.y += alignment.y * allignment_weight + cohesion.y * cohesion_weight + separation.y * separation_weight
	 
	velocity = velocity.normalized()
	
	position += velocity * delta * speed
	
func compute_alignment(close_workers):
	var vector = Vector2()
	for i in range(close_workers.size()):
		vector.x += close_workers[i].velocity.x
		vector.y += close_workers[i].velocity.y
	if close_workers.size() == 0:
		return vector
	else:
		vector.x /= close_workers.size()
		vector.y /= close_workers.size()
		vector.normalized()
		return vector
	
func compute_cohesion(close_workers):
	var vector = Vector2()
	for i in range(close_workers.size()):
		vector.x += close_workers[i].position.x
		vector.y += close_workers[i].position.y
	if close_workers.size() == 0:
		return vector
	else:
		vector.x /= close_workers.size()
		vector.y /= close_workers.size()
		vector = Vector2(vector.x - position.x, vector.y - position.y)
		vector.normalized()
		return vector
	
func compute_separation(close_workers):
	var vector = Vector2()
	for i in range(close_workers.size()):
		vector.x += close_workers[i].position.x - position.x
		vector.y += close_workers[i].position.y - position.y
	if close_workers.size() == 0:
		return vector
	else:
		vector.x /= close_workers.size()
		vector.y /= close_workers.size()
		vector.x *= -1
		vector.y *= -1
		vector.normalized()
		return vector
	
func ai(delta, cmd):
	match(cmd):
		"idle":
			pass
		"find_nearest_tree":
			var trees = get_tree().get_nodes_in_group("Trees")
			nearest_target = Utils.find_nearest_target(position, trees)
			if nearest_target != null:
				command = "move_towards_nearest_tree"
		"find_nearest_townhall":
			var townhalls = get_tree().get_nodes_in_group("Townhall")
			nearest_target = Utils.find_nearest_target(position, townhalls)
			if nearest_target != null:
				command = "move_towards_nearest_townhall"
		"find_nearest_buildzone":
			var buildzones = get_tree().get_nodes_in_group("BuildZones")
			var needs_to_be_constructed = Array()
			for i in range(buildzones.size()):
				if !buildzones[i].constructed:
					needs_to_be_constructed.append(buildzones[i])
			nearest_target = Utils.find_nearest_target(position, needs_to_be_constructed)
			if nearest_target != null:
				if wood < 1:
					resources.add_wood(-1)
					wood += 1
				if nearest_target.placed:
					if nearest_target.wood == 2:
						command = "find_nearest_townhall"
					else:
						command = "move_towards_nearest_buildzone"
		"move_towards_nearest_buildzone":
			if position.distance_to(nearest_target.position) < buildzone_sprite.get_width() + 1:
				wood -= 1
				nearest_target.wood += 1
				if nearest_target.wood == 2:
					nearest_target.evolve()
				command = "find_nearest_townhall"
			else:
				move(delta)
		"move_towards_nearest_tree":
			if position.distance_to(nearest_target.position) < tree_sprite.get_width() + 1:
				command = "harvest_wood"
			else:
				move(delta)
		"move_towards_nearest_townhall":
			if position.distance_to(nearest_target.position) < townhall_sprite.get_width() + 1:
				command = "drop_off_resources"
			else:
				move(delta)
		"harvest_wood":
			# Harvest resources for 'harvestTime' seconds.
			harvest_resource_timer += delta
			if get_node("WorkerSprite").texture != mining_sprite:
				get_node("WorkerSprite").texture = mining_sprite
			if harvest_resource_timer >= harvest_time:
				# We are finished gathering all the resources we can carry.
				harvest_resource_timer = 0
				wood += 1
				find_resources = false
				command = "find_nearest_townhall"
		"drop_off_resources":
			# Dump resources into base.
			dump_resource_timer += delta
			if get_node("WorkerSprite").texture != base_sprite:
				get_node("WorkerSprite").texture = base_sprite
			if dump_resource_timer >= dump_resource_time_length:
				# Resume previous task.
				dump_resource_timer = 0
				find_resources = true
				if wood > 0 && resources.wood <= resources.max_wood:
					resources.add_wood(wood)
					wood -= 1
				
				if resources.wood + wood < resources.max_wood:
					command = "find_nearest_tree"
				else:
					command = "find_nearest_buildzone"

func _physics_process(delta): # Main function called every frame.
	ai(delta, command)
