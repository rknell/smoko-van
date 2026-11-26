extends Control
const City = preload("res://scripts/city.gd")
const BUILDING_ATLAS = preload("res://assets/buildings-atlas.png")
const DRINK_ICON = preload("res://assets/drink.svg")
const FOOD_ICON = preload("res://assets/food.svg")
const VAN_SPRITE = preload("res://assets/coffee-van.png")
const DEFAULT_CITY_SEED = 1987
const STOP_MARKER_RADIUS = 11.0
const CRUISE_SPEED = 150.0
const TURN_SPEED = 65.0
const DRIVEWAY_SPEED = 43.0
const ACCELERATION = 150.0
const BRAKING = 250.0
const CORNER_RADIUS = 20.0
const DRIVE_STEP = 1.0/60.0
const GAME_MINUTES_PER_SECOND = 2.0
const SERVICE_SECONDS = 4.0
const CLOSING_TIME = 1080.0
const ARRIVAL_TOLERANCE = 0.05
var placing_depot = false
var depot_button: Button
var header_row: HBoxContainer
var status_row: HBoxContainer
var period_picker: OptionButton
var demand_badges = []
var city = City.new()
var zoom = 0.3
var centre = Vector2(2160,1680)
var map_rect = Rect2()
var selected = -1
var stops: Array = []
var legs: Array = []
var driving_paths: Array[Curve2D] = []
var arrival_times = PackedFloat64Array()
var van = Vector2.ZERO
var van_heading = 0.0
var van_speed = 0.0
var travelling = false
var started = false
var leg_index = 0
var leg_progress = 0.0
var dwell = 0.0
var distance = 0.0
var route_mode = true
var drag_start = Vector2.ZERO
var drag_button = MOUSE_BUTTON_NONE
var moved = false
var speed = 1.0
var refresh = 0.0
var message = "Tap properties to add stops. Tap streets for waypoints."
var header: PanelContainer
var sidebar: PanelContainer
var title: Label
var status: Label
var info: RichTextLabel
var route_info: RichTextLabel
var run_button: Button
var mode_button: Button
var route_box: VBoxContainer
var touch_points = {}
var touch_gesture = false
var touch_start = Vector2.ZERO
var touch_moved = false
var last_narrow = false
var narrow = false
var mobile_layout = OS.has_feature("android") or OS.has_feature("ios")
var van_button: Button
var ui_font = ThemeDB.fallback_font

func _ready() -> void:
	if mobile_layout:
		# Logical UI size keeps touch targets readable on high-density phone screens.
		get_window().content_scale_size = Vector2i(800,400)
		get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme_new = Theme.new()
	theme_new.default_font_size = 18 if mobile_layout else 16
	var style = StyleBoxFlat.new()
	style.bg_color = Color("172b30")
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	theme_new.set_stylebox("normal","Button",style)
	var hover = style.duplicate()
	hover.bg_color = Color("31545a")
	theme_new.set_stylebox("hover","Button",hover)
	theme_new.set_stylebox("pressed","Button",hover)
	theme_new.set_color("font_color","Button",Color("e9eacb"))
	theme = theme_new
	_build_ui()
	city.generate(DEFAULT_CITY_SEED)
	van = city.depot
	_layout()
	if mobile_layout: _focus_van()
	else: _fit()
	_update_ui()
	resized.connect(_layout)

func _panel() -> PanelContainer:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("101f25")
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel",style)
	add_child(panel)
	return panel

