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
	check(c.properties==twin.properties and c.workers==twin.workers,"Seed must reproduce properties and individual workers")
	twin.generate(1988)
	check(c.workers!=twin.workers,"Different seeds must differ")
	for seed_value in [1,19,1987,99999]:
		c.generate(seed_value)
		check(c.properties.size()>700,"City scale")
		check(c.workers.size()>10000,"Individual population scale")
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
