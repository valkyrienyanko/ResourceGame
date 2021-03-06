extends Button

onready var resources = get_tree().get_nodes_in_group("Resources")[0]
onready var build_zone_sprite = preload("res://Scenes/BuildZone.tscn")
onready var world_generator = get_tree().get_nodes_in_group("WorldGenerator")[0]

func _process(delta):
	if resources.wood >= 25:
		disabled = false
	else:
		disabled = true

func _on_ButtonCreateWoodGenerator_pressed():
	var build_zone = build_zone_sprite.instance()
	build_zone.set_position(world_generator.player.position)
	build_zone.init("wood_generator")
	world_generator.add_child(build_zone)
	get_tree().call_group("Labels", "refresh")