func _button(text: String, callback: Callable, parent: Node) -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(52,52) if mobile_layout else Vector2(44,44)
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func _build_ui() -> void:
	header = _panel()
	var top = VBoxContainer.new()
	header.add_child(top)
	title = Label.new()
	title.text = "SMOKO / CITY LAB    ·    CITY + PEOPLE + ROUTES"
	title.add_theme_color_override("font_color",Color("efc56b"))
	top.add_child(title)
	var row = HBoxContainer.new()
	header_row = row
	top.add_child(row)
	_button("New map",_generate,row)
	_button("Fit",_fit,row)
	_button("−",func(): _zoom_at(0.8,map_rect.get_center()),row)
	_button("+",func(): _zoom_at(1.25,map_rect.get_center()),row)
	van_button = _button("Van",_focus_van,row)
	depot_button = _button("Depot",_choose_depot,row)
	status = Label.new()
	status.add_theme_font_size_override("font_size",16 if mobile_layout else 13)
	status_row = HBoxContainer.new()
	top.add_child(status_row)
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_row.add_child(status)
	period_picker = OptionButton.new()
	period_picker.add_item("Demand: now")
	for period in City.PERIODS: period_picker.add_item(period.name)
	period_picker.item_selected.connect(func(_index): _update_ui(); queue_redraw())
	period_picker.custom_minimum_size.y = 52 if mobile_layout else 44
	header_row.add_child(period_picker)
	sidebar = _panel()
	route_box = VBoxContainer.new()
	sidebar.add_child(route_box)
	var controls = HBoxContainer.new()
	route_box.add_child(controls)
	mode_button = _button("Route",func(): route_mode=not route_mode; _update_ui(),controls)
	run_button = _button("Drive",_toggle_drive,controls)
	_button("1×",func(): speed=4.0 if speed==1 else 1.0; controls.get_child(2).text="4×" if speed==4 else "1×",controls)
	var edit = HBoxContainer.new()
	route_box.add_child(edit)
	_button("Undo",_undo,edit)
	_button("Clear",_clear,edit)
	_button("Next day",_next_day,edit)
	route_info = RichTextLabel.new()
	route_info.bbcode_enabled = true
	route_info.custom_minimum_size.y = 90
	route_info.add_theme_font_size_override("normal_font_size",18 if mobile_layout else 14)
	route_box.add_child(route_info)
	var rule = HSeparator.new()
	route_box.add_child(rule)
	info = RichTextLabel.new()
	info.bbcode_enabled = true
	info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info.custom_minimum_size.y = 100
	info.add_theme_font_size_override("normal_font_size",16 if mobile_layout else 14)
	info.add_theme_font_size_override("bold_font_size",16 if mobile_layout else 16)
	route_box.add_child(info)

func _layout() -> void:
	if not is_instance_valid(header): return
	narrow = size.x < 680
	header.position = Vector2.ZERO
	var header_height = 96 if mobile_layout or (size.x>=680 and size.y<600) else 126
	title.visible = header_height==126
	van_button.visible = not narrow and not mobile_layout
	var picker_parent = status_row if narrow else header_row
	if period_picker.get_parent()!=picker_parent: period_picker.reparent(picker_parent)
	if narrow: title.visible=false
	header.size = Vector2(size.x,header_height)
	if narrow:
		title.text = "SMOKO / CITY LAB"
		sidebar.position = Vector2(0,maxf(280,size.y-310))
		sidebar.size = Vector2(size.x,310)
		map_rect = Rect2(0,126,size.x,maxf(154,size.y-436))
		route_info.custom_minimum_size.y = 60
	else:
		title.text = "SMOKO / CITY LAB    ·    CITY + PEOPLE + ROUTES"
		var panel_width = 300 if mobile_layout else 330
		sidebar.position = Vector2(size.x-panel_width,header_height)
		sidebar.size = Vector2(panel_width,size.y-header_height)
		map_rect = Rect2(0,header_height,size.x-panel_width,size.y-header_height)
		route_info.custom_minimum_size.y = 48 if size.y < 600 else 120
		info.custom_minimum_size.y = 70 if size.y < 600 else 100
	queue_redraw()

func _fit() -> void:
	centre = Vector2(city.width,city.height)/2
	zoom = clampf(minf((map_rect.size.x-64)/city.width,(map_rect.size.y-100)/city.height),0.035,2.5)
	queue_redraw()

func _focus_van() -> void:
	zoom = maxf(zoom,0.65)
	centre = van
	if van==Vector2.ZERO:
		centre = map_rect.size/(2*zoom)-Vector2(55,55)/zoom
	queue_redraw()

