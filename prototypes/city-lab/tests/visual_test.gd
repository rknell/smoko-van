extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.size=Vector2i(1280,800)
	root.add_child(scene)
	await process_frame
	await process_frame
	scene._fit()
	for id in [0,6,30,53,100,130]: scene._tap(scene.city.properties[id].rect.get_center())
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://screenshots/desktop.png")
	root.size=Vector2i(390,844)
	await process_frame
	await process_frame
	scene._fit()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://screenshots/mobile.png")
	for button in scene.find_children("*","Button",true,false):
		if not button.is_visible_in_tree(): continue
		assert(button.get_global_rect().end.x<=391,"Button outside phone width: "+button.text)
		assert(button.get_global_rect().end.y<=845,"Button outside phone height: "+button.text)
	root.size=Vector2i(844,390)
	await process_frame
	await process_frame
	scene._fit()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://screenshots/landscape.png")
	for button in scene.find_children("*","Button",true,false):
		if not button.is_visible_in_tree(): continue
		assert(button.get_global_rect().end.x<=845 and button.get_global_rect().end.y<=391,"Landscape button clipped: "+button.text)
	print("Rendered desktop, portrait and landscape; all phone buttons within viewport")
	quit()
