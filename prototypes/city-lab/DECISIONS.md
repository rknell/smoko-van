# City Lab: first layer

## What we are testing

Can placing and observing a van route through a city feel natural on both mouse and touch screens? Can individual workers supply understandable future demand without reintroducing the previous game's management UI?

## Scope chosen

- Godot 4.7.2, GDScript and the Compatibility renderer.
- A reproducible seeded city, with commercial and industrial districts and parks.
- Approximately 900 properties and 15,000 persistent-in-session individual people.
- A street graph shared by generated property access and van pathfinding.
- Tap-to-append route points, pan/zoom, undo/clear, automatic movement and property inspection.
- Free fulfilment of individual requests to make the population model observable.
- Browser-first testing for desktop and mobile; a native Linux build and editable Godot project.

## Deliberate simplifications

The generator creates nine separated industrial precincts and a seeded orthogonal road network with omitted connections, loops and dead ends. Every property retains reachable frontage. Curved roads, terrain and traffic are later experiments. Workers are simulated individually as records, not rendered as 17,000 walking characters. Demand is deterministic from each person's schedule/preferences and recent service. Prices, budgets and willingness-to-pay are absent.

Routes begin at the north-west depot, terminate at the last selected point, and are edited before departure. Pausing is for inspection; clear or next day enables editing again. Seeds reproduce cities, but routes are not saved across app restarts yet.

## Future layers, after the map feels right

1. Refine map navigation, street layouts and route placement from playtests.
2. More individual daily needs, optional employee movements and visible queues.
3. Van capacity and loading tied to actual requested items.
4. Costs/prices and business decisions.
5. Rival routes, territory and the absurd combat tone.

No later layer is a prerequisite for testing this one.

## Engine references

Godot's [renderer overview](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html) identifies Compatibility as suitable for 2D and web/mobile targets. Its [web export guide](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html) documents single-threaded web builds and WebGL 2 requirements. Native mobile SDK/signing setup is a separate packaging task.

## Landscape and city character update

Android now scales the UI independently of physical display pixels and runs in either landscape orientation. Close-up camera framing and 52-unit buttons make properties and controls usable on phones. Sixteen generated building sprites are mapped to business types. Industrial specialisms are shuffled across nine separated precincts; commercial areas provide buffers. Road generation preserves connectivity and actual property access while creating measurable detours.