func screen(point: Vector2) -> Vector2:
	return map_rect.get_center() + (point-centre)*zoom

func world(point: Vector2) -> Vector2:
	return centre + (point-map_rect.get_center())/zoom

func _zoom_at(factor: float, at: Vector2) -> void:
	var before = world(at)
	zoom = clampf(zoom*factor,0.035,2.5)
	centre += before-world(at)
	queue_redraw()

func _generate() -> void:
	city.generate(randi())
	selected = -1
	_clear()
	if mobile_layout: _focus_van()
	else: _fit()

func _choose_depot() -> void:
	if started:
		message = "Start the next day or clear the run to move your depot."
	else:
		placing_depot = not placing_depot
		message = "Tap a building or road for your depot. Tap Cancel to keep it." if placing_depot else "Depot unchanged."
	_update_ui()

func _clear() -> void:
	placing_depot = false
	stops.clear()
	legs.clear()
	driving_paths.clear()
	arrival_times.clear()
	van = city.depot
	van_speed = 0.0
	van_heading = 0.0
	travelling = false
	started = false
	dwell = 0
	leg_index = 0
	leg_progress = 0.0
	distance = 0
	message = "Route cleared. Tap a property or road to begin."
	_update_ui()
	queue_redraw()

func _undo() -> void:
	if started:
		message = "Clear the run or start the next day before editing."
	elif not stops.is_empty():
		stops.pop_back()
		_rebuild()
	_update_ui()

func _remove_stop_at(at: Vector2) -> void:
	if started or placing_depot: return
	var property_id = city.property_at(world(at))
	var closest = -1
	var closest_distance = STOP_MARKER_RADIUS
	for i in range(stops.size()-1,-1,-1):
		if property_id>=0 and stops[i].property==property_id:
			closest = i
			break
		var marker_distance = at.distance_to(screen(legs[i][-1]))
		if marker_distance<=STOP_MARKER_RADIUS and (closest<0 or marker_distance<closest_distance):
			closest = i
			closest_distance = marker_distance
	if closest<0: return
	stops.remove_at(closest)
	message = "Stop %d removed." % (closest+1)
	_rebuild()
	_update_ui()

func _entrance(property: Dictionary) -> Vector2:
	var middle = property.rect.get_center()
	var driveway = property.access-middle
	var inner_half_size = property.rect.size/2-Vector2(10,10)
	var edge = maxf(absf(driveway.x)/inner_half_size.x,absf(driveway.y)/inner_half_size.y)
	return middle+driveway/edge

func _rebuild() -> void:
	legs.clear()
	driving_paths.clear()
	var previous = city.depot
	var parked_at = previous
	distance = 0
	for stop in stops:
		var points = city.path(previous,stop.point)
		if parked_at!=previous: points.insert(0,parked_at)
		parked_at = _entrance(city.properties[stop.property]) if stop.property>=0 else stop.point
		if parked_at!=stop.point: points.append(parked_at)
		legs.append(points)
		var path = _rounded_path(points)
		driving_paths.append(path)
		distance += path.get_baked_length()
		previous = stop.point
	_estimate_arrivals()
	queue_redraw()

func _rounded_path(points: PackedVector2Array) -> Curve2D:
	var path = Curve2D.new()
	path.bake_interval = 4.0
	path.add_point(points[0])
	for i in range(1,points.size()-1):
		var corner = points[i]
		var incoming = corner-points[i-1]
		var outgoing = points[i+1]-corner
		var alignment = incoming.normalized().dot(outgoing.normalized())
		if alignment>0.999: continue
		if alignment< -0.98:
			path.add_point(corner)
			continue
		var radius = minf(CORNER_RADIUS,minf(incoming.length(),outgoing.length())*0.45)
		var entry = corner-incoming.normalized()*radius
		var exit = corner+outgoing.normalized()*radius
		# Control handles reproduce a quadratic arc through the street junction.
		path.add_point(entry,Vector2.ZERO,(corner-entry)*2.0/3.0)
		path.add_point(exit,(corner-exit)*2.0/3.0)
	if points.size()>1: path.add_point(points[-1])
	return path

