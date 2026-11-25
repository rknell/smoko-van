# Smoko Van Game Design v1

Version: 1.0 — design draft, 30 October 2026.

Source: https://chatgpt.com/space/page_52a99fb36c3c8191a1a0196000a27b0f

Smoko Van is a pixel art business and territory game set in an exaggerated Australian town. The player runs a fleet of food vans, plans dependable routes, stocks products for different times of day, and defends the business through outrageous turn-based fights and underhanded interference.

The main challenge is improving the business. Combat supplies comedy, disruption and tactical variety. Success should feel like “I made this operation work better”, with recoverable local setbacks and no routine campaign restart.

Draft dated 30 October 2026. The concept and scope below reflect the agreed direction. Rules marked **Proposed** fill gaps for review; numerical examples are tuning candidates, not approved balance values.

## Experience and platform

The player is the boss. Vans drive and sell automatically; the player chooses stock, prices, staff, routes, investments and intrigue, then personally commands disputes.

**Proposed platform direction:** design one game for desktop and phone, with a shared simulation and different screen arrangements. Start with a playable desktop layout while testing every core interaction on a narrow touch screen from the first milestone. Phone support is part of completion, not an optional sequel. Browser delivery is a candidate for early testing; engine, native packaging and distribution remain undecided.

The complexity fits the concept if decisions can be made without time pressure. Provide pause, simulation speed controls, saved route and loadout presets, clear forecasts and automatic saving. Complexity should come from tradeoffs rather than tiny controls or constant tapping.

Desktop shows the map, selected van and route timeline together. Phone shows a full map with a focused panel for Route, Stock, Stops or Fleet. Use tap-to-select and explicit reorder buttons alongside optional dragging. Never require hover or precision gestures. Phone orientation remains open.

**Proposed:** single-player first, no offline progression, and saving during planning, operations and battles. Closing the game should not punish a player.

## The daily loop

1. Review yesterday’s performance, customer feedback, business changes and rival activity.

2. Buy supplies, allocate stock to vans, set prices and assign staff.

3. Keep existing routes or modify stops, arrival targets and restocking plans.

4. Schedule espionage, traps or HQ operations.

5. Start the day. Vans travel, queue, serve and continue automatically.

6. Monitor live stock, sales, arrival forecasts and satisfaction. Redirect a van to restock when the lost time is worth it.

7. When a qualifying rival encounter occurs, pause operations and enter a dispute.

8. Resume operations, finish the day and review profit, waste, loyalty and territory changes.

9. Repair, recruit and upgrade before the next run.

Routes persist between days. **Proposed:** reusable loading plans and price presets also persist, but stock purchases are confirmed each day. Midday route edits show the knock-on effects before commitment.

The simulation runs continuously during operations. Manual pause and speed controls supplement automatic dispute pauses. Proposed battle handling freezes the town during player decisions, then applies a bounded in-world delay after the result. Multiple encounters enter a queue so managing a fleet never requires simultaneous battles.

## Town and routes

The town is a top-down pixel art map with roads, a depot, rival HQs and service stops. Routes follow the road network. Travel time, service time and any waiting determine arrival at the next stop.

Each route displays stop order, intended arrival, predicted arrival, expected demand, stock remaining and a warning where an important service window is at risk. Players can add a depot visit, skip a stop, reorder stops or set an earliest service time.

An illustrative morning route might leave the depot at 8:40, arrive at a workshop at 8:55, spend ten minutes serving, then drive fifteen minutes to an office at 9:20. Returning to the depot after the workshop must visibly push back every downstream arrival.

**Proposed:** distinguish the published service commitment from the live ETA. Moving an ETA cannot erase lateness. Changing the recurring schedule creates a transition period while customers learn the new routine.

Business activity rises and falls. A construction project can hire another crew; an office can lose workers; a factory can introduce a shift. Changes affect demand and potentially break times. Forecast them through news and stop trends so the player has a chance to adapt.

## Stops and customer demand

