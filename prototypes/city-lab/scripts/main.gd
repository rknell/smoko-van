extends Control
const City = preload("res://scripts/city.gd")
const BUILDING_ATLAS = preload("res://assets/buildings-atlas.png")
var city = City.new()
var zoom = 0.3
var centre = Vector2(2160,1680)
var map_rect = Rect2()
var selected = -1
var stops: Array = []
var legs: Array = []
var van = Vector2.ZERO
var travelling = false
var started = false
var leg_index = 0
var point_index = 1
var dwell = 0.0
var distance = 0.0
var route_mode = true
var drag_start = Vector2.ZERO
var dragging = false
var moved = false
var speed = 1.0
var refresh = 0.0
var message = "Tap properties to add stops. Tap streets for waypoints."
var header: PanelContainer
var sidebar: PanelContainer
var title: Label
var status: Label
var seed_input: LineEdit
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
	city.generate(1987)
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
	top.add_child(row)
	seed_input = LineEdit.new()
	seed_input.text = "1987"
	seed_input.placeholder_text = "City seed"
	seed_input.custom_minimum_size = Vector2(80,52) if mobile_layout else Vector2(68,44)
	seed_input.tooltip_text = "Same seed recreates the same city and workers."
	row.add_child(seed_input)
	_button("New",_generate,row)
	_button("Shuffle",func(): seed_input.text=str(randi()%999999); _generate(),row)
	_button("Fit",_fit,row)
	_button("−",func(): _zoom_at(0.8,map_rect.get_center()),row)
	_button("+",func(): _zoom_at(1.25,map_rect.get_center()),row)
	van_button = _button("Van",_focus_van,row)
	status = Label.new()
	status.add_theme_font_size_override("font_size",16 if mobile_layout else 13)
	top.add_child(status)
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
	info.add_theme_font_size_override("normal_font_size",18 if mobile_layout else 14)
	route_box.add_child(info)

func _layout() -> void:
	if not is_instance_valid(header): return
	narrow = size.x < 680
	header.position = Vector2.ZERO
	var header_height = 96 if mobile_layout or (size.x>=680 and size.y<600) else 126
	title.visible = header_height==126
	van_button.visible = not narrow
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
		route_info.custom_minimum_size.y = 58 if size.y < 600 else 120
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
	if not seed_input.text.is_valid_int():
		message = "Use a whole number for the city seed."
		_update_ui()
		return
	city.generate(int(seed_input.text))
	selected = -1
	_clear()
	if mobile_layout: _focus_van()
	else: _fit()

func _clear() -> void:
	stops.clear()
	legs.clear()
	van = Vector2.ZERO
	travelling = false
	started = false
	dwell = 0
	leg_index = 0
	point_index = 1
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

func _rebuild() -> void:
	legs.clear()
	var previous = Vector2.ZERO
	distance = 0
	for stop in stops:
		var points = city.path(previous,stop.point)
		legs.append(points)
		for i in range(1,points.size()): distance += points[i-1].distance_to(points[i])
		previous = stop.point
	queue_redraw()

func _toggle_drive() -> void:
	if city.clock >= 1080:
		message = "Day finished. Start the next day to drive again."
	elif stops.is_empty():
		message = "Add a property or road waypoint first."
	elif leg_index >= legs.size():
		message = "Run complete. Next day repeats this route; Clear starts a new route."
	else:
		travelling = not travelling
		started = true
		message = "Following roads. Free service at each property." if travelling else "Paused. Inspect any property or worker."
	_update_ui()

func _next_day() -> void:
	city.next_day()
	van = Vector2.ZERO
	travelling = false
	started = false
	leg_index = 0
	point_index = 1
	dwell = 0
	message = "New day. Same people and route; fresh appetites."
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
			if event.pressed and map_rect.has_point(event.position):
				dragging=true
				moved=false
				drag_start=event.position
			elif not event.pressed and dragging:
				dragging=false
				if not moved and event.button_index==MOUSE_BUTTON_LEFT and map_rect.has_point(event.position): _tap(world(event.position))
	if event is InputEventMouseMotion and dragging and touch_points.size()<2:
		if event.position.distance_to(drag_start)>7: moved=true
		if moved:
			centre-=event.relative/zoom
			queue_redraw()

func _tap(point: Vector2) -> void:
	if point.x < -30 or point.y < -30 or point.x > city.width+30 or point.y > city.height+30: return
	selected = city.property_at(point)
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
	_update_ui()
	queue_redraw()

func _process(delta: float) -> void:
	if travelling:
		var dt = minf(delta,0.1)*speed
		city.clock += dt*2
		if dwell>0:
			dwell-=dt
		else:
			var budget = dt*150
			while budget>0 and leg_index<legs.size():
				var points = legs[leg_index]
				if point_index>=points.size():
					var destination = stops[leg_index]
					if destination.property>=0:
						var orders = city.serve(destination.property)
						message = city.properties[destination.property].name+": "+_orders(orders)
						dwell=4.0
					leg_index+=1
					point_index=1
					break
				var remaining = van.distance_to(points[point_index])
				if remaining<=budget:
					van=points[point_index]
					budget-=remaining
					point_index+=1
				else:
					van=van.move_toward(points[point_index],budget)
					budget=0
			if leg_index>=legs.size():
				travelling=false
				message += " · Route complete."
		if city.clock>=1080:
			travelling=false
			message="18:00 · Day finished. Next day resets appetites and keeps your route."
		queue_redraw()
	refresh+=delta
	if refresh>=0.5:
		refresh=0
		_update_ui()

