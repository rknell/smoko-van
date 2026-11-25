# Smoko Van

Version 0.2 of the Australian food-van business game. Run a route through Wattle Creek, keep the crew fed and deal with Big Kev's territorial nonsense.

## New city prototype

A separate Godot experiment lives in [prototypes/city-lab](prototypes/city-lab/README.md): a seeded city, individual workers and click/tap road routes, without economics. The original game below remains independent.

## Run locally

Requires Node.js 20 or newer. There are no package dependencies to install.

```sh
npm run dev
```

Open [Smoko Van](http://127.0.0.1:4173). The development server binds to this computer only. Phone layouts can be tested with a narrow browser viewport; access from a physical phone or public hosting is not configured.

```sh
npm test
```

## Play

1. Use **Route** to order visits, choose departure time, and set a **Not before** time when a van should wait for a break. Repeated stops allow morning and lunch visits. Depot visits refill the van.
2. Use **Stock** to set quantities and prices. Capacity includes each item's size. Purchases, wages and fuel are charged when the day starts.
3. **Open for business**. Staff drive and sell automatically. Pause or run at 1×, 3× or 6×. One in-game minute takes half a second at 1×.
4. Watch customer feedback and remaining stock. **Return to depot & restock** interrupts the current leg and then resumes the pending visit, at the cost of travel and loading time.
5. Fight at contested stops with the haymaker, pie-zooka, emu uprising and esky bunker. Losing is recoverable. Construction crews enjoy the chaos; offices lose trust.
6. At **HQ**, upgrade storage, train staff, order specialist vans, open an eastside depot, choose express crews or plan an operation. Routes and loading plans persist tomorrow.

The browser autosaves each simulation update. Reloading pauses trading. Hidden tabs pause, and time does not progress offline. Use **Export save** and **Import save** to transfer progress between browsers. **New game** asks before replacing a save.

## Included in this version

- Original canvas pixel-art town with eight stops, roads, a depot, rival HQ, moving vans, route overlay and map zoom.
- Persistent routes, road travel times, service durations, earliest-arrival waits and depot restocking.
- Four products, stock capacity, adjustable prices, wholesale variation, wages, fuel and overnight spoilage.
- Stop-specific preferences, coffee/lunch demand, business activity changes, weather effects and shared demand depletion after either van sells.
- Customer loyalty, rival loyalty, protected loyal stops, competition for demand and long-term relationship shifts.
- One rival with an actual route, automatic disputes at shared stops and four turn-based combat actions.
- Rumours, emu blockades and HQ sabotage with success, backfire and economic effects.
- Three-van fleet, crew training, vehicle upgrades, local recovery grants, daily results and a conquest threshold.
- A tougher follow-on challenge reusing the same map, with partial cash carryover and stronger opposition.
- Responsive desktop and phone layouts, keyboard-accessible management controls, save export/import and validation.

## Strategy expansion (v0.2)

- **Stops:** three reliable lunch days earn preferred service, a $100 bonus, extra lunch demand and morning trust. Serve within 15 minutes, fill at least 80% of demand and sell the required meals. Two missed lunch days suspend preferred status; a qualifying visit restores it.
- **Route:** overlapping coffee breaks force choices. Arrival warnings expose the tradeoff between prime windows, distance and capacity.
- **HQ:** all-rounders, fast espresso vans and large lunch trucks have distinct capacity, demand and operating-cost tradeoffs. Express crews save service time for extra daily wages. An eastside depot enables new routes. Investments arrive tomorrow; pending orders can be cancelled for a full refund before opening.
- **Board:** pin relationship goals, inspect known construction/shift changes and see Kev’s announced intentions. Existing saves start the business-event calendar from their migration day.
- **Daily report:** tomorrow’s opportunities combine relationship progress, deliveries, rival plans, business changes and a weather/wholesale forecast. Forecasts persist across reloads and are used the next day.

Existing saves migrate automatically without resetting cash, routes or trading day. Old relationship progress starts at zero; coffee windows adopt the new overlapping schedule at the next planning phase.

## Provisional rules and remaining scope

The complete vision remains in [DESIGN.md](DESIGN.md). This playable is a foundation, not the completed campaign.

Turf now tracks separate morning and lunch trust, recent service history and preferred-service relationships. Continuous ownership gradients and a time-slider map remain future scope. Demand resets between morning and lunch rather than recovering continuously.

Big Kev now plans around service gaps, discounts contested slots, buys finite stock from his own budget and responds to operations with security or delays. Multiple distinct rivals and faction personalities remain future scope. Operations currently affect departure or reputation; there are no placeable road traps or playable HQ raids yet. Heat is recorded but police enforcement is not implemented.

Storage is one shared capacity. Hot/chilled product labels do not yet impose separate compartment limits. Staff quality is an upgrade level rather than individual recruitable characters. Spoilage occurs at day end rather than minute by minute.

Combat uses one fighter per side and placeholder pixel characters. The first matchup is tuned around 84% wins for the baseline policy “use pie-zooka when available, otherwise punch,” tested across 2,000 deterministic seeds. This is not a fixed outcome probability; defensive choices and upgrades change results. Kev can miss, graze or land a lucky heavy blow, and player attacks can critically hit. New games use a fresh random seed; saving and reloading preserve the current random sequence. The town pauses during decisions. A 60-minute dispute cooldown prevents successive stops from turning the whole run into fights.

Follow-on towns currently reuse Wattle Creek. New maps, larger campaigns, multi-character battles, richer animation, sound/music, production assets and device-store packaging remain future work. Mobile layout testing is browser-based, not a physical-device certification.

## Code map

- `public/engine.js` — deterministic simulation, economic rules, rival, combat, saves.
- `public/strategy.js` — relationships, investments, business calendar, rival planning and forecasts.
- `public/strategy-ui.js` — board, relationships and investment controls.
- `tests/strategy.test.mjs` — multi-day progression, migration, rival economics and forecasts.
- `public/app.js` — management controls, dialogs, autosave and browser loop.
- `public/map.js` — original canvas town and vehicle rendering.
- `public/style.css` — responsive layout and battle effects.
- `tests/engine.test.mjs` — economy, routing, combat, restocking and persistence checks.
- `server.mjs` — local static development server.

There is no backend account, analytics, external game API or paid service. Optional Google Fonts enhance typography; system fonts remain usable if unavailable.