Customers are simulated as demand groups at each stop rather than named individuals. Every stop has a workforce or customer volume, daily activity level, break windows, product preferences, price sensitivity, quality expectations and attitude to violence.

| Stop type | Typical opportunity | Main service pressure | Reaction to overt violence |
| --- | --- | --- | --- |
| Construction site | Coffee, filling lunches, cold drinks | Short breaks and large orders | Entertained; may reward loyalty |
| Office | Coffee, lighter meals, reliable lunch | Punctuality, quality and reputation | Disapproval and lost trust |
| Workshop | Coffee, pies and substantial meals | Value and dependable visits | Proposed mixed tolerance |
| Factory | Large orders around shift breaks | Throughput and enough stock | Proposed dependence on workforce culture |

Demand changes with time, weather, business activity, price and previous purchases. Arriving early does not create customers who are not ready to buy. Arriving after another van may find demand already satisfied.

Track unmet appetite separately for coffee, meals and drinks, with recovery over time. Buying coffee should not erase lunch demand. **Proposed:** track fractions of each stop’s demand group so selling ten coffees does not suppress demand for every worker.

Feedback reports causes: “Coffee sold out before half the crew were served”, “Arrived after the break”, or “Lunch was great; we’ll try your morning run.”

## Stock and pricing

Stock is purchased rather than cooked by the player. Vans have limited storage and equipment for hot, cold and ambient products. Perishability, storage conditions, supplier prices, weather and product quality all affect purchasing decisions.

**Proposed initial product families:** coffee supplies, pies and sausage rolls, sandwiches or wraps, packaged snacks, cold drinks and iced coffee. Exact products and preparation abstractions remain to be chosen. Coffee equipment can affect capacity and service speed without creating a cooking minigame.

The loading screen shows capacity used, purchase cost, projected demand, expected margin and likely shortages or waste. Forecasts should be ranges with reasons, not perfect knowledge of future sales.

**Proposed pricing:** product prices set per van, with a fleet default and optional route-level overrides later if useful. Avoid requiring separate prices for every stop. Higher prices improve margin but may reduce purchases and perceived value.

Restocking uses depot stock, loading time and travel time. The route preview compares expected recovered sales with likely losses from lateness. A restock is a meaningful tradeoff, particularly for small early vans.

Daily results separate revenue from stock costs, wages, fuel, waste, repairs and operation costs. Stock should be paid for once; accounting must distinguish cash spent on purchases from the cost of goods sold.

## Satisfaction and loyalty

Satisfaction measures recent service. Loyalty reflects accumulated trust in a business. Both matter, but a single bad day should not wipe out weeks of dependable service.

Inputs include punctuality, consistency, availability, price, quality, variety, staff service and reputation. Violence can improve or damage a relationship depending on the stop.

**Proposed loyalty model:** maintain a relationship between each business and stop, plus a stronger service-specific habit for morning coffee, lunch or other established visits. Good lunch service can gradually help a challenger win the morning relationship, without immediately replacing the trusted coffee van.

Stops display separate signals for current satisfaction, long-term loyalty and willingness to consider a rival. Explain their recent movement. Highly loyal customers refuse a hostile takeover until their loyalty has been undermined; military victory alone cannot override that protection.

Missed or unreliable visits, shortages and unmet preferences create openings. Reliable rival service outside the incumbent’s hours and reputation attacks can widen them. Repeated improvement should repair a damaged relationship.

## Territory across place and time

A stop is not owned uniformly for the whole day. Territory is a business’s influence over a stop during a service window, affected by arrival habits, loyalty and remaining demand.

The example of a 9:30 regular visit influencing roughly 8:30–10:00 is a useful starting point. **Proposed:** use a strong central window with fading influence at its edges, rather than an unconditional ninety-minute ownership block. Tune the width separately for each stop’s break patterns.

The interface shows a daily timeline at a selected stop, with coloured bands for each rival’s influence. A map time slider reveals who controls the morning, lunch and afternoon opportunities. Colour is supplemented by labels and symbols.

Resolve a prospective visit in this order: are customers ready to buy; is demand still unmet; will they consider this seller; is the visit inside contested incumbent hours; and is a rival present to contest it?

