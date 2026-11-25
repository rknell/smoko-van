extends RefCounted
## Pure city/simulation model. No scene nodes per worker, no money or inventory.
const STEP = 60.0
const BLOCK = 240.0
const COLS = 18
const ROWS = 14
const FIRST = ["Alex", "Sam", "Charlie", "Morgan", "Jamie", "Riley", "Ash", "Taylor", "Billie", "Jordan", "Casey", "Drew", "Lee", "Frankie", "Pat", "Jess"]
const LAST = ["Kelly", "Nguyen", "Singh", "Wilson", "Brown", "Chen", "Williams", "Jones", "Patel", "Smith", "Martin", "Ryan"]
const DRINKS = ["Flat white", "Long black", "Tea", "Iced coffee"]
const PERIODS = [
	{"name":"Early morning", "start":360, "end":540},
	{"name":"Morning", "start":540, "end":660},
	{"name":"Lunch", "start":660, "end":840},
	{"name":"Afternoon", "start":840, "end":1080}
]
var depot = Vector2.ZERO
const MEALS = ["Meat pie", "Salad wrap", "Toastie", "Veggie roll"]
const INDUSTRIES = [
	{"name":"Engineering", "sprite":0, "mix":[0,7,12]},
	{"name":"Freight", "sprite":1, "mix":[1,0,3]},
	{"name":"Timber", "sprite":2, "mix":[2,0,14]},
	{"name":"Auto Works", "sprite":3, "mix":[3,0,14]},
	{"name":"Food Works", "sprite":4, "mix":[4,1,15]},
	{"name":"Recycling", "sprite":5, "mix":[5,0,1]},
	{"name":"Electronics", "sprite":6, "mix":[6,0,12]},
	{"name":"Foundry", "sprite":7, "mix":[7,0,5]},
	{"name":"Brewing", "sprite":15, "mix":[15,4,1]}
]
const BUILDINGS = ["Engineering", "Freight", "Timber", "Auto Works", "Bakery", "Recycling", "Electronics", "Foundry", "Offices", "Medical", "Market", "Design Studio", "Print House", "Accountants", "Hardware", "Brewery"]
var roads: Array = []
var dead_ends: Array = []
var precincts: Array = []
var industrial_blocks: Dictionary = {}
var properties: Array = []
var workers: Array = []
var parks: Array = []
var graph = AStar2D.new()
var city_seed: int
var total_orders = 0
var clock = 450.0
var day = 1
var width = COLS * BLOCK
var height = ROWS * BLOCK

func generate(seed_value: int) -> void:
	depot = Vector2.ZERO
	city_seed = seed_value
	precincts.clear()
	industrial_blocks.clear()
	properties.clear()
	workers.clear()
	parks.clear()
	graph.clear()
	clock = 450.0
	day = 1
	total_orders = 0
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	_generate_roads(rng)
	# Nine separated 3x3-ish industrial islands, with commercial streets between.
	# Shuffle their specialisms with this city's RNG, never the global RNG.
	var themes = range(INDUSTRIES.size())
	for i in range(themes.size()-1,0,-1):
		var other = rng.randi_range(0,i)
		var swap = themes[i]
		themes[i] = themes[other]
		themes[other] = swap
	for row in range(3):
		for col in range(3):
			var anchor = Vector2i(2+col*6+rng.randi_range(0,1),[2,7,11][row])
			var theme_id = themes[row*3+col]
			var district = {"id":precincts.size(), "name":["Gumtree", "Banksia", "Ironbark", "Wattle", "Cockatoo", "Bottlebrush", "Kookaburra", "Redgum", "Possum"][row*3+col]+" "+INDUSTRIES[theme_id].name+" Park", "theme":theme_id, "centre":(Vector2(anchor)+Vector2(0.5,0.5))*BLOCK, "blocks":[]}
			for dy in range(-1,2):
				for dx in range(-1,2):
					if abs(dx)+abs(dy)==2 and rng.randf()<0.3: continue
					var block = anchor+Vector2i(dx,dy)
					industrial_blocks[block] = district.id
					district.blocks.append(block)
			precincts.append(district)
	for by in range(ROWS):
		for bx in range(COLS):
			var origin = Vector2(bx,by) * BLOCK
			if not industrial_blocks.has(Vector2i(bx,by)) and rng.randf() < 0.10:
				parks.append(Rect2(origin+Vector2(24,24),Vector2(192,192)))
				continue
			var district_id = industrial_blocks.get(Vector2i(bx,by),-1)
			var industrial = district_id>=0
			for q in range(4):
				var px = q % 2
				var py = q / 2
				var rect = Rect2(origin+Vector2(28+px*100,28+py*100),Vector2(84,84))
				var choices = [origin+Vector2(60+px*120,0 if py==0 else BLOCK), origin+Vector2(0 if px==0 else BLOCK,60+py*120)]
				var access = Vector2.INF
				for candidate in choices:
					if road_point(candidate).is_equal_approx(candidate):
						access = candidate
						break
				# No road on either frontage: leave this corner as open green space.
				if access==Vector2.INF: continue
				var sprite = [8,9,10,11,12,13,14][rng.randi_range(0,6)]
				if industrial:
					var industry = INDUSTRIES[precincts[district_id].theme]
					sprite = industry.sprite if rng.randf()<0.75 else industry.mix[rng.randi_range(0,industry.mix.size()-1)]
				var name = ["Wattle", "Banksia", "Ironbark", "River", "Coastal", "Southern"][rng.randi_range(0,5)] + " " + BUILDINGS[sprite]
				var p = {"id":properties.size(), "name":name, "zone":"Industrial" if industrial else "Commercial", "precinct":district_id, "sprite":sprite, "rect":rect, "access":access, "staff":[], "style":rng.randi_range(0,3), "orders":0}
				p["customer"] = rng.randf() >= 0.28
				var count = rng.randi_range(12,36) if industrial else rng.randi_range(5,22)
				for j in range(count):
					var start = rng.randi_range(360,420) if industrial else rng.randi_range(480,540)
					var worker = {"id":workers.size(), "name":FIRST[rng.randi_range(0,15)]+" "+LAST[rng.randi_range(0,11)], "property":p.id, "start":start, "end":start+480, "coffee_break":start+rng.randi_range(50,110), "lunch":start+rng.randi_range(210,270), "drink":DRINKS[rng.randi_range(0,3)], "meal":MEALS[rng.randi_range(0,3)], "last_drink":-9999.0, "last_meal":-9999.0, "orders":0}
					worker["drink_periods"] = []
					worker["meal_periods"] = []
					worker["served_drinks"] = []
					worker["served_meals"] = []
					for period in range(4):
						# Broad windows: staff available during any part of the period
						# can be served throughout it; no minute-perfect appointments.
						var available = start < PERIODS[period].end and worker.end > PERIODS[period].start
						if p.customer and available:
							if rng.randf() < [0.75,0.85,0.4,0.6][period]: worker.drink_periods.append(period)
							if rng.randf() < [0.15,0.2,0.9,0.25][period]: worker.meal_periods.append(period)
					p.staff.append(worker.id)
					workers.append(worker)
				properties.append(p)
	_prepare_day()