func _toggle_drive() -> void:
	if placing_depot:
		message = "Place your depot or tap Cancel before driving."
		_update_ui()
		return
	if city.clock >= CLOSING_TIME:
		message = "Day finished. Start the next day to drive again."
	elif stops.is_empty():
		message = "Add a property or road waypoint first."
	elif leg_index >= legs.size():
		message = "Run complete. Next day repeats this route; Clear starts a new route."
	else:
		travelling = not travelling
		started = true
		message = "Following roads. Free service at each property." if travelling else "Paused. Tap a property to see demand."
	_update_ui()

func _next_day() -> void:
	placing_depot = false
	city.next_day()
	van = city.depot
	van_speed = 0.0
	van_heading = 0.0
	travelling = false
	started = false
	leg_index = 0
	leg_progress = 0.0
	dwell = 0
	message = "New day. Same people and route; fresh appetites."
	_estimate_arrivals()
	_update_ui()
	queue_redraw()

# Handle captured fingers before GUI dispatch so releasing over a panel cannot
# leave a stuck gesture. Mouse-emulated touch events are ignored by the map.
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if not map_rect.has_point(event.position): return
			if touch_points.is_empty():
				touch_start = event.position
				touch_moved = false
				touch_gesture = false
			touch_points[event.index] = event.position
			if touch_points.size()>1: touch_gesture = true
		elif touch_points.has(event.index):
			touch_points.erase(event.index)
			if touch_points.is_empty() and not touch_moved and not touch_gesture and map_rect.has_point(event.position):
				_tap(world(event.position))
		else: return
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and touch_points.has(event.index):
		var before = touch_points.values()
		var previous = touch_points[event.index]
		touch_points[event.index] = event.position
		if touch_points.size()==2:
			var after = touch_points.values()
			var old_mid = (before[0]+before[1])*0.5
			var new_mid = (after[0]+after[1])*0.5
			var old_span = before[0].distance_to(before[1])
			if old_span>1:
				_zoom_at(after[0].distance_to(after[1])/old_span,old_mid)
				centre += (old_mid-new_mid)/zoom
		elif touch_points.size()==1:
			if event.position.distance_to(touch_start)>7: touch_moved=true
			if touch_moved or touch_gesture: centre -= (event.position-previous)/zoom
		queue_redraw()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.device == -1: return
	if event is InputEventMagnifyGesture and map_rect.has_point(event.position):
		_zoom_at(event.factor,event.position)
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP and map_rect.has_point(event.position): _zoom_at(1.15,event.position)
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN and map_rect.has_point(event.position): _zoom_at(1/1.15,event.position)
		if event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_MIDDLE,MOUSE_BUTTON_RIGHT]:
			if event.pressed and drag_button==MOUSE_BUTTON_NONE and map_rect.has_point(event.position):
				drag_button=event.button_index
				moved=false
				drag_start=event.position
			elif not event.pressed and event.button_index==drag_button:
				drag_button=MOUSE_BUTTON_NONE
				if not moved and map_rect.has_point(event.position):
					if event.button_index==MOUSE_BUTTON_LEFT: _tap(world(event.position))
					elif event.button_index==MOUSE_BUTTON_RIGHT: _remove_stop_at(event.position)
	if event is InputEventMouseMotion and drag_button!=MOUSE_BUTTON_NONE and touch_points.size()<2:
		if event.position.distance_to(drag_start)>7: moved=true
		if moved:
			centre-=event.relative/zoom
			queue_redraw()