| Situation | Proposed result |
| --- | --- |
| Arrive well before a useful break | Little demand, regardless of territory |
| Serve lunch outside a rival’s morning influence | Peaceful sales and a chance to build trust |
| Challenge a highly loyal morning stop | Customers reject the takeover; violence cannot force sales |
| Enter a weakened window without the incumbent present | Win available sales and gradually strengthen influence |
| Meet the incumbent while challenging a vulnerable window | Automatic dispute |
| Lose one service window | Retain unrelated visits and relationships at the same stop |

**Proposed encounter boundary:** a rival encounter means competing to serve the same stop in a contested window, not simply passing on the road. This needs confirmation against the intended “finding a rival starts a fight” rule.

Influence grows from actual service, not just placing a waypoint. Prevent repeated empty visits, trivial purchases and hovering nearby from manufacturing ownership.

## Disputes and turn based combat

Combat is deliberately excessive: bazookas, mines, ridiculous punch-ons, wildlife chaos and attacks on rival HQs. The preferred direction is a party battle with alternating turns, inspired by the broad structure of South Park’s RPG battles, using original characters, artwork and jokes.

**Proposed presentation:** cut from the map to a side-on pixel art battle scene. The boss selects actions for the crew. A first-person presentation remains an alternative, not a settled requirement.

A compact encounter uses a small crew on each side. Each turn offers a basic attack, character ability, limited item or defensive action. Clear status effects and visible upcoming turns allow planning without reflex inputs.

Example original actions include a Pie-Zooka, an Esky shield, an Emu Barricade that disrupts the enemy’s next turn, and an exaggerated tradie punch-on. Koala involvement is part of the proposed absurdist palette; whether animals are unharmed cartoon participants or the humour is darker remains open.

Victory secures today’s contested selling opportunity and pressures an already vulnerable incumbent. **Proposed:** lasting control still requires dependable follow-up service. Defeat costs a local opportunity, some stock, repairs or bounded downtime; it does not wipe the fleet.

The requested first battle has a 55% player win chance. **Proposed interpretation:** target roughly 55% success for a defined baseline matchup and basic play, with choices able to improve the result. A guaranteed fixed 55% roll would make tactical decisions cosmetic. Confirm whether the intended first prototype instead uses that simple roll.

Keep encounters brief enough that fleet management remains the main activity. A provisional target is two to four minutes, with skippable repeated animation, no real-time input demands, and encounter cooldowns to prevent the same stop repeatedly blocking the day.

## Sabotage and intrigue

Plan operations at the start of the day. Operations consume money, staff time or limited items, with a displayed risk and possible consequences.

| Operation | Gameplay effect | Possible drawback |
| --- | --- | --- |
| Cartoon road hazard or nail trap | Tyre damage and a route delay | Discovery, repair costs or retaliation |
| Emu blockade | Temporary obstruction or detour | Disruption spreads beyond the intended rival |
| HQ sabotage | Reduced loading capacity or delayed departure | Security catches the crew; compensation or heat |
| Hygiene or ethics rumour | Temporary loss of trust | Exposure strengthens the target and harms the instigator |
| Absurd cult allegation | Reputation event with stop-specific reactions | Customers find it ridiculous or become sympathetic |

These are fictional game actions resolved through rules and animations. Offices favour subtle competition and punish visible violence; construction crews can react very differently.

**Proposed counterplay:** depot security, vehicle resilience, scouting, staff skills and reputation repair. Stacking operations must have diminishing effects and recovery periods so one van cannot be disabled indefinitely. Rivals follow equivalent resource, travel and cooldown rules.

The broader concept includes police or heat and consequences such as repairs, stolen stock, medical downtime and missed service. The exact enforcement model remains open because “all of that” supports the direction without settling the severity.

## Fleet staff and progression

Start with a small van whose capacity forces difficult route and stocking choices. Expand through equipment improvements, larger or specialised vans, additional vehicles, depot upgrades and stronger crew capabilities.