func _generate_roads(rng: RandomNumberGenerator) -> void:
	roads.clear()
	dead_ends.clear()
	var junctions = AStar2D.new()
	for y in range(ROWS+1):
		for x in range(COLS+1):
			junctions.add_point(y*(COLS+1)+x,Vector2(x,y)*BLOCK)
	# Randomised depth-first spanning tree guarantees a connected city.
	var visited = {0:true}
	var stack = [0]
	while not stack.is_empty():
		var current = stack[-1]
		var x = current%(COLS+1)
		var y = current/(COLS+1)
		var neighbours = []
		for offset in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]:
			var next = Vector2i(x,y)+offset
			var id = next.y*(COLS+1)+next.x
			if next.x>=0 and next.x<=COLS and next.y>=0 and next.y<=ROWS and not visited.has(id): neighbours.append(id)
		if neighbours.is_empty():
			stack.pop_back()
		else:
			var next = neighbours[rng.randi_range(0,neighbours.size()-1)]
			junctions.connect_points(current,next)
			visited[next]=true
			stack.append(next)
	# Extra links create alternative routes, without restoring a perfect lattice.
	for id in junctions.get_point_ids():
		var x = id%(COLS+1)
		var y = id/(COLS+1)
		for offset in [Vector2i(1,0),Vector2i(0,1)]:
			var next = Vector2i(x,y)+offset
			var other = next.y*(COLS+1)+next.x
			if next.x<=COLS and next.y<=ROWS and not junctions.are_points_connected(id,other) and rng.randf()<0.32:
				junctions.connect_points(id,other)
	# Every block keeps at least one frontage. This never removes connectivity.
	for y in range(ROWS):
		for x in range(COLS):
			var nw = y*(COLS+1)+x
			var borders = [[nw,nw+1],[nw,nw+COLS+1],[nw+1,nw+COLS+2],[nw+COLS+1,nw+COLS+2]]
			var accessible = false
			for edge in borders:
				if junctions.are_points_connected(edge[0],edge[1]): accessible=true
			if not accessible:
				var edge = borders[rng.randi_range(0,3)]
				junctions.connect_points(edge[0],edge[1])
	# Keep a visible set of cul-de-sacs even when the extra loops joined most leaves.
	var candidates = Array(junctions.get_point_ids())
	for i in range(candidates.size()-1,0,-1):
		var j = rng.randi_range(0,i)
		var swap = candidates[i]
		candidates[i]=candidates[j]
		candidates[j]=swap
	var dead_count = 0
	for id in candidates:
		if junctions.get_point_connections(id).size()==1: dead_count+=1
	for id in candidates:
		if dead_count>=12: break
		if junctions.get_point_connections(id).size()!=2: continue
		for other in junctions.get_point_connections(id):
			junctions.disconnect_points(id,other)
			if junctions.get_id_path(id,other).is_empty() or not _all_blocks_have_frontage(junctions):
				junctions.connect_points(id,other)
			else:
				dead_count+=1
				if junctions.get_point_connections(other).size()==1: dead_count+=1
				break
	# Expand each retained street into the fine graph used by vehicles and stops.
	for id in junctions.get_point_ids():
		var from = junctions.get_point_position(id)
		if junctions.get_point_connections(id).size()==1: dead_ends.append(from)
		for other in junctions.get_point_connections(id):
			if other<id: continue
			var to = junctions.get_point_position(other)
			roads.append([from,to])
			var previous = -1
			for segment in range(5):
				var at = from.lerp(to,segment/4.0)
				var fine_id = node_id(roundi(at.x/STEP),roundi(at.y/STEP))
				if not graph.has_point(fine_id): graph.add_point(fine_id,at)
				if previous>=0: graph.connect_points(previous,fine_id)
				previous=fine_id

