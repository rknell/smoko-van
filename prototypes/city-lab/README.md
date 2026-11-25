# Smoko Van — City Lab

A fresh **Godot 4.7.2 / GDScript** experiment. The original browser game at the repository root is independent and unchanged. This is the city, people and route layer only: no money, inventory, prices, loyalty, rivals or combat.

## Open and run

Import `project.godot` into Godot 4.7.2 and press F6/F5. The project uses the Compatibility renderer, an original generated building atlas, and no third-party plugins or packages.

```sh
godot --path prototypes/city-lab
```

### Browser preview (desktop and mobile)

Install the matching Godot export templates, then:

```sh
mkdir -p prototypes/city-lab/build/web
godot --headless --path prototypes/city-lab --export-release Web
python3 prototypes/city-lab/serve.py
```

Open <http://localhost:4174>. To test on a physical phone on the same trusted Wi-Fi, run `python3 prototypes/city-lab/serve.py --lan` and open `http://YOUR-COMPUTER-IP:4174`. This serves only the exported build directory, not the source tree. Stop with Ctrl+C. Web builds use single-threaded WebAssembly and WebGL 2.

An Android test APK is available in `build/android/smoko-city-lab.apk` (Android 7+, ARM32/ARM64). It is debug-signed for sideload testing. Pinch with two fingers to zoom, drag with one finger to pan, or use +/− and Fit. Real-device testing remains outstanding.

Native Linux export is also configured. Godot can target Windows, macOS, Android and iOS; native phone exports still need platform SDKs/signing and device testing. This iteration provides a responsive browser build and Android test APK, not an app-store package.

## Controls

- **New:** regenerate the entered integer seed. **Shuffle:** choose a fresh seed. Both discard the current prototype route and reset the population.
- **Route:** tap/click a building to inspect it and append a service stop. Tap a street to append a road waypoint. Paths start at your chosen depot and automatically follow streets between your points.
- Toggle **Route / Inspect** to inspect without changing the route.
- **Drag** to pan; **wheel, pinch or +/−** to zoom. **Fit** shows the whole city; **Van** (desktop) returns to a close-up of your vehicle. **Depot** lets you tap a building or nearby road to move your base before driving; routes automatically recalculate.
- **Drive / Pause / Resume:** run or pause the van and population clock. **1× / 4×:** simulation speed.
- **Undo:** remove the last planned stop. **Clear:** stop the run and clear its route. Clear preserves the day's worker orders; it is not a new day.
- **Next day:** keep the route and workers, reset their appetites and the van, and return to 07:30. Routes can then be edited again.
- The property panel shows approximate drink/food demand for four periods: one dot is light, two steady, three busy. Individual staff still determine actual orders. The demand dropdown previews each period on the map. Scroll the route list to see all placed stops.

## Model

The seeded city spans 4.32 × 3.36 km, with roughly 850–950 properties and 14,000–16,000 workers. Nine separated, named industrial precincts specialise in engineering, freight, timber, auto repair, food, recycling, electronics, foundry work and brewing. Commercial properties and parks separate them. Sixteen building sprites match each property's business type.

Streets are orthogonal but incomplete: a seeded spanning tree guarantees connectivity, extra links make loops, and selected removable links create cul-de-sacs without isolating blocks. Missing streets form longer blocks and real route detours. Blue dead-end signs mark turning areas. Property placement requires an actual adjoining frontage, so unserved corners remain open space. Drawing and A* use the same road network; vehicles cannot cross missing links. The seed reproduces roads, precincts, buildings and workers.

Each worker has a stable ID, workplace, shift, drink/meal preferences and individual demand in four broad periods: early morning (06:00–09:00), morning (09:00–11:00), lunch (11:00–14:00), afternoon (14:00–18:00). A worker whose shift overlaps a period can be a customer in that window. Actual turnout varies daily (each business has a daily turnout probability between 70% and 100% for its usual requests), with seeded results. Individual boundaries vary by up to 8 minutes so transitions are staggered. Each desired category is served at most once per period; next day resets it. Exact break minutes and rolling cooldowns no longer drive orders. Forecast dots reflect usual demand, not guaranteed orders. Workers remain data records at their workplace, without pedestrian sprites.