Staff vary in quality. **Proposed attributes:** service speed, reliability, sales manner, product handling and combat skills. Wages and training create a choice between dependable service and a stronger fighting crew. Training and replacements should make poor hiring recoverable.

More vans expand the same boss-level decisions. Players still plan, stock, monitor and command fights; they do not transition into manual driving. Reusable routes, loadouts, staff assignment tools and prioritised alerts keep fleet growth manageable.

Upgrades include hot and cold storage, coffee equipment, capacity, vehicle reliability, armour, combat equipment and depot logistics. The previously mentioned “own kitchen” conflicts with the decision against cooking: **Proposed resolution:** depot storage and distribution upgrades, with production excluded unless explicitly reinstated.

Rivals become more capable through territory, resources and distinct tactics. **Proposed:** avoid automatically matching every player upgrade; improvement should produce a felt advantage.

Conquer one town, then optionally continue into a harder town. **Proposed completion rule:** secure a dominant share of valuable service windows and neutralise major rivals, rather than requiring every tiny time slot. The exact threshold and what carries between towns remain open. Continuing to optimise a conquered town should remain possible.

## Difficulty and recovery

The intended campaign is forgiving and persistent. The player may lose a stop or a morning window, but should usually have time and tools to respond.

**Proposed safeguards:** visible warnings before loyalty collapses; limited rival aggression against a struggling business; protection against repeated losses at one location; affordable repairs; temporary staff recovery; and emergency operating assistance if the player cannot fund a viable route.

Assistance must preserve meaningful tradeoffs without forcing a restart. Avoid permanent loss of the final usable van or a bankruptcy state that leaves the save unplayable.

Local rivalry should keep the town interesting as the player grows. It should not secretly erase the value of upgrades or force a predetermined loss rate. Random events need explanations and bounded effects.

Campaign duration, a typical day’s real-time length and the number of vans and stops are playtest decisions. Provisional test targets are short sessions that can be suspended at any point, with a campaign unfolding across many sessions.

## Visual direction sound and interface

Use a readable top-down pixel art Australian town: industrial estates, suburban streets, office blocks, construction sites, workshops, sun-faded signage and recognisable food vans. Vehicles and stop icons must stay legible at phone scale.

Keep the map calm enough to read. Use bright, exaggerated animation for disputes and important events. Pixel art does not require pixel-sized text; interface labels should remain clear at normal device sizes.

Australian humour comes through staff banter, products, feedback, rival personalities and escalating absurdity. Exact profanity level, gore and audience rating remain undecided. Original visual designs should establish Smoko Van’s own identity.

The main screens are Town, Route Planner, Depot and Loading, Stop Details, Fleet and Staff, Rival Operations, Battle, and Daily Results. Prioritise actionable notifications over a constant stream of interruptions. Feedback can remain a running feed while urgent shortages and imminent lateness receive stronger signals.

Sound should communicate van arrivals, sales, stockouts and disputes without requiring the player to listen. Music and sound have separate controls; animations can be accelerated or reduced.

## Delivery milestones and full completion

The full vision is the intended finished game. Milestones test parts of that vision; the first playable is not the definition of “ready”.

| Milestone | Playable scope | What it must prove |
| --- | --- | --- |
| Business and rivalry foundation | Top-down town, persistent routes, ETAs, loading, pricing, varied stops, automatic selling, one rival, time-based turf and one absurd battle | Stock, timing and rivalry create an understandable daily loop |
| Customer and territory depth | Loyalty transfer between visits, satiation, restocking, spoilage, weather, supplier variation, business growth and decline | Optimising service creates believable opportunities and defences |
| Rivalry and fleet depth | Several vans, staff quality, upgrades, intrigue, traps, HQ attacks, counterplay and broader combat | Expansion remains manageable and rivalry stays varied |
| Complete town campaign | Stronger rivals, conquest, harder subsequent towns, recovery rules, full desktop and phone interaction, final art and sound | The complete vision remains fun and usable over a campaign |