func _all_blocks_have_frontage(junctions: AStar2D) -> bool:
	for y in range(ROWS):
		for x in range(COLS):
			var nw = y*(COLS+1)+x
			if not (junctions.are_points_connected(nw,nw+1) or junctions.are_points_connected(nw,nw+COLS+1) or junctions.are_points_connected(nw+1,nw+COLS+2) or junctions.are_points_connected(nw+COLS+1,nw+COLS+2)): return false
	return true

func node_id(x: int,y: int) -> int:
	return y * (COLS*4+1) + x

func road_point(point: Vector2) -> Vector2:
	return graph.get_point_position(graph.get_closest_point(point))

func path(from: Vector2,to: Vector2) -> PackedVector2Array:
	return graph.get_point_path(graph.get_closest_point(from),graph.get_closest_point(to))

func property_at(point: Vector2) -> int:
	for p in properties:
		if p.rect.has_point(point): return p.id
	return -1

func period_at(at: float) -> int:
	for i in range(PERIODS.size()):
		if at >= PERIODS[i].start and at < PERIODS[i].end: return i
	return -1

func _prepare_day() -> void:
	# Daily turnout varies, but this seed/day always gives the same outcome.
	var rng = RandomNumberGenerator.new()
	rng.seed = city_seed * 1000003 + day * 7919
	for p in properties:
		p["turnout"] = rng.randf_range(0.70,1.0)
	for w in workers:
		w["today_drinks"] = []
		w["today_meals"] = []
		# A small timing buffer; periods remain distinct for route planning.
		w["boundaries"] = [360,540+rng.randi_range(-8,8),660+rng.randi_range(-8,8),840+rng.randi_range(-8,8),1080]
		for period in w.drink_periods:
			if rng.randf()<properties[w.property].turnout: w.today_drinks.append(period)
		for period in w.meal_periods:
			if rng.randf()<properties[w.property].turnout: w.today_meals.append(period)

func worker_period(w: Dictionary, at: float) -> int:
	for i in range(4):
		if at>=w.boundaries[i] and at<w.boundaries[i+1]: return i
	return -1

func wants(w: Dictionary, at: float) -> Array:
	var result: Array = []
	var period = worker_period(w,at)
	if period < 0: return result
	if period in w.today_drinks and not period in w.served_drinks: result.append(w.drink)
	if period in w.today_meals and not period in w.served_meals: result.append(w.meal)
	return result

func demand(property_id: int, at: float = -1) -> Dictionary:
	var result = {}
	for id in properties[property_id].staff:
		for item in wants(workers[id],clock if at<0 else at): result[item] = result.get(item,0)+1
	return result

func demand_summary(property_id: int, period: int) -> Vector2i:
	var result = Vector2i.ZERO
	if period<0: return result
	for id in properties[property_id].staff:
		var w = workers[id]
		if period in w.drink_periods and not period in w.served_drinks: result.x += 1
		if period in w.meal_periods and not period in w.served_meals: result.y += 1
	return result

func serve(property_id: int) -> Dictionary:
	var result = {}
	for id in properties[property_id].staff:
		var w = workers[id]
		for item in wants(w,clock):
			result[item] = result.get(item,0)+1
			if item in DRINKS: w.served_drinks.append(worker_period(w,clock))
			else: w.served_meals.append(worker_period(w,clock))
			w.orders += 1
			total_orders += 1
			properties[property_id].orders += 1
	return result

func next_day() -> void:
	day += 1
	clock = 450.0
	total_orders = 0
	for p in properties: p.orders = 0
	for w in workers:
		w.last_drink = -9999.0
		w.last_meal = -9999.0
		w.served_drinks.clear()
		w.served_meals.clear()
		w.orders = 0
	_prepare_day()
