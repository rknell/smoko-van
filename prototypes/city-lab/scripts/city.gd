extends RefCounted
## Pure city/simulation model. No scene nodes per worker, no money or inventory.
const STEP = 60.0
const BLOCK = 240.0
const COLS = 18
const ROWS = 14
const FIRST = ["Alex", "Sam", "Charlie", "Morgan", "Jamie", "Riley", "Ash", "Taylor", "Billie", "Jordan", "Casey", "Drew", "Lee", "Frankie", "Pat", "Jess"]
const LAST = ["Kelly", "Nguyen", "Singh", "Wilson", "Brown", "Chen", "Williams", "Jones", "Patel", "Smith", "Martin", "Ryan"]
const DRINKS = ["Flat white", "Long black", "Tea", "Iced coffee"]
const MEALS = ["Meat pie", "Salad wrap", "Toastie", "Veggie roll"]
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
	city_seed = seed_value
	properties.clear()
	workers.clear()
	parks.clear()
	graph.clear()
	clock = 450.0
	day = 1
	total_orders = 0
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	for y in range(ROWS * 4 + 1):
		for x in range(COLS * 4 + 1):
			if x % 4 == 0 or y % 4 == 0:
				graph.add_point(node_id(x,y), Vector2(x,y) * STEP)
	for id in graph.get_point_ids():
		var x = id % (COLS * 4 + 1)
		var y = id / (COLS * 4 + 1)
		for delta in [Vector2i(1,0),Vector2i(0,1)]:
			var nx = x + delta.x
			var ny = y + delta.y
			var other = node_id(nx,ny)
			if nx <= COLS*4 and ny <= ROWS*4 and graph.has_point(other):
				graph.connect_points(id,other)
	for by in range(ROWS):
		for bx in range(COLS):
			var origin = Vector2(bx,by) * BLOCK
			if rng.randf() < 0.10:
				parks.append(Rect2(origin+Vector2(24,24),Vector2(192,192)))
				continue
			var industrial = (float(bx)/COLS + float(by)/ROWS * 0.25 + rng.randf_range(-0.25,0.25)) > 0.67
			for q in range(4):
				var px = q % 2
				var py = q / 2
				var rect = Rect2(origin+Vector2(28+px*100,28+py*100),Vector2(84,84))
				var access = origin+Vector2(60+px*120,0 if py==0 else BLOCK)
				var names = ["Engineering", "Freight", "Fabrication", "Timber", "Auto Works"] if industrial else ["Design Studio", "Medical", "Accountants", "Market", "Print House"]
				var name = ["Wattle", "Banksia", "Ironbark", "River", "Coastal", "Southern"][rng.randi_range(0,5)] + " " + names[rng.randi_range(0,4)]
				var p = {"id":properties.size(), "name":name, "zone":"Industrial" if industrial else "Commercial", "rect":rect, "access":access, "staff":[], "style":rng.randi_range(0,3), "orders":0}
				var count = rng.randi_range(12,36) if industrial else rng.randi_range(5,22)
				for j in range(count):
					var start = rng.randi_range(360,420) if industrial else rng.randi_range(480,540)
					var worker = {"id":workers.size(), "name":FIRST[rng.randi_range(0,15)]+" "+LAST[rng.randi_range(0,11)], "property":p.id, "start":start, "end":start+480, "coffee_break":start+rng.randi_range(50,110), "lunch":start+rng.randi_range(210,270), "drink":DRINKS[rng.randi_range(0,3)], "meal":MEALS[rng.randi_range(0,3)], "last_drink":-9999.0, "last_meal":-9999.0, "orders":0}
					p.staff.append(worker.id)
					workers.append(worker)
				properties.append(p)

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

func wants(w: Dictionary, at: float) -> Array:
	var result: Array = []
	if at < w.start or at >= w.end: return result
	if at >= w.coffee_break-20 and at <= w.coffee_break+60 and at-w.last_drink >= 150:
		result.append(w.drink)
	elif at >= w.lunch and at <= w.lunch+45 and at-w.last_drink >= 150:
		result.append(w.drink)
	if at >= w.lunch-15 and at <= w.lunch+45 and at-w.last_meal >= 240:
		result.append(w.meal)
	return result

func demand(property_id: int) -> Dictionary:
	var result = {}
	for id in properties[property_id].staff:
		for item in wants(workers[id],clock): result[item] = result.get(item,0)+1
	return result

func serve(property_id: int) -> Dictionary:
	var result = {}
	for id in properties[property_id].staff:
		var w = workers[id]
		for item in wants(w,clock):
			result[item] = result.get(item,0)+1
			if item in DRINKS: w.last_drink = clock
			else: w.last_meal = clock
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
		w.orders = 0