The first milestone must show an opponent trying to steal business and a meaningful battle outcome. A static map or a stock calculator alone does not meet it.

Full completion requires all agreed systems above, adequate content to sustain a town campaign, save and resume, clear feedback, and usable phone and desktop layouts. Content quantities, campaign length and polish criteria need agreement before a production estimate can be credible.

## Validation before production

Prototype the business rules before committing to a large quantity of art or combat content. Check that changing stop order changes ETAs correctly; service and depot dwell times propagate; stock cannot be sold twice; morning coffee purchases suppress later coffee demand without suppressing lunch; and loyal stops remain protected from brute-force transfer.

Play through the distinctive takeover example: the incumbent serves coffee poorly, a challenger establishes dependable lunch service, trust shifts over several days, the morning window becomes vulnerable, and a dispute or peaceful competitive visit can finally change control.

Check that office and construction-site reactions differ, rumours can backfire, staff quality affects operations, business activity changes demand, and a lost battle leaves a viable next day.

Test battle balance across repeated encounters with a defined baseline strategy. Do not infer a 55% win rate from a handful of fights. Check pause/resume, queued encounters and interrupted mobile sessions for duplicate sales or lost progress.

Observe whether players can explain why sales were missed and identify one useful improvement. If they cannot, improve the forecasts and feedback before adding more systems.

## Decisions for the next review

1. Should the fight trigger be competing at a stop during contested hours, or any close encounter between rival vans?

2. Should battle presentation be side-on party combat, or a first-person view with turn-based commands?

3. Does 55% describe baseline tactical balance, or a fixed random result for the first version?

4. Should police and heat be a light comic consequence system, or should law enforcement be absent?

5. Is the humour broadly cartoonish with animals unharmed, or darker, with pixel gore and adult language?

6. Is landscape phone play acceptable, or must the game support portrait?

7. Should town completion mean market dominance, defeating each rival, or both, and what should carry into the next town?

8. Confirm the proposed single-player direction, suspended offline time and depot upgrades without food production.

These decisions refine implementation without removing the agreed business, territory, combat or progression systems. The first playable implementation is now available in this workspace. See [README.md](README.md) for launch instructions, implemented features and the remaining full-game scope.



## Implemented strategy expansion — v0.2

The playable now connects five decision layers: multi-day stop relationships, competing prime service windows, distinct investments, a reactive rival and actionable tomorrow previews. This extends the original vision; remaining campaign scope is unchanged.

Reliable lunch service on three separate days earns preferred status, a one-off $100 bonus and a morning trust foothold. Qualification is visible: arrive within 15 minutes, meet 80% of demand, and sell at least six meals (three wraps at offices). Preferred status adds 15% lunch demand but lapses after two missed days; one qualifying lunch restores it. Morning and lunch trust are separate. Repeat visits cannot farm daily progress.

The morning schedule deliberately overlaps around 9am. Route previews expose late/early arrivals. Espresso vans trade food space for speed and office coffee pricing tolerance; lunch trucks trade speed and running cost for capacity and worksite meal demand. Express crews save service time for higher wages. An eastside depot changes journey lengths and restocking options. Vehicles and depot purchases arrive next morning and can be refunded while still pending before opening.

Kev assesses available service windows, weak service and protected stops. He can target lunch instead of a defended morning, discount contested stops, buy security or retaliate against operations. His stock is finite and purchased with his own funds. The Board exposes his announced plan so players can respond.

Construction expands and eventually closes; factory shifts increase demand. Known dates are shown ahead of time. End-of-day reports offer relationship targets, upcoming deliveries, business changes, Kev’s plan and weather/wholesale forecasts. These previews persist through reloads and govern the following day, making planning consequential. Players can pin a stop as a goal.

Existing saves retain their money, route, day and battle state. New relationships start from zero, separate service trust starts from existing loyalty, and the business calendar starts from migration day. The new overlapping coffee windows apply in planning, never halfway through a saved trading day.

Balance remains provisional: automated multi-day tests check progression and economic consistency, while player feedback will determine whether choices stay interesting over longer campaigns.
