extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.size=Vector2i(1280,800)
	root.add_child(scene)
	await process_frame
	scene.size=Vector2(1280,800)
	scene._layout()
	var property = scene.city.properties[0]
	scene._fit()
	var click = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = scene.screen(property.rect.get_center())
	click.global_position = click.position
	click.pressed = true
	root.push_input(click,true)
	var release = click.duplicate()
	release.pressed = false
	root.push_input(release,true)
	await process_frame
	assert(scene.stops.size()==1)
	assert(scene.legs[0][-1]==property.access)
	scene._toggle_drive()
	for i in range(2000): scene._process(0.1)
	assert(scene.leg_index==1)
	assert(scene.van==property.access)
	assert(not scene.travelling)
	assert(scene.city.clock>450)
	scene._next_day()
	assert(scene.stops.size()==1 and scene.city.day==2)
	assert(scene.van==Vector2.ZERO and not scene.started)
	scene._undo()
	assert(scene.stops.is_empty())
	scene.route_mode=false
	scene._tap(property.rect.get_center())
	assert(scene.stops.is_empty() and scene.selected==0)
	scene._choose_depot()
	var base = scene.city.properties[20]
	scene._tap(base.rect.get_center())
	assert(scene.city.depot==base.access and scene.van==base.access)
	scene.route_mode=true
	scene._tap(property.rect.get_center())
	assert(scene.legs[0][0]==base.access,"Route starts at chosen depot")
	scene._choose_depot()
	scene._toggle_drive()
	assert(not scene.started,"Cannot drive while placing depot")
	scene._choose_depot()
	scene._next_day()
	assert(scene.van==base.access,"Next day preserves chosen depot")
	scene._toggle_drive()
	scene._choose_depot()
	assert(not scene.placing_depot,"Cannot teleport depot during a run")
	scene._clear()
	assert(scene.city.depot==base.access and scene.van==base.access)
	print("Route/UI integration and depot placement: PASS")
	quit()