func _tap(point: Vector2) -> void:
	if point.x < -30 or point.y < -30 or point.x > city.width+30 or point.y > city.height+30: return
	selected = city.property_at(point)
	if placing_depot:
		var access = city.properties[selected].access if selected>=0 else city.road_point(point)
		if selected<0 and access.distance_to(point)>32:
			message = "Place the depot beside a building or on a road."
		else:
			city.depot = access
			van = access
			placing_depot = false
			_rebuild()
			message = "Depot placed. Your route starts here."
		_update_ui()
		queue_redraw()
		return
	if route_mode and not started:
		var target = city.properties[selected].access if selected>=0 else city.road_point(point)
		if selected<0 and target.distance_to(point)>32:
			message = "Tap a building or street. Drag to explore; + to zoom."
		elif stops.size()>=64:
			message = "64 stops is the prototype route limit."
		else:
			stops.append({"point":target,"property":selected})
			message = "Stop %d added. Drag to explore, tap to extend." % stops.size()
			_rebuild()
			_update_ui(true)
			return
	_update_ui()
	queue_redraw()

func _process(delta: float) -> void:
	if travelling:
		var dt = minf(delta,0.1)*speed
		while dt>0.0001 and travelling:
			var step = minf(dt,DRIVE_STEP)
			dt-=step
			_drive_step(step)
		queue_redraw()
	refresh+=delta
	if refresh>=0.5:
		refresh=0
		_update_ui()

func _path_heading(path: Curve2D, at: float) -> float:
	return (path.sample_baked(at+3.0)-path.sample_baked(at-3.0)).angle()

func _drive_speed(index: int, progress: float, current_speed: float, dt: float) -> float:
	var path = driving_paths[index]
	var length = path.get_baked_length()
	var remaining = length-progress
	var ahead = _path_heading(path,minf(progress+32.0,length))
	var turn = absf(angle_difference(_path_heading(path,maxf(progress-12.0,0.0)),ahead))
	var target = lerpf(CRUISE_SPEED,TURN_SPEED,minf(1.0,turn/(PI*0.5)))
	var property_id = stops[index].property
	var arrival_speed = 0.0
	if index+1<driving_paths.size() and property_id<0:
		var exit_heading = _path_heading(driving_paths[index+1],0.0)
		var waypoint_turn = absf(angle_difference(_path_heading(path,length),exit_heading))
		arrival_speed = lerpf(CRUISE_SPEED,TURN_SPEED,minf(1.0,waypoint_turn/(PI*0.5)))
	target = minf(target,sqrt(arrival_speed*arrival_speed+2.0*BRAKING*remaining))
	if property_id>=0:
		var driveway_length = legs[index][-1].distance_to(legs[index][-2])
		var approach = maxf(0.0,remaining-driveway_length-CORNER_RADIUS*0.5)
		target = minf(target,sqrt(DRIVEWAY_SPEED*DRIVEWAY_SPEED+2.0*BRAKING*approach))
	if progress<_departure_driveway_length(index):
		target = minf(target,DRIVEWAY_SPEED)
	return move_toward(current_speed,target,(ACCELERATION if target>current_speed else BRAKING)*dt)

func _departure_driveway_length(index: int) -> float:
	if index==0 or stops[index-1].property<0: return 0.0
	return legs[index][0].distance_to(legs[index][1])

func _estimate_arrivals() -> void:
	arrival_times.resize(stops.size())
	arrival_times.fill(CLOSING_TIME)
	var clock = city.clock
	var current_speed = 0.0
	for index in range(stops.size()):
		var progress = 0.0
		var length = driving_paths[index].get_baked_length()
		while true:
			clock += DRIVE_STEP*GAME_MINUTES_PER_SECOND
			if clock>=CLOSING_TIME: return
			if length-progress>ARRIVAL_TOLERANCE:
				var next_speed = _drive_speed(index,progress,current_speed,DRIVE_STEP)
				progress = minf(length,progress+(current_speed+next_speed)*0.5*DRIVE_STEP)
				current_speed = next_speed
			if length-progress<=ARRIVAL_TOLERANCE: break
		arrival_times[index] = clock
		if stops[index].property>=0:
			current_speed = 0.0
			clock += SERVICE_SECONDS*GAME_MINUTES_PER_SECOND

