extends SceneTree
const City = preload("res://scripts/city.gd")
var failures = 0
func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		failures += 1
func _initialize() -> void:
	var c = City.new()
	c.generate(1987)
	var twin = City.new()
	twin.generate(1987)
	check(c.properties==twin.properties and c.workers==twin.workers and c.precincts==twin.precincts and c.roads==twin.roads,"Seed must reproduce properties and individual workers")
	twin.generate(1988)
	check(c.workers!=twin.workers,"Different seeds must differ")
	for seed_value in [1,19,1987,99999]:
		c.generate(seed_value)
		check(c.properties.size()>700,"City scale")
		check(c.workers.size()>10000,"Individual population scale")
		check(c.dead_ends.size()>=5,"Generated roads include meaningful dead ends")
		check(c.roads.size()<450,"City does not restore the full street grid")
		var detour_found = false
		for road_id in range(0,c.roads.size(),11):
			var from=c.roads[road_id][0]
			var to=c.roads[(road_id+47)%c.roads.size()][1]
			var route=c.path(from,to)
			var length=0.0
			for i in range(1,route.size()): length+=route[i-1].distance_to(route[i])
			if length>abs(to.x-from.x)+abs(to.y-from.y)+120: detour_found=true
		check(detour_found,"Missing links create real driving detours")
		var zones = {}
		for p in c.properties:
			zones[p.zone]=true
			var path = c.path(Vector2.ZERO,p.access)
			check(not path.is_empty() and path[-1]==p.access,"Every property reachable")
			for i in range(1,path.size()):
				var delta = path[i]-path[i-1]
				check(is_equal_approx(delta.length(),60) and (delta.x==0 or delta.y==0),"Paths stay on adjacent road nodes")
			for id in p.staff: check(c.workers[id].property==p.id,"Property owns its individual workers")
		check(zones.size()==2,"Both zones generated")
		check(c.precincts.size()==9,"Nine named industrial precincts")
		var remaining = c.industrial_blocks.duplicate()
		var components = 0
		while not remaining.is_empty():
			components+=1
			var queue = [remaining.keys()[0]]
			remaining.erase(queue[0])
			while not queue.is_empty():
				var block = queue.pop_back()
				for offset in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]:
					var neighbour = block+offset
					if remaining.has(neighbour):
						remaining.erase(neighbour)
						queue.append(neighbour)
		check(components==9,"Industry forms nine disconnected clusters, not one belt")
		var sprites = {}
		for p in c.properties:
			sprites[p.sprite]=true
			check(p.sprite>=0 and p.sprite<16,"Valid building atlas cell")
			if p.zone=="Industrial": check(p.precinct>=0,"Every industrial property has a precinct")
		check(sprites.size()==16,"All sixteen building graphics have uses")
	var worker = c.workers[0]
	c.clock=worker.coffee_break
	var wants_before=c.wants(worker,c.clock)
	check(worker.drink in wants_before,"Personal break drives individual demand")
	var orders=c.serve(worker.property)
	check(orders.get(worker.drink,0)>0,"Free service fulfils actual individual demand")
	check(not worker.drink in c.wants(worker,c.clock),"Satisfied worker cannot instantly order again")
	var total=c.total_orders
	c.serve(worker.property)
	check(c.total_orders==total,"Repeated service at same minute does not create orders")
	check(c.wants(worker,worker.end+1).is_empty(),"Off-shift workers do not order")
	c.next_day()
	check(c.total_orders==0 and worker.orders==0,"New day resets service history")
	print("City model checks: ","PASS" if failures==0 else "FAIL", " · ",c.properties.size()," properties / ",c.workers.size()," individuals")
	quit(failures)