Around 28% of businesses are non-customers and never order from the van. Others aggregate their individual workers' requests. Cup and food badges show outstanding demand on buildings at neighbourhood zoom. The demand selector previews any period, while “Demand: now” follows the clock. Selecting a property shows all four periods with cup/food icons and one to three dots for light, steady or busy demand; non-customers are labelled explicitly.

Service remains free and takes eight simulated minutes. One real second is two simulated minutes; movement is 150 world metres per real second. Runs stop after the final stop or at 18:00. Routes and new days use the chosen roadside depot; moving it is allowed before departure, never during a run. New city generation resets it. There is no persistent save yet.

## Tests

```sh
godot --headless --path prototypes/city-lab --script tests/model_test.gd
godot --headless --path prototypes/city-lab --script tests/route_test.gd
```

Checks cover deterministic generation, both zones, population scale, worker ownership, road reachability for every property across multiple seeds, individual period demand, duplicate-service protection, non-customer businesses, day reset, and the actual scene's route/drive/inspect controls.

## Structure and next layers

- `scripts/city.gd`: city generation, road graph, people and demand. Independent of the UI.
- `scripts/main.gd`: procedural drawing, responsive controls, route editing and van movement.
- `export_presets.cfg`: single-threaded Web, native Linux and Android targets.
- `tests/`: headless model and scene integration tests.

Deliberately provisional: orthogonal roads, no route autosave, no traffic or walking workers, no multiple vans, no economic simulation. The first playtest should answer whether city scale, map navigation and placing a useful route feel good. Economics can then attach to actual individual requests without replacing the population model.

### Verification in this workspace

Model tests passed across four generated seeds; scene tests cover an actual viewport mouse event, route traversal, day reset, undo and inspection. Godot rendered screenshots at 1280×800, 390×844 and 844×390, with button-bound checks for both phone orientations. Web and Linux release exports succeeded. Browser automation and physical-phone testing were unavailable in this session; browser loading and real touch-device performance still need playtesting.

To reproduce the rendering checks on a machine with a graphics display:

```sh
godot --path prototypes/city-lab --script tests/visual_test.gd
```

Generated screenshots are in `screenshots/`. Build outputs and Godot's cache are ignored by Git.


### Android build

Use the Android export preset with Godot 4.7.2's matching `android_debug.apk` template, OpenJDK 17, Android SDK platform-tools and build-tools. Set the Java and Android SDK paths in Godot Editor Settings, then:

```sh
mkdir -p prototypes/city-lab/build/android
godot --headless --path prototypes/city-lab --export-debug Android
godot --headless --path prototypes/city-lab --script tests/touch_test.gd
```

Godot's local debug keystore signs this test package; do not commit keystores. The preset includes ARM32 and ARM64 and has no internet permission. Gesture tests cover pinch anchoring, panning, release over UI, avoiding accidental route points, single taps and bounded zoom.


## v0.1.1 — landscape city update

Android supports either landscape orientation, a density-independent 800×400 logical UI, larger 52-unit buttons, larger text and a compact header. It opens zoomed into the depot neighbourhood rather than fitting the whole city into a phone screen. Pinch, +/−, Fit and Van remain available.

This update also includes the sixteen generated building sprites, nine industrial precincts, and irregular connected streets with cul-de-sacs. Tests check deterministic road generation, genuine detours, dead ends, reachable property entrances, cluster separation, all sprite mappings, input gestures and high-density phone layouts. APK version code is 2, signed with the same local debug key as v0.1.0. Native physical-device testing remains outstanding.

Asset provenance and the full built-in image-generation prompt are in [assets/README.md](assets/README.md).

## v0.1.2 — simpler stops

Rounded street corners, junctions and dead-end caps soften the map. The sidebar now shows a compact drinks/meal demand summary instead of individual worker schedules. Android version code 3.

## v0.1.3 — your depot and broad demand periods

Choose your own depot, find customers through cup/food badges, and plan around four broad windows. Around 28% of businesses have no van demand. Forecasts use approximate levels, daily turnout varies, and period transitions are staggered. Android version code 4. Icons are original code-authored SVGs in `assets/drink.svg` and `assets/food.svg`.