func _drive_step(dt: float) -> void:
	city.clock += dt*GAME_MINUTES_PER_SECOND
	if city.clock>=CLOSING_TIME:
		travelling = false
		van_speed = 0.0
		message = "18:00 · Day finished. Next day resets appetites and keeps your route."
		return
	if dwell>0:
		dwell -= dt
		return
	var path = driving_paths[leg_index]
	var path_length = path.get_baked_length()
	var property_id = stops[leg_index].property
	var last_stop = leg_index+1==driving_paths.size()
	if path_length-leg_progress>ARRIVAL_TOLERANCE:
		var backing_out = leg_progress<_departure_driveway_length(leg_index)-8.0
		var previous_speed = van_speed
		van_speed = _drive_speed(leg_index,leg_progress,van_speed,dt)
		if leg_index==0 and leg_progress==0:
			van_heading = _path_heading(path,leg_progress)
		leg_progress = minf(path_length,leg_progress+(previous_speed+van_speed)*0.5*dt)
		van = path.sample_baked(leg_progress)
		var heading = _path_heading(path,leg_progress)+(PI if backing_out else 0.0)
		van_heading = rotate_toward(van_heading,heading,TAU*1.75*dt)
		if path_length-leg_progress>ARRIVAL_TOLERANCE: return
	van = legs[leg_index][-1]
	arrival_times[leg_index] = city.clock
	if property_id>=0:
		var orders = city.serve(property_id)
		message = city.properties[property_id].name+": "+_orders(orders)
		dwell = SERVICE_SECONDS
		van_speed = 0.0
	leg_index += 1
	leg_progress = 0.0
	if last_stop:
		travelling = false
		van_speed = 0.0
		message += " · Route complete."

func _orders(orders: Dictionary) -> String:
	if orders.is_empty(): return "No orders for the current menu."
	var parts = PackedStringArray()
	for key in orders: parts.append("%d %s" % [orders[key],key])
	return ", ".join(parts)

func _time(minutes: float) -> String:
	return "%02d:%02d" % [int(minutes)/60,int(minutes)%60]

func _update_ui(show_latest_stop: bool = false) -> void:
	if not is_instance_valid(status): return
	var current_period = city.period_at(city.clock)
	status.text = "Day %d · %s · %s" % [city.day,_time(city.clock),City.PERIODS[current_period].name if current_period>=0 else "Closed"]
	depot_button.text = "Cancel" if placing_depot else "Depot"
	var shown_period = city.period_at(city.clock) if period_picker.selected==0 else period_picker.selected-1
	demand_badges.clear()
	for property in city.properties:
		var demand = city.demand(property.id) if period_picker.selected==0 else city.demand_forecast(property.id,shown_period)
		var categories = Vector2i.ZERO
		for item in demand:
			if item in City.DRINKS: categories.x = 1
			else: categories.y = 1
		demand_badges.append(categories)
	queue_redraw()
	mode_button.text = "Route ✓" if route_mode else "Inspect"
	run_button.text = "Pause" if travelling else ("Resume" if started and leg_index<legs.size() else "Drive")
	var route_text = "[color=#efc56b]%d STOPS · %.1f km[/color]\n%s" % [stops.size(),distance/1000,message]
	for i in range(stops.size()):
		var p = stops[i].property
		var arrival = arrival_times[i]
		var time_text = "After close" if arrival>=CLOSING_TIME else _time(arrival)
		if i>=leg_index and arrival<CLOSING_TIME: time_text = "≈ "+time_text
		route_text += "\n%d. [color=#efc56b]%s[/color] · %s%s" % [i+1,time_text,city.properties[p].name if p>=0 else "Road waypoint"," ✓" if i<leg_index else ""]
	if route_info.text != route_text:
		var scrollbar = route_info.get_v_scroll_bar()
		var previous_scroll = scrollbar.value
		route_info.text = route_text
		# Lay out the new text before reading the scrollbar's range.
		route_info.get_content_height()
		scrollbar.value = scrollbar.max_value if show_latest_stop else previous_scroll
	if selected<0:
		var instructions = "[b]Serving hot flat whites[/b]\nSelect a business to see what its staff might buy. Use the demand menu to preview another period."
		if info.text != instructions: info.text = instructions
		return
	var p = city.properties[selected]
	var summary = "[color=#efc56b][b]%s[/b][/color] · %d staff\n" % [p.name,p.staff.size()]
	if not p.customer:
		summary += "No van customers here."
	else:
		var forecast = city.demand_forecast(selected,shown_period)
		if forecast.is_empty():
			summary += "No orders expected for the current menu."
		else:
			summary += "%s · est. orders\n" % City.PERIODS[shown_period].name
			for item in p.menu:
				if not forecast.has(item): continue
				var high = forecast[item]
				var low = roundi(high*City.MIN_TURNOUT)
				var estimate = str(high) if low==high else "%d–%d" % [low,high]
				summary += "%s · %s\n" % [item,estimate]
	if info.text != summary: info.text = summary

