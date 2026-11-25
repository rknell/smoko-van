extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func finger(index: int, position: Vector2, pressed: bool) -> void:
	var event = InputEventScreenTouch.new()
	event.index=index
	event.position=position
	event.pressed=pressed
	root.push_input(event,true)
func drag(index: int, position: Vector2) -> void:
	var event = InputEventScreenDrag.new()
	event.index=index
	event.position=position
	root.push_input(event,true)
func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.size=Vector2i(1280,800)
	root.add_child(scene)
	await process_frame
	scene.size=Vector2(1280,800)
	scene._layout()
	scene._fit()
	var at = scene.map_rect.get_center()
	var original_zoom = scene.zoom
	var original_world = scene.world(at)
	finger(0,at-Vector2(40,0),true)
	finger(1,at+Vector2(40,0),true)
	drag(0,at-Vector2(80,0))
	drag(1,at+Vector2(80,0))
	assert(is_equal_approx(scene.zoom,original_zoom*2),"Pinch should double zoom immediately")
	assert(scene.world(at).distance_to(original_world)<0.01,"Pinch must keep midpoint anchored")
	finger(0,at-Vector2(80,0),false)
	finger(1,at+Vector2(80,0),false)
	assert(scene.stops.is_empty(),"Pinch release must not add route stops")
	var previous_centre=scene.centre
	finger(0,at,true)
	drag(0,at+Vector2(45,30))
	finger(0,at+Vector2(45,30),false)
	assert(scene.centre!=previous_centre and scene.stops.is_empty(),"One finger pans without placing stops")
	finger(0,at,true)
	finger(1,at+Vector2(50,0),true)
	finger(0,Vector2(30,30),false)
	finger(1,Vector2(60,30),false)
	assert(scene.touch_points.is_empty(),"Releasing over UI clears captured fingers")
	scene._fit()
	var property=scene.city.properties[0]
	var point=scene.screen(property.rect.get_center())
	finger(0,point,true)
	finger(0,point,false)
	assert(scene.stops.size()==1,"A single tap still places a stop")
	scene._zoom_at(1000,at)
	assert(scene.zoom==2.5,"Maximum zoom is bounded")
	scene._zoom_at(0.00001,at)
	assert(scene.zoom==0.035,"Minimum zoom is bounded")
	print("Touch: pinch anchoring, pan, UI release, tap and zoom limits PASS")
	quit()
