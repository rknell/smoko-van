import { EAST_DEPOT, VAN_TYPES, spec, serviceMinutes, runningCost, mealSpace, isDepot, windowFor, idealFor, migrateStrategy, applyWindows, applyBusinesses, recordVisit, settleRelationships, forecastTomorrow, deliverOrders, validateStrategy } from './strategy.js';
export const PRODUCTS = [
  { id: 'coffee', name: 'Flat whites', short: 'COFFEE', icon: '☕', cost: 1.2, price: 4.5, size: 1, shelf: 'Fresh daily', type: 'coffee' },
  { id: 'pie', name: 'Meat pies', short: 'PIES', icon: '🥧', cost: 2.5, price: 6.5, size: 2, shelf: 'Hot cabinet', type: 'meal' },
  { id: 'wrap', name: 'Salad wraps', short: 'WRAPS', icon: '🥪', cost: 3, price: 7.5, size: 2, shelf: 'Chilled', type: 'meal' },
  { id: 'iced', name: 'Iced coffee', short: 'ICED', icon: '🧋', cost: 2, price: 5, size: 1, shelf: 'Chilled', type: 'drink' },
];
export const DEPOT = { id: 'depot', name: 'Your depot', x: 80, y: 500 };
export const RIVAL_HQ = { id: 'rival-hq', name: "Big Kev’s HQ", x: 680, y: 500 };
const stops = [
  { id: 'workshop', name: 'Spanner & Sons', type: 'Workshop', x: 280, y: 500, people: 26, coffeeAt: 505, lunchAt: 725, violence: .4, preferences: [1, 1.1, .25, .7] },
  { id: 'site', name: 'The Big Dig', type: 'Construction', x: 480, y: 500, people: 38, coffeeAt: 535, lunchAt: 710, violence: 1, preferences: [1.1, 1.5, .15, 1] },
  { id: 'office', name: 'Paperwork Palace', type: 'Office', x: 480, y: 300, people: 34, coffeeAt: 570, lunchAt: 750, violence: -1, preferences: [1.2, .25, 1.3, .5] },
  { id: 'factory', name: 'Wattle Steel', type: 'Factory', x: 680, y: 300, people: 42, coffeeAt: 600, lunchAt: 735, violence: .3, preferences: [1, 1.2, .35, 1] },
  { id: 'council', name: 'Shire Chambers', type: 'Office', x: 280, y: 100, people: 24, coffeeAt: 590, lunchAt: 765, violence: -1, preferences: [1.2, .25, 1.1, .5] },
  { id: 'yard', name: 'Rusty’s Timber', type: 'Construction', x: 80, y: 300, people: 28, coffeeAt: 525, lunchAt: 720, violence: 1, preferences: [.9, 1.3, .25, .8] },
  { id: 'clinic', name: 'Creekside Clinic', type: 'Office', x: 880, y: 100, people: 30, coffeeAt: 610, lunchAt: 780, violence: -1, preferences: [1, .2, 1.4, .7] },
  { id: 'shed', name: 'Freight Mates', type: 'Factory', x: 880, y: 500, people: 36, coffeeAt: 625, lunchAt: 800, violence: .6, preferences: [1, 1.4, .25, .9] },
];
export const clamp = (x, a, b) => Math.max(a, Math.min(b, x));
export const money = x => new Intl.NumberFormat('en-AU', { style: 'currency', currency: 'AUD', maximumFractionDigits: 0 }).format(x);
export const time = n => `${String(Math.floor(n / 60)).padStart(2, '0')}:${String(Math.floor(n % 60)).padStart(2, '0')}`;
export const travel = (a, b, v) => Math.ceil((Math.abs(a.x - b.x) + Math.abs(a.y - b.y)) / (v ? spec(v).speed : 20));
export const spot = (s, id) => id === 'depot' ? DEPOT : id === 'east-depot' ? EAST_DEPOT : s.stops.find(x => x.id === id);
export function rng(s) { s.seed = (Math.imul(s.seed, 1664525) + 1013904223) >>> 0; return s.seed / 4294967296; }
const zero = () => Object.fromEntries(PRODUCTS.map(p => [p.id, 0]));
export function newVan(id = 1) { return { id, type: 'general', crew: 'standard', home: 'depot', name: id === 1 ? 'The Early Bird' : `Tucker Truck ${id}`, capacity: 120, level: 1, staff: 1, route: ['workshop', 'site', 'office', 'factory'], waitUntil: [], depart: 490, load: { coffee: 44, pie: 18, wrap: 10, iced: 20 }, prices: Object.fromEntries(PRODUCTS.map(p => [p.id, p.price])), stock: zero(), x: DEPOT.x, y: DEPOT.y, stage: 'idle', index: 0, next: 0, revenue: 0, sold: 0, restocked: false }; }
export function newGame(seed = Math.floor(Math.random() * 4294967296)) {
  return migrateStrategy({ version: 1, seed: seed >>> 0, day: 1, time: 480, phase: 'planning', paused: false, cash: 1200, weather: 'Sunny', supply: 1, vans: [newVan()], stops: stops.map((x, i) => ({ ...x, activity: 1, loyalty: i < 2 ? 44 : 15, rival: i < 4 ? 52 : 35, habit: x.coffeeAt, consumed: {}, served: [], fought: false })), rival: { route: ['workshop', 'site', 'office', 'factory', 'clinic', 'shed'], x: RIVAL_HQ.x, y: RIVAL_HQ.y, index: 0, stage: 'idle', next: 0, revenue: 0 }, feed: [{ text: 'Welcome to Wattle Creek. Big Kev reckons he owns the place. Prove him wrong.', kind: 'news', at: 480 }], today: { revenue: 0, costs: 0, waste: 0, customers: 0, fights: 0, won: 0, soldByProduct: zero() }, operation: null, battle: null, summary: null, conquered: false, town: 1, heat: 0 });
}
export function log(s, text, kind = 'news') { s.feed.unshift({ text, kind, at: s.time }); s.feed = s.feed.slice(0, 60); }
export const loadSize = load => PRODUCTS.reduce((n, p) => n + load[p.id] * p.size, 0);
export const loadCost = (s, load) => PRODUCTS.reduce((n, p) => n + load[p.id] * p.cost * s.supply, 0);
export function schedule(s, v) { let at = v.depart, prev = spot(s,v.home || 'depot'); return v.route.map((id, i) => { const p = spot(s, id); at += travel(prev, p, v); at = Math.max(at, v.waitUntil?.[i] || 0); const row = { ...p, at, until: at + (isDepot(id) ? 12 : serviceMinutes(v)) }; at = row.until; prev = p; return row; }); }
export function demand(s, stop, p, at = s.time) {
  const coffee = Math.max(0, 1 - Math.abs(at - stop.coffeeAt) / 45);
  const lunch = Math.max(0, 1 - Math.abs(at - stop.lunchAt) / 55);
  const weight = p.type === 'coffee' ? Math.max(coffee, lunch * .45) : p.type === 'meal' ? Math.max(lunch, coffee * .2) : Math.max(coffee * .6, lunch * .9);
  const heat = s.weather === 'Scorcher' && p.type === 'drink' ? 1.5 : 1;
  return Math.max(0, Math.round(stop.people * stop.activity * stop.preferences[PRODUCTS.indexOf(p)] * weight * .65 * heat));
}
export function startDay(s) {
  if (s.phase !== 'planning') return 'The day has already started.';
  migrateStrategy(s);
  if (s.vans.every(v => !v.route.length)) return 'Give at least one van a route. Vans without routes stay parked.';
  if (s.vans.some(v => v.route.length && loadSize(v.load) > v.capacity)) return 'A van is overloaded. Reduce its stock.';
  if (s.vans.some(v => v.route.length && v.type==='espresso' && mealSpace(v.load) > spec(v).mealLimit)) return 'The espresso van only has 20 food spaces. Reduce pies or wraps.';
  if (s.vans.some(v => v.route.includes('east-depot') && !s.depots.east)) return 'Eastside depot is not open yet.';
  const cost = s.vans.filter(v=>v.route.length).reduce((n, v) => n + loadCost(s, v.load) + runningCost(v), s.depots.east ? 18 : 0);
  if (cost > s.cash) return 'Not enough cash for stock, wages and fuel.';
  s.cash -= cost; s.today.costs += cost; s.phase = 'running'; s.paused = false;
  for (const v of s.vans) { const home=spot(s,v.home); v.x=home.x;v.y=home.y;v.stock = v.route.length ? { ...v.load } : zero(); v.stage = v.route.length ? 'waiting' : 'done'; v.next = v.depart; v.index = 0; }
  // Kev has to pay for a finite load, fuel and any announced countermeasure.
  const plan=s.rival.plan;
  if(plan?.security && s.rival.cash>=120){s.rival.cash-=120;s.rival.security=Math.min(2,s.rival.security+1);}
  if(plan?.retaliation && s.rival.cash>=60){s.rival.cash-=60;const victim=s.vans.find(v=>v.route.length);victim.next+=12;log(s,`${victim.name}: Kev’s dodgy roadworks delay departure by 12 minutes.`, 'warn');}
  if(plan?.security || plan?.retaliation)s.rival.grudge=Math.max(0,s.rival.grudge-(plan.grudge||1));
  const budget=Math.min(240,Math.max(0,s.rival.cash-35));
  const wishlist=plan?.slot==='lunch'?{coffee:20,pie:36,wrap:22,iced:28}:{coffee:60,pie:12,wrap:10,iced:25};
  const multiplier=Math.min(1,budget/loadCost(s,wishlist));
  s.rival.stock=Object.fromEntries(PRODUCTS.map(p=>[p.id,Math.floor(wishlist[p.id]*multiplier)]));
  s.rival.cash=Math.max(0,s.rival.cash-loadCost(s,s.rival.stock)-35);
  s.rival.stage = 'waiting'; s.rival.next = 480;
  if (s.operation) {
    const op = s.operation;
    if (rng(s) < .72 - s.rival.security * .12) {
      if (op === 'rumour') { for (const p of s.stops) { p.rival = clamp(p.rival - 10, 0, 100); for(const slot of ['morning','lunch'])p.kevTrust[slot]=clamp(p.kevTrust[slot]-10,0,100); } log(s, 'The “cult of the soggy pie” rumour is doing the rounds. Kev loses trust.', 'good'); }
      else { s.rival.next += op === 'hq' ? 65 : 35; log(s, op === 'hq' ? 'HQ raid! Kev’s roller door is mysteriously full of expanding foam. Late start.' : 'Emu blockade! Kev’s van is stuck behind a very assertive bird.', 'good'); }
    } else { s.heat += 1; const penalty = Math.min(30, s.cash); s.cash -= penalty; s.today.costs += penalty; for (const p of s.stops) {p.loyalty = clamp(p.loyalty - 4, 0, 100);for(const slot of ['morning','lunch'])p.trust[slot]=clamp(p.trust[slot]-4,0,100);} log(s, 'Busted! Your scheme backfired. $30 clean-up and a dent in your reputation.', 'bad'); }
    s.operation = null;
  }
  log(s, 'Roll out! Your crew has the keys. Watch the ETAs and the stock.', 'good');
  return null;
}
function go(s, unit, target) { unit.from = { x: unit.x, y: unit.y }; unit.verticalFirst = ![100, 300, 500].includes(Math.round(unit.y)); unit.target = target.id; unit.to = { x: target.x, y: target.y }; unit.started = s.time; unit.next = s.time + travel(unit, target, unit); unit.stage = 'driving'; }
function advance(s, v, rival = false) {
  if (v.index >= v.route.length) { if (rival) { v.stage = 'done'; return; } go(s, v, spot(s,v.home || 'depot')); v.finishing = true; return; }
  go(s, v, spot(s, v.route[v.index]));
}
export function restock(s, v) {
  if (s.phase !== 'running' || s.battle || v.stage === 'done' || v.returning || v.finishing) return 'This van cannot restock right now.';
  const depot = s.depots.east && travel(v,EAST_DEPOT,v) < travel(v,DEPOT,v) ? EAST_DEPOT : DEPOT;
  v.returning = true; go(s, v, depot); log(s, `${v.name} is heading back to stock up. Downstream stops will be late.`, 'warn'); return null;
}
function fill(s, v) {
  let spent = 0;
  for (const p of PRODUCTS) { const missing = Math.max(0, v.load[p.id] - v.stock[p.id]); const count = Math.min(missing, Math.floor(Math.max(0, s.cash - spent) / (p.cost * s.supply))); v.stock[p.id] += count; spent += count * p.cost * s.supply; }
  s.cash -= spent; s.today.costs += spent; log(s, `${v.name} restocked for ${money(spent)}. Twelve minutes to load.`, 'news');
}
function service(s, v, stop, rival = false) {
  const at=v.serviceAt ?? s.time, slot = windowFor(at);
  const soldProducts=zero();
  // Older saves can start tracking if no sales have happened yet.
  if (!rival && !s.today.soldByProduct && s.today.customers === 0) s.today.soldByProduct = zero();
  let sold = 0, wanted = 0, revenue = 0;
  const shortages = [];
  for (const p of PRODUCTS) {
    const key = `${slot}-${p.type}`;
    let raw = demand(s, stop, p, at);
    if(!rival && stop.relationship.preferred && slot==='lunch')raw=Math.round(raw*1.15);
    if(!rival && v.type==='lunch' && stop.type!=='Office' && p.type==='meal')raw=Math.round(raw*1.25);
    const unmet = Math.max(0, raw - (stop.consumed[key] || 0));
    const loyalty = rival ? stop.kevTrust[slot] : stop.trust[slot];
    const other = rival ? stop.trust[slot] : stop.kevTrust[slot];
    const protection = other >= 80 && loyalty < 60 && Math.abs(at - idealFor(stop,slot)) < 35 ? .08 : 1;
    const price = rival ? p.price * (s.rival.plan?.discount && s.rival.plan.targetId===stop.id ? .85 : 1.04) : v.prices[p.id];
    const premium = !rival && v.type==='espresso' && stop.type==='Office' && p.id==='coffee' ? 1.25 : 1;
    const value = clamp(1.3 - (price / (p.price*premium) - 1) * .8, .1, 1.4);
    const request = Math.round(unmet * clamp(.5 + loyalty / 120, .35, 1) * value * protection);
    wanted += request;
    const count = Math.min(v.stock?.[p.id] ?? (rival ? request : 0), request);
    soldProducts[p.id] = count;
    if(rival && v.stock)v.stock[p.id]-=count;
    if (!rival) {
      v.stock[p.id] -= count;
      if (count < request) shortages.push(p.name);
      if (s.today.soldByProduct) s.today.soldByProduct[p.id] += count;
    }
    stop.consumed[key] = (stop.consumed[key] || 0) + count;
    sold += count; revenue += count * price;
  }
  if (rival) { v.revenue += revenue; v.cash += revenue; if (sold) {stop.kevTrust[slot] = clamp(stop.kevTrust[slot] + 2, 0, 95);if(sold>=wanted*.8)stop.trust[slot]=clamp(stop.trust[slot]-2,0,100);} return; }
  v.revenue += revenue; v.sold += sold; s.cash += revenue; s.today.revenue += revenue; s.today.customers += sold;
  const expected = idealFor(stop,slot);
  const late = Math.abs(at - expected) > 15;
  const ratio = wanted ? sold / wanted : 0;
  const delta = wanted === 0 ? -1 : (ratio > .85 ? 7 : ratio > .5 ? 1 : -6) + (late ? -3 : 2) + (v.staff - 1);
  stop.trust[slot] = clamp(stop.trust[slot] + delta, 0, 100);
  stop.loyalty = Math.round((stop.trust.morning+stop.trust.lunch)/2);
  if (delta > 3) stop.kevTrust[slot] = clamp(stop.kevTrust[slot] - 2, 0, 100);
  const relationshipNews=recordVisit(s,stop,slot,{sold,wanted,products:soldProducts,at});
  if(relationshipNews)log(s,relationshipNews,'good');
  stop.served.push(slot);
  const issue = !wanted ? 'Too early, too late, or customers already fed.' : shortages.length ? `${shortages.join(', ')} ran out — sales lost.${late ? ' Timing was off too.' : ''}` : late ? 'Good tucker, but the timing’s a bit off.' : 'Right on time. You little ripper!';
  log(s, `${stop.name}: ${sold} items · ${money(revenue)}. ${issue}`, shortages.length || delta <= 0 ? 'warn' : 'good');
}
function encounter(s, v, p) {
  if (p.fought || s.battle || s.time < (s.nextDispute || 0) || p.trust[windowFor(s.time)] >= 85 || p.kevTrust[windowFor(s.time)] >= 85) return false;
  p.fought = true; s.today.fights++;
  s.battle = { vanId: v.id, stopId: p.id, hp: 100 + v.staff * 10 + v.level * 5, maxHp: 100 + v.staff * 10 + v.level * 5, enemy: 105 + s.town * 8, maxEnemy: 105 + s.town * 8, turn: 1, energy: 3, guard: false, stun: false, message: 'Big Kev: “You’re on my pie run, mate!”', history: [], result: null };
  log(s, `Turf dispute at ${p.name}! Big Kev wants a word. And possibly a bazooka.`, 'bad'); return true;
}
export function battleAction(s, action) {
  const b = s.battle; if (!b || b.result || !['punch', 'pie', 'emu', 'guard'].includes(action)) return;
  const v = s.vans.find(v => v.id === b.vanId);
  const cost = action === 'pie' ? 2 : action === 'emu' ? 1 : 0;
  if (b.energy < cost) return;
  b.energy -= cost; let damage = 0, text = '';
  if (action === 'punch') { damage = 14 + Math.floor(rng(s) * 20) + v.staff * 2; b.energy = Math.min(4, b.energy + 1); text = `Hi-vis haymaker! ${damage} damage. +1 energy.`; }
  if (action === 'pie') { damage = 28 + Math.floor(rng(s) * 32) + v.level * 3; text = `PIE-ZOOKA! Thermonuclear gravy. ${damage} damage.`; }
  if (action === 'emu') { damage = 10; b.stun = true; text = 'Emu uprising! 10 damage. Kev loses his next turn.'; }
  if (action === 'guard') { b.guard = true; b.energy = Math.min(4, b.energy + 2); text = 'Esky bunker! Incoming damage reduced. +2 energy.'; }
  if ((action === 'punch' || action === 'pie') && rng(s) < .18) {
    damage = Math.round(damage * 1.5);
    text = action === 'pie' ? `JACKPOT GRAVY! Critical pie-zooka hit: ${damage} damage.` : `YOU BEAUTY! Critical haymaker: ${damage} damage. +1 energy.`;
  }
  b.enemy = Math.max(0, b.enemy - damage);
  if (b.enemy <= 0) { b.result = 'win'; b.message = text; return; }
  if (b.stun) { text += ' Kev is arguing with a bird.'; b.stun = false; }
  else {
    const luck = rng(s);
    if (luck < .15) text += ' Kev slips on a sausage roll. Complete miss!';
    else {
      const weak = luck < .35, big = luck >= .9;
      const raw = (weak ? 12 + rng(s) * 18 : big ? 55 + rng(s) * 15 : 36 + rng(s) * 26) + s.town * 2;
      const hit = Math.round(raw * (b.guard ? .3 : 1));
      b.hp = Math.max(0, b.hp - hit);
      text += ` ${weak ? 'Kev barely clips you' : big ? 'Kev gets lucky with a massive hit' : 'Kev swings his thong of destiny'}: ${hit} damage.${b.guard ? ' Your esky softened the blow.' : ''}`;
    }
  }
  b.guard = false; b.turn++; b.history.unshift(text); b.message = text;
  if (b.hp <= 0) b.result = 'loss';
}
export function resolveBattle(s) {
  const b = s.battle; if (!b?.result) return;
  const v = s.vans.find(v => v.id === b.vanId), p = spot(s, b.stopId);
  if (b.result === 'win') { s.today.won++; p.kevTrust[windowFor(s.time)] = clamp(p.kevTrust[windowFor(s.time)] - 7, 0, 100); s.rival.stage = 'waiting'; s.rival.index++; s.rival.next = s.time + 20; log(s, `Kev retreats from ${p.name}. The selling window is yours.`, 'good'); }
  else { const repair = Math.min(45, s.cash); s.cash -= repair; s.today.costs += repair; v.index++; v.stage = 'waiting'; v.next = s.time + 15; p.trust[windowFor(s.time)] = clamp(p.trust[windowFor(s.time)] - 3, 0, 100); log(s, `Lost the punch-on. ${money(repair)} repairs, then back on the road.`, 'warn'); }
  p.trust[windowFor(s.time)] = clamp(p.trust[windowFor(s.time)] + p.violence * 5, 0, 100);
  if (p.violence < 0) { s.heat++; log(s, `${p.name}: “Please take your bazookas away from reception.” Trust down.`, 'bad'); }
  else log(s, `${p.name}: “Best smoko entertainment all week!”`, 'good');
  s.nextDispute = s.time + 60;
  s.battle = null;
}
function updateUnit(s, v, rival = false) {
  if (v.stage === 'done') return;
  if (v.stage === 'driving') { const f = clamp((s.time - v.started) / Math.max(1, v.next - v.started), 0, 1); const dx = Math.abs(v.to.x - v.from.x), dy = Math.abs(v.to.y - v.from.y), dist = (dx + dy) * f; v.x = v.from.x + Math.sign(v.to.x - v.from.x) * (v.verticalFirst ? Math.max(0, dist - dy) : Math.min(dist, dx)); v.y = v.from.y + Math.sign(v.to.y - v.from.y) * (v.verticalFirst ? Math.min(dist, dy) : Math.max(0, dist - dx)); }
  if (s.time < v.next) return;
  if (v.stage === 'waiting' || v.stage === 'idle') { advance(s, v, rival); return; }
  if (v.stage === 'loading') { if (v.returning) v.returning = false; else v.index++; advance(s, v, rival); return; }
  if (v.stage === 'driving') {
    v.x = v.to.x; v.y = v.to.y;
    if (isDepot(v.target)) {
      if (v.finishing) { v.stage = 'done'; return; }
      fill(s, v); v.stage = 'loading'; v.next = s.time + 12; return;
    }
    if ((v.waitUntil?.[v.index] || 0) > s.time) { v.stage = 'waiting-stop'; v.next = v.waitUntil[v.index]; return; }
    v.stage = 'serving'; v.serviceAt=s.time; v.next = s.time + (rival ? 18 : serviceMinutes(v));
  }
  if (v.stage === 'waiting-stop') { v.stage = 'serving'; v.serviceAt=s.time; v.next = s.time + (rival ? 18 : serviceMinutes(v)); }
  if (v.stage === 'serving') {
    const p = spot(s, v.target);
    if (!rival && s.rival.stage === 'serving' && s.rival.target === p.id && encounter(s, v, p)) return;
    if (rival) { const other = s.vans.find(x => x.stage === 'serving' && x.target === p.id); if (other && encounter(s, other, p)) return; }
    if (s.time < v.next) return;
    service(s, v, p, rival); v.index++; advance(s, v, rival);
  }
}
export function tick(s) {
  if (s.phase !== 'running' || s.paused || s.battle) return;
  s.time++;
  updateUnit(s, s.rival, true);
  if (s.battle) return;
  for (const v of s.vans) { updateUnit(s, v); if (s.battle) return; }
  if (s.vans.every(v => v.stage === 'done')) {
    // Resolve the rest of Kev’s announced run even if the player finishes early.
    while(s.time<870 && s.rival.stage!=='done'){s.time++;updateUnit(s,s.rival,true);}
    endDay(s);
  } else if(s.time>=870)endDay(s);
}
export function endDay(s) {
  if (s.phase !== 'running') return;
  s.today.leftByProduct = zero();
  s.today.waste = 0;
  for (const v of s.vans) for (const p of PRODUCTS) s.today.leftByProduct[p.id] += v.stock[p.id];
  for (const v of s.vans) { s.today.waste += Object.values(v.stock).reduce((a, b) => a + b, 0); v.stage = 'done'; }
  settleRelationships(s);
  forecastTomorrow(s,rng);
  const controlled = s.stops.filter(p => p.loyalty > p.rival && p.loyalty >= 60).length;
  s.conquered = controlled >= 6;
  s.summary = { ...s.today, controlled, profit: s.today.revenue + (s.today.bonuses||0) - s.today.costs, leads: structuredClone(s.leads) };
  s.phase = 'summary'; log(s, 'That’s a wrap. Fresh stock expires overnight; tomorrow is another chance.', 'news');
}
export function nextDay(s) {
  if (s.phase !== 'summary') return;
  s.day++; s.nextDispute = 0; s.time = 480; s.phase = 'planning'; s.summary = null; s.paused = false;
  const forecast=s.forecast;
  s.weather=forecast?.weather || 'Sunny';s.supply=forecast?.supply || 1;
  if(s.windowsPending)applyWindows(s);
  for(const name of deliverOrders(s,newVan))log(s,`${name} is ready. Give it a job in HQ.`, 'good');
  applyBusinesses(s);
  s.today = { revenue: 0, costs: 0, waste: 0, customers: 0, fights: 0, won: 0, soldByProduct: zero() };
  for (const v of s.vans) { Object.assign(v, { stock: zero(), x: spot(s,v.home).x, y: spot(s,v.home).y, stage: 'idle', index: 0, next: 0, revenue: 0, sold: 0, finishing: false, returning: false }); }
  Object.assign(s.rival, { x: RIVAL_HQ.x, y: RIVAL_HQ.y, stage: 'idle', index: 0, next: 0, revenue: 0 });
  for (const p of s.stops) { p.consumed = {}; p.served = []; p.fought = false; }
  if(forecast?.kev){s.rival.plan=forecast.kev;s.rival.route=[...forecast.kev.route];s.rival.waitUntil=[...forecast.kev.waitUntil];}
  s.forecast=null;
  const minimum = s.vans.reduce((n, v) => n + loadCost(s, v.load) + runningCost(v), 0) + 50;
  if (s.cash < minimum) { const grant = minimum - s.cash; s.cash += grant; log(s, `Shire recovery grant: ${money(grant)}. Enough for another honest go.`, 'good'); }
}
export function planOperation(s, op) {
  if (s.phase !== 'planning') return 'Plan operations before the day starts.';
  if (s.operation) return 'One operation per day. Make it count.';
  const price = { rumour: 60, emu: 85, hq: 125 }[op];
  if (!price || s.cash < price) return 'Not enough cash.';
  s.cash -= price; s.today.costs += price; s.operation = op; s.rival.grudge++; return null;
}
export function upgrade(s, v, kind) {
  if (s.phase !== 'planning') return 'Make upgrades between days.';
  const price = kind === 'staff' ? v.staff * 180 : v.level * 220;
  if ((kind === 'staff' ? v.staff : v.level) >= 3) return 'Already at the top level.';
  if (s.cash < price) return 'Not enough cash.';
  s.cash -= price; s.today.costs += price;
  if (kind === 'staff') v.staff++; else { v.level++; v.capacity += 45; }
  return null;
}
export function buyVan(s) {
  if (s.phase !== 'planning') return 'Buy vans between days.';
  if (s.vans.length >= 3) return 'Your depot holds three vans in v1.';
  if (s.cash < 900) return 'A second van costs $900.';
  s.cash -= 900; s.today.costs += 900; const v = newVan(s.vans.length + 1); v.route = ['yard', 'council', 'clinic']; v.depart = 520; s.vans.push(v); return null;
}
export function validateSave(s) {
  try {
    const finite = n => Number.isFinite(n);
    const bounded = (n,a,b) => finite(n) && n>=a && n<=b;
    const ids = new Set(stops.map(p=>p.id));
    if(!s || s.version!==1 || !Array.isArray(s.vans) || !s.vans.length || s.vans.length>3 || !Array.isArray(s.stops) || s.stops.length!==stops.length) return false;
    if(!['planning','running','summary'].includes(s.phase) || !bounded(s.cash,0,1e9) || !bounded(s.time,480,870) || !bounded(s.day,1,1e7) || !bounded(s.town,1,1000) || !finite(s.seed) || !bounded(s.supply,.5,2) || !['Sunny','Scorcher','Showers'].includes(s.weather) || !Array.isArray(s.feed)) return false;
    if(!s.feed.every(f=>typeof f.text==='string'&&finite(f.at)))return false;
    if(!s.today || !['revenue','costs','waste','customers','fights','won'].every(k=>finite(s.today[k])))return false;
    if(s.phase==='summary'&&(!s.summary || !['profit','controlled','revenue','costs','waste','customers','fights','won'].every(k=>finite(s.summary[k]))))return false;
    for (const record of [s.today, s.summary].filter(Boolean)) {
      for (const field of ['soldByProduct', 'leftByProduct']) {
        if (record[field] !== undefined && (!record[field] || !PRODUCTS.every(p => Number.isInteger(record[field][p.id]) && record[field][p.id] >= 0))) return false;
      }
    }
    const unitOK = u => u && Array.isArray(u.route) && u.route.length<=16 && u.route.every(id=>ids.has(id)||isDepot(id)) && ['idle','waiting','waiting-stop','driving','serving','loading','done'].includes(u.stage) && bounded(u.x,0,960) && bounded(u.y,0,640) && finite(u.index) && finite(u.next) && (u.stage!=='driving'||(u.from&&u.to&&[u.from.x,u.from.y,u.to.x,u.to.y,u.started].every(finite)&& (ids.has(u.target)||isDepot(u.target)))) && (u.stage!=='serving'||ids.has(u.target));
    if(!unitOK(s.rival))return false;
    if(new Set(s.stops.map(p=>p.id)).size!==stops.length)return false;
    if(!s.stops.every(p=>ids.has(p.id)&&bounded(p.loyalty,0,100)&&bounded(p.rival,0,100)&&bounded(p.activity,0,2)&&[p.x,p.y,p.people,p.coffeeAt,p.lunchAt,p.habit,p.violence].every(finite)&&Array.isArray(p.preferences)&&p.preferences.length===4&&p.preferences.every(finite)&&Array.isArray(p.served)&&p.consumed&&Object.values(p.consumed).every(finite)))return false;
    if(!s.vans.every(v=>unitOK(v)&&typeof v.name==='string'&&finite(v.id)&&bounded(v.capacity,1,500)&&bounded(v.staff,1,3)&&bounded(v.level,1,3)&&bounded(v.depart,480,780)&&finite(v.revenue)&&finite(v.sold)&&(!v.waitUntil||(Array.isArray(v.waitUntil)&&v.waitUntil.every(n=>n===null||bounded(n,0,850))))&&v.load&&v.prices&&v.stock&&PRODUCTS.every(p=>[v.load[p.id],v.prices[p.id],v.stock[p.id]].every(n=>bounded(n,0,500)))))return false;
    if(s.battle){const b=s.battle;if(!s.vans.some(v=>v.id===b.vanId)||!ids.has(b.stopId)||!['hp','maxHp','enemy','maxEnemy','turn','energy'].every(k=>finite(b[k]))||!bounded(b.energy,0,4)||!Array.isArray(b.history)||typeof b.message!=='string'||![null,'win','loss'].includes(b.result))return false;}
    return validateStrategy(s);
  } catch {return false;}
}
