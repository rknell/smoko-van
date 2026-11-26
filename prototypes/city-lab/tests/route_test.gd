extends SceneTree
func _initialize() -> void:
	call_deferred("run")

func click_at(button: MouseButton, at: Vector2) -> void:
	var click = InputEventMouseButton.new()
	click.button_index = button
	click.position = at
	click.global_position = at
	click.pressed = true
	root.push_input(click,true)
	var release = click.duplicate()
	release.pressed = false
	root.push_input(release,true)

func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.size=Vector2i(1280,800)
	root.add_child(scene)
	await process_frame
	var default_depot = scene.city.depot
	assert(scene.van==default_depot,"Van starts at the central depot")
	scene.size=Vector2(1280,800)
	scene._layout()
	var property = scene.city.properties[0]
	scene._fit()
	click_at(MOUSE_BUTTON_LEFT,scene.screen(property.rect.get_center()))
	await process_frame
	assert(scene.stops.size()==1)
	var first_eta = scene.arrival_times[0]
	assert(first_eta>scene.city.clock and "≈ "+scene._time(first_eta) in scene.route_info.text,"Planned stops show an ETA")
	assert(scene.legs[0][0]==default_depot,"First route starts at the central depot")
	var entrance = scene.legs[0][-1]
	assert(property.rect.has_point(entrance) and scene.legs[0][-2]==property.access,"Van pulls off the street into the business")
	scene._toggle_drive()
	click_at(MOUSE_BUTTON_RIGHT,scene.screen(entrance))
	assert(scene.stops.size()==1,"Right-click cannot edit a run in progress")
	scene._process(0.05)
	assert(scene.van_speed>0.0 and scene.van_speed<scene.CRUISE_SPEED,"Van accelerates from rest")
	var initial_heading = scene.van_heading
	var turned = false
	var slowed_for_driveway = false
	var path = scene.driving_paths[0]
	var raw_length = 0.0
	for point in range(1,scene.legs[0].size()):
		raw_length += scene.legs[0][point-1].distance_to(scene.legs[0][point])
	assert(path.get_baked_length()<raw_length,"Turns round off the original street and driveway corners")
	for i in range(2000):
		if not scene.travelling: break
		scene._process(0.05)
		turned = turned or absf(angle_difference(initial_heading,scene.van_heading))>0.5
		if scene.travelling and path.get_baked_length()-scene.leg_progress<30.0:
			slowed_for_driveway = true
			assert(scene.van_speed<=scene.DRIVEWAY_SPEED,"Van slows before it pulls into the driveway")
	assert(turned and slowed_for_driveway,"Route exercises both steering and driveway braking")
	assert(scene.leg_index==1)
	assert(scene.van==entrance,"Van parks inside the last business")
	assert(scene.van_speed==0.0,"Van comes to rest inside the business")
	assert(not scene.travelling)
	assert(scene.city.clock>450)
	assert(absf(scene.arrival_times[0]-first_eta)<0.1,"Forecast matches the simulated arrival")
	scene._update_ui()
	assert(not "≈" in scene.route_info.text and "✓" in scene.route_info.text,"Visited stops show actual arrival")
	scene._next_day()
	assert(scene.stops.size()==1 and scene.city.day==2)
	assert(scene.van==default_depot and not scene.started)
	assert(is_equal_approx(scene.arrival_times[0],first_eta),"Repeating the route restores its forecast")
	click_at(MOUSE_BUTTON_LEFT,scene.screen(default_depot))
	var other_property = scene.city.properties[20]
	click_at(MOUSE_BUTTON_LEFT,scene.screen(other_property.rect.get_center()))
	assert(scene.stops.size()==3 and scene.stops[1].property==-1)
	assert(scene.arrival_times[1]>=scene.arrival_times[0]+8.0,"Forecast includes service time at earlier businesses")
	var eta_with_waypoint = scene.arrival_times[2]
	assert(scene.legs[1][0]==entrance and scene.legs[1][1]==property.access,"The next leg exits along the driveway")
	assert(scene.legs[1][-1]==default_depot,"Road waypoints stay on the street")
	click_at(MOUSE_BUTTON_RIGHT,scene.screen(default_depot))
	assert(scene.stops.size()==2 and scene.stops[1].property==other_property.id,"Right-click removes a specific waypoint")
	assert(scene.legs.size()==2 and scene.legs[1][0]==entrance,"Removing a waypoint reconnects adjacent stops")
	assert(scene.arrival_times.size()==2 and scene.arrival_times[1]<eta_with_waypoint,"Editing the route refreshes its ETAs")
	click_at(MOUSE_BUTTON_RIGHT,scene.screen(property.rect.get_center()))
	assert(scene.stops.size()==1 and scene.stops[0].property==other_property.id,"Right-click on a building removes its stop")
	assert(scene.legs[0][0]==default_depot,"Removing the first stop reconnects the depot")
	scene.city.clock = scene.CLOSING_TIME-0.1
	scene._estimate_arrivals()
	scene._update_ui()
	assert("After close" in scene.route_info.text,"Stops past closing are marked")
	scene._next_day()
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
	scene.route_mode = false
	scene.period_picker.select(2)
	var coffee_stop = scene.city.properties.filter(func(p):
		return "Hot flat white" in p.menu and p.menu.size()>2 and not scene.city.demand_forecast(p.id,1).is_empty()
	)[0]
	scene._tap(coffee_stop.rect.get_center())
	assert("Morning · est. orders" in scene.info.text and "Hot flat white" in scene.info.text)
	assert("%d staff" % coffee_stop.staff.size() in scene.info.text)
	for item in coffee_stop.menu:
		if item!="Hot flat white": assert(not item in scene.info.text,"Locked items stay hidden in the property panel")
	scene.route_mode = true
	for i in range(12):
		scene._tap(scene.city.depot)
	await process_frame
	var scrollbar = scene.route_info.get_v_scroll_bar()
	assert(scrollbar.value>0 and is_equal_approx(scrollbar.value,scrollbar.max_value-scrollbar.page),"Adding a stop scrolls the ETA list to its end")
	scrollbar.value = 0
	scene.message = "Route ready."
	scene._update_ui()
	assert(is_zero_approx(scrollbar.value),"Routine refresh preserves manual scrolling")
	scene._tap(scene.city.depot)
	assert(scrollbar.value>0 and is_equal_approx(scrollbar.value,scrollbar.max_value-scrollbar.page),"Adding another stop reveals it after manual scrolling")
	print("Route/UI integration and depot placement: PASS")
	quit()
