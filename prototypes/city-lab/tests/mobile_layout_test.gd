extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size=Vector2i(1280,576)
	var scene=load("res://main.tscn").instantiate()
	scene.mobile_layout=true
	root.add_child(scene)
	await process_frame
	await process_frame
	scene._layout()
	scene._focus_van()
	await process_frame
	assert(scene.size.y<=451,"Phone UI uses logical units, not native screen pixels")
	assert(scene.zoom>=0.65,"Phone starts at a tappable neighbourhood scale")
	for button in scene.find_children("*","Button",true,false):
		if not button.is_visible_in_tree(): continue
		assert(button.size.y>=52,"Touch targets at least 52 logical pixels")
		assert(button.get_global_rect().end.x<=scene.size.x+1 and button.get_global_rect().end.y<=scene.size.y+1,"Button clipped: "+button.text)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://screenshots/android-landscape.png")
	root.size=Vector2i(1920,1080)
	await process_frame
	await process_frame
	for button in scene.find_children("*","Button",true,false):
		if not button.is_visible_in_tree(): continue
		assert(button.get_global_rect().end.x<=scene.size.x+1 and button.get_global_rect().end.y<=scene.size.y+1,"16:9 button clipped: "+button.text)
	assert(scene.size.x<=801,"High-density 16:9 phone scales to 800 logical pixels")
	print("Landscape mobile scaling, touch targets, default zoom and layouts PASS")
	quit()