func _orders(orders: Dictionary) -> String:
	if orders.is_empty(): return "Nobody wants anything right now."
	var parts = PackedStringArray()
	for key in orders: parts.append("%d %s" % [orders[key],key])
	return ", ".join(parts)

func _time(minutes: float) -> String:
	return "%02d:%02d" % [int(minutes)/60,int(minutes)%60]

func _update_ui() -> void:
	if not is_instance_valid(status): return
	status.text = "D%d · %s  |  %d properties · %s workers" % [city.day,_time(city.clock),city.properties.size(),str(city.workers.size())]
	mode_button.text = "Route ✓" if route_mode else "Inspect"
	run_button.text = "Pause" if travelling else ("Resume" if started and leg_index<legs.size() else "Drive")
	var route_text = "[color=#efc56b]%d STOPS · %.1f km · %d free orders[/color]\n%s\n" % [stops.size(),distance/1000,city.total_orders,message]
	for i in range(stops.size()):
		var p = stops[i].property
		route_text += "%d. %s%s\n" % [i+1,city.properties[p].name if p>=0 else "Road waypoint"," ✓" if i<leg_index else ""]
	if route_info.text != route_text: route_info.text = route_text
	if selected<0:
		var instructions = "[b]A city of individual people.[/b]\n\n[color=#72c8bd]■ Commercial[/color]   [color=#d6a16c]■ Industrial[/color]\nNine named industrial precincts, each with its own specialty. Roads have real detours and signed dead ends.\n\nRoute mode: tap buildings or streets.\nInspect mode: tap without adding stops.\nDrag to pan. Scroll / pinch / + − to zoom.\n\nEvery worker has a shift, a break, preferences and their own recent orders. The van supplies requests for free. No money, stock, loyalty or combat.\n\nStart at the north-west depot. Routes follow connected streets. Seed %d recreates this city." % city.city_seed
		if info.text != instructions: info.text = instructions
		return
	var saved_scroll = info.get_v_scroll_bar().value
	var p = city.properties[selected]
	var district_name = city.precincts[p.precinct].name if p.precinct>=0 else "Commercial neighbourhood"
	var people_text = "[color=#efc56b][b]%s[/b][/color]\n%s\n%s · %d staff · %d orders today\n\n[b]Wanted now[/b]\n%s\n\n[b]People · individual schedules[/b]\n" % [p.name,district_name,p.zone,p.staff.size(),p.orders,_orders(city.demand(selected))]
	for id in p.staff:
		var w = city.workers[id]
		var requests = city.wants(w,city.clock)
		people_text += "\n[b]%s #%d[/b]  ·  %s–%s\n%s / %s\nBreak %s · Lunch %s\n[color=#9db6b7]%s · %d orders today[/color]\n" % [w.name,w.id,_time(w.start),_time(w.end),w.drink,w.meal,_time(w.coffee_break),_time(w.lunch),", ".join(requests) if not requests.is_empty() else "Not hungry / off shift",w.orders]

	if info.text != people_text:
		info.text = people_text
		info.get_v_scroll_bar().set_deferred("value",saved_scroll)

func _draw() -> void:
	if city.properties.is_empty(): return
	draw_rect(map_rect,Color("203c3b"))
	# All world rendering is clipped by a drawing child in future; currently cull and
	# draw UI panels above the world so off-map geometry never covers controls.
	var land = Rect2(screen(Vector2(-30,-30)),Vector2(city.width+60,city.height+60)*zoom)
	draw_rect(land,Color("658576"))
	for road in city.roads:
		var a = screen(road[0])
		var b = screen(road[1])
		draw_line(a,b,Color("26393b"),maxf(1,36*zoom))
		if zoom>0.18: draw_line(a,b,Color("667770"),maxf(1,zoom))
	for endpoint in city.dead_ends:
		var at = screen(endpoint)
		draw_circle(at,23*zoom,Color("26393b"))
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
	for district in city.precincts:
		var at = screen(district.centre-Vector2(120,120))
		if not map_rect.has_point(at): continue
		var words = district.name.split(" ")
		var label = words[0]+" / "+City.INDUSTRIES[district.theme].name
		if zoom<0.2: label = words[0]
		var label_width = ui_font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x+12
		draw_rect(Rect2(at-Vector2(3,14),Vector2(label_width,20)),Color("172b30"))
		draw_string(ui_font,at+Vector2(3,1),label,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("ffdb8a"))
	for points in legs:
		if points.size()>1:
			var line = PackedVector2Array()
			for point in points: line.append(screen(point))
			draw_polyline(line,Color("f4c45f"),3,true)
	for i in range(stops.size()):
		var at = screen(stops[i].point)
		if not map_rect.has_point(at): continue
		draw_circle(at,11,Color("f4c45f") if i>=leg_index else Color("80c8b4"))
		draw_string(ui_font,at+Vector2(-5,5),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("192f32"))
	var depot = screen(Vector2.ZERO)
	draw_rect(Rect2(depot-Vector2(12,12),Vector2(24,24)),Color("e7e5ca"))
	draw_string(ui_font,depot+Vector2(16,5),"DEPOT",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("f0edce"))
	var v = screen(van)
	draw_circle(v,13,Color(0,0,0,0.3))
	draw_rect(Rect2(v-Vector2(9,6),Vector2(18,12)),Color("fff2c2"))
	draw_rect(Rect2(v+Vector2(3,-5),Vector2(4,10)),Color("276369"))
	# Screen-space compass and scale remain legible at city-wide zoom.
	draw_string(ui_font,map_rect.position+Vector2(18,26),"N ↑   /   WATTLE METRO",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("f0edce"))
	draw_string(ui_font,map_rect.end-Vector2(165,16),"%.0f m / 100 px" % (100/zoom),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("f0edce"))