func _draw() -> void:
	if city.properties.is_empty(): return
	draw_rect(map_rect,Color("53684b"))
	# Give open country a continuous ground colour and break up the built-up edge.
	for y in range(City.ROWS):
		for x in range(City.COLS):
			var block = Vector2i(x,y)
			var ground = Rect2(screen(Vector2(block)*City.BLOCK),Vector2.ONE*City.BLOCK*zoom)
			if not map_rect.intersects(ground): continue
			if city.town_blocks.has(block):
				draw_rect(ground.grow(0.25),Color("658576"))
			else:
				for i in range(6):
					var shift = float(x+y*City.COLS)*0.317+i
					var at = ground.position+Vector2(fposmod(shift*0.618,0.86)+0.07,fposmod(shift*0.409,0.86)+0.07)*ground.size
					draw_circle(at,(4.0+2.0*(i%3))*zoom,Color("647957"),true,-1,true)
	for area in city.undeveloped_areas:
		var field = Rect2(screen(area.position),area.size*zoom)
		if not map_rect.intersects(field): continue
		draw_rect(field,Color("859461"))
		for i in range(24):
			var at = field.position+Vector2(fposmod(0.27+i*0.618,0.90)+0.05,fposmod(0.39+i*0.414,0.90)+0.05)*field.size
			draw_line(at,at+Vector2(12,-8)*zoom,Color("6b7c4f"),maxf(1,4*zoom),true)
	# Round every street endpoint, including corners and T-junctions. Draw
	# junction caps after the road markings so lines do not cross intersections.
	var junctions = {}
	for road in city.roads:
		var a = screen(road[0])
		var b = screen(road[1])
		draw_line(a,b,Color("26393b"),maxf(1,36*zoom))
		if zoom>0.18: draw_line(a,b,Color("667770"),maxf(1,zoom))
		junctions[road[0]] = true
		junctions[road[1]] = true
	for junction in junctions:
		draw_circle(screen(junction),18*zoom,Color("26393b"),true,-1,true)
	for endpoint in city.dead_ends:
		var at = screen(endpoint)
		draw_circle(at,23*zoom,Color("26393b"),true,-1,true)
		if zoom>0.22:
			draw_rect(Rect2(at+Vector2(13,-14)*zoom,Vector2(16,18)*zoom),Color("598db0"))
			draw_line(at+Vector2(21,-11)*zoom,at+Vector2(21,0)*zoom,Color.WHITE,maxf(1,3*zoom))
			draw_line(at+Vector2(16,-11)*zoom,at+Vector2(26,-11)*zoom,Color("f5bba1"),maxf(1,4*zoom))
	for park in city.parks:
		var r = Rect2(screen(park.position),park.size*zoom)
		if not map_rect.intersects(r): continue
		draw_rect(r,Color("527b53"))
		for q in range(9):
			var tree = park.position+Vector2(28+(q%3)*64,28+(q/3)*64)
			draw_circle(screen(tree),14*zoom,Color("325e48"))
	for p in city.properties:
		var r = Rect2(screen(p.rect.position),p.rect.size*zoom)
		if not map_rect.intersects(r): continue
		var base = Color("a2b7a0")
		if p.precinct>=0:
			base = Color.from_hsv(float(city.precincts[p.precinct].theme)/9.0,0.22,0.65)
		draw_rect(r.grow(4*zoom),base)
		# Driveway first; the sprite covers the inner end, not the road.
		draw_line(screen(p.rect.get_center()),screen(p.access),Color("d6caa0"),maxf(1,5*zoom))
		var cell = BUILDING_ATLAS.get_size()/4.0
		var source = Rect2(Vector2(p.sprite%4,p.sprite/4)*cell,cell)
		draw_texture_rect_region(BUILDING_ATLAS,r,source)
		if p.id==selected: draw_rect(r.grow(3),Color("fff0b3"),false,2)
		if zoom>0.25 and p.id<demand_badges.size():
			var amounts = demand_badges[p.id]
			if amounts.x+amounts.y>0:
				var count = int(amounts.x>0)+int(amounts.y>0)
				var badge = Rect2(r.get_center().x-count*10,r.position.y-21,count*20,20)
				draw_style_box(_badge_style(),badge)
				var icon_x = badge.position.x
				if amounts.x>0:
					draw_texture_rect(DRINK_ICON,Rect2(icon_x,badge.position.y,18,18),false)
					icon_x+=20
				if amounts.y>0:
					draw_texture_rect(FOOD_ICON,Rect2(icon_x,badge.position.y,18,18),false)
	for district in city.precincts:
		var at = screen(district.centre-Vector2(120,120))
		if not map_rect.has_point(at): continue
		var words = district.name.split(" ")
		var label = words[0]+" / "+City.INDUSTRIES[district.theme].name
		if zoom<0.2: label = words[0]
		var label_width = ui_font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x+12
		draw_rect(Rect2(at-Vector2(3,14),Vector2(label_width,20)),Color("172b30"))
		draw_string(ui_font,at+Vector2(3,1),label,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("ffdb8a"))
	draw_set_transform(screen(Vector2.ZERO),0.0,Vector2.ONE*zoom)
	for path in driving_paths:
		if path.get_point_count()>1:
			draw_polyline(path.get_baked_points(),Color("f4c45f"),3.0/zoom,true)
	draw_set_transform(Vector2.ZERO)
	for i in range(stops.size()):
		var at = screen(legs[i][-1])
		if not map_rect.has_point(at): continue
		draw_circle(at,STOP_MARKER_RADIUS,Color("f4c45f") if i>=leg_index else Color("80c8b4"))
		draw_string(ui_font,at+Vector2(-5,5),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("192f32"))
	var depot = screen(city.depot)
	draw_rect(Rect2(depot-Vector2(12,12),Vector2(24,24)),Color("e7e5ca"))
	var depot_label_width = ui_font.get_string_size("DEPOT",HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
	var depot_label = depot+Vector2(-depot_label_width*0.5,31)
	draw_rect(Rect2(depot_label-Vector2(4,13),Vector2(depot_label_width+8,17)),Color("172b30"))
	draw_string(ui_font,depot_label,"DEPOT",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("f0edce"))
	var v = screen(van)
	var sprite_length = clampf(64.0*zoom,29.0,65.0)
	var sprite_size = Vector2(sprite_length,sprite_length*0.5)
	draw_set_transform(v+Vector2(2,3),van_heading,Vector2(1,0.5))
	draw_circle(Vector2.ZERO,sprite_length*0.45,Color(0,0,0,0.28),true,-1,true)
	draw_set_transform(v,van_heading)
	draw_texture_rect(VAN_SPRITE,Rect2(-sprite_size*0.5,sprite_size),false)
	draw_set_transform(Vector2.ZERO)
	# Screen-space compass and scale remain legible at city-wide zoom.
	draw_string(ui_font,map_rect.position+Vector2(18,26),"N ↑   /   WATTLE METRO",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("f0edce"))
	draw_string(ui_font,map_rect.end-Vector2(165,16),"%.0f m / 100 px" % (100/zoom),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("f0edce"))


func _badge_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color("172b30")
	style.set_corner_radius_all(5)
	return style
