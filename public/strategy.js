// Persistent strategic decisions. This module has no UI or simulation-clock side effects.
export const EAST_DEPOT = { id: 'east-depot', name: 'Eastside depot', x: 880, y: 300 };
export const VAN_TYPES = {
  general: { name: 'All-rounder', price: 900, capacity: 120, speed: 20, overhead: 35, mealLimit: 120, description: 'Flexible stock and normal road speed. The dependable choice.', load: { coffee: 44, pie: 18, wrap: 10, iced: 20 } },
  espresso: { name: 'Espresso van', price: 1200, capacity: 100, speed: 24, overhead: 48, mealLimit: 20, description: '20% faster travel; office coffee customers tolerate a 25% premium. Only 20 spaces for food.', load: { coffee: 60, pie: 6, wrap: 4, iced: 20 } },
  lunch: { name: 'Lunch truck', price: 1500, capacity: 220, speed: 14, overhead: 65, mealLimit: 220, description: 'Huge load and 25% more meal demand at worksites. 30% slower travel; higher running costs.', load: { coffee: 20, pie: 45, wrap: 25, iced: 30 } },
};
const bound = (n,a,b) => Math.max(a,Math.min(b,n));
export const spec = v => VAN_TYPES[v.type] || VAN_TYPES.general;
export const serviceMinutes = v => Math.max(6, 16 - v.staff * 2 - (v.crew === 'fast' ? 6 : 0));
export const runningCost = v => spec(v).overhead + v.staff * 8 + (v.crew === 'fast' ? 32 : 0);
export const mealSpace = load => (load.pie + load.wrap) * 2;
export const isDepot = id => id === 'depot' || id === 'east-depot';
export const windowFor = at => at < 680 ? 'morning' : 'lunch';
export const idealFor = (p,slot) => slot === 'morning' ? p.coffeeAt : p.lunchAt;
export const relationshipGoal = p => p.type === 'Office' ? 'Three reliable lunches with at least 3 wraps sold' : 'Three reliable lunches with at least 6 meals sold';
export function migrateStrategy(s) {
  if (s.strategyVersion === 1) return s;
  s.strategyVersion = 1;
  s.chapterStart = s.day;
  s.windowsPending = s.phase !== 'planning';
  s.depots = { east: false };
  s.orders = [];
  s.focusStop = null;
  s.rival.cash = 800;
  s.rival.security = 0;
  s.rival.grudge = 0;
  s.rival.stock = null;
  s.rival.plan = null;
  s.forecast = null;
  s.leads = [];
  for (const v of s.vans) { v.type = 'general'; v.crew = 'standard'; v.home = 'depot'; }
  for (const p of s.stops) {
    p.baseActivity = p.activity;
    p.relationship = { lunches: 0, lastGoodDay: 0, preferred: false, unlocked: false, misses: 0, rewarded: false };
    p.trust = { morning: p.loyalty, lunch: p.loyalty };
    p.kevTrust = { morning: p.rival, lunch: p.rival };
    p.visitHistory = {};
  }
  if (!s.windowsPending) applyWindows(s);
  return s;
}
export function applyWindows(s) {
  const times = { workshop: 505, site: 535, office: 540, factory: 550, council: 540, yard: 540, clinic: 545, shed: 625 };
  for (const p of s.stops) { p.coffeeAt = times[p.id]; p.habit = p.coffeeAt; }
  s.windowsPending = false;
}
export function businessAt(s,p,day=s.day) {
  const age = day - s.chapterStart;
  if (p.id === 'site') return age >= 12 ? { activity: 0, text: 'Project finished. Closed to vans.' } : age >= 3 ? { activity: 1.8, text: `Extra crew on site. Project closes on day ${s.chapterStart+12}.` } : { activity: p.baseActivity, text: `Extra crew from day ${s.chapterStart+3}; project closes day ${s.chapterStart+12}.` };
  if (p.id === 'factory') return { activity: age >= 5 ? 1.4 : p.baseActivity, text: age >= 5 ? 'New shift established: 40% more workers.' : `New shift starts day ${s.chapterStart+5}: 40% more workers.` };
  return { activity: p.baseActivity, text: 'Established local business.' };
}
export function applyBusinesses(s) { for (const p of s.stops) p.activity = businessAt(s,p).activity; }
export function recordVisit(s,p,slot,details) {
  const { sold, wanted, products, at } = details;
  const reliable = wanted > 0 && sold/wanted >= .8 && Math.abs(at-idealFor(p,slot)) <= 15;
  // Repeated visits cannot earn multiple days of trust or overwrite a successful visit.
  const old = p.visitHistory[slot];
  if (old?.day !== s.day || !old.reliable) p.visitHistory[slot] = { day:s.day, reliable, shortage:sold<wanted, at, sold };
  const r = p.relationship;
  const meals = products.pie + products.wrap;
  const matches = p.type === 'Office' ? products.wrap >= 3 : meals >= 6;
  if (slot !== 'lunch' || !reliable || !matches || r.lastGoodDay === s.day) return null;
  r.lastGoodDay = s.day; r.lunches = Math.min(3,r.lunches+1); r.misses = 0;
  if (r.lunches < 3) return `${p.name}: ${r.lunches}/3 reliable lunches. Keep it up and they’ll back your morning run.`;
  if (r.preferred) return null;
  const restored = r.unlocked;
  r.preferred = true; r.unlocked = true;
  if (!restored) { p.trust.morning = bound(p.trust.morning+18,0,100); p.kevTrust.morning = bound(p.kevTrust.morning-8,0,100); }
  if (!r.rewarded) { r.rewarded = true; s.cash += 100; s.today.bonuses = (s.today.bonuses||0)+100; }
  return `${p.name}: ${restored?'preferred service restored':'preferred service earned! $100 signing bonus'}. More lunch demand and a foothold on mornings.`;
}
export function settleRelationships(s) {
  for (const p of s.stops) {
    if (!p.activity) continue;
    for (const slot of ['morning','lunch']) {
      if (p.visitHistory[slot]?.day !== s.day) p.trust[slot] = Math.max(0,p.trust[slot]-2);
    }
    const r=p.relationship;
    if(r.preferred && r.lastGoodDay !== s.day) { r.misses++; if(r.misses>=2) r.preferred=false; }
    p.loyalty = Math.round((p.trust.morning+p.trust.lunch)/2);
    p.rival = Math.round((p.kevTrust.morning+p.kevTrust.lunch)/2);
  }
}
const distance = (a,b) => Math.abs(a.x-b.x)+Math.abs(a.y-b.y);
export function planKev(s,day=s.day+1) {
  const open = s.stops.filter(p=>businessAt(s,p,day).activity>0);
  const morningStrength = open.reduce((n,p)=>n+p.trust.morning,0)/open.length;
  const lunchStrength = open.reduce((n,p)=>n+p.trust.lunch,0)/open.length;
  let candidates=[];
  for(const p of open)for(const slot of ['morning','lunch']) {
    if(p.trust[slot]>=85)continue;
    const history=p.visitHistory[slot], gap=history && (history.day<s.day || !history.reliable || history.shortage);
    const switchBonus=slot==='lunch' && morningStrength>lunchStrength+8 ? 35 : 0;
    const score=p.people*businessAt(s,p,day).activity + (gap?65:0) + switchBonus + (p.trust[slot]>25?15:0) - p.trust[slot]*.35;
    candidates.push({p,slot,gap,score});
  }
  candidates.sort((a,b)=>b.score-a.score || a.p.id.localeCompare(b.p.id));
  const pick=candidates[0] || {p:open[0],slot:'lunch',gap:false};
  const target=pick.p, slot=pick.slot;
  const discount=target.trust[slot]>=35;
  const reason=pick.gap?'He noticed missed demand or unreliable service.':slot==='lunch'&&morningStrength>lunchStrength+8?'Your mornings are strong. He is building a lunch foothold.':'He is chasing a valuable service window.';
  let route=[target.id], waits=[idealFor(target,slot)-5], at=waits[0]+18, prev=target;
  // Choose reachable follow-up windows. He obeys roads and service time too.
  const remaining=open.filter(p=>p.id!==target.id);
  while(route.length<4 && remaining.length) {
    remaining.sort((a,b)=>(distance(prev,a)-a.people*2)-(distance(prev,b)-b.people*2));
    const p=remaining.shift();const eta=at+Math.ceil(distance(prev,p)/20), ideal=idealFor(p,slot);
    if(eta>ideal+35)continue;
    route.push(p.id);waits.push(Math.max(eta,ideal-10));at=waits.at(-1)+18;prev=p;
  }
  const retaliation=s.rival.grudge>0 && s.rival.grudge%2===0 && s.rival.cash>=60;
  const security=s.rival.grudge>0 && !retaliation && s.rival.security<2 && s.rival.cash>=120;
  return { grudge:s.rival.grudge,day,targetId:target.id,slot,discount,reason,route,waitUntil:waits,retaliation,security };
}
export function forecastTomorrow(s,rng) {
  if(s.forecast?.day===s.day+1)return;
  s.forecast = {day:s.day+1,weather:['Sunny','Scorcher','Showers'][Math.floor(rng(s)*3)],supply:.9+rng(s)*.25,kev:planKev(s)};
  s.leads=buildLeads(s);
}
export function buildLeads(s) {
  const day=s.forecast?.day || s.day+1;
  const leads=[];
  for(const order of s.orders)leads.push({kind:'investment',stopId:null,title:`${order.kind==='depot'?'Eastside depot':VAN_TYPES[order.type].name} opens day ${order.readyDay}`,text:order.kind==='depot'?'Assign a van to start in the east or add a restock visit.':'A new route becomes possible. Plan which window it will cover.'});
  const ranked=[...s.stops].filter(p=>businessAt(s,p,day).activity>0).sort((a,b)=>(b.id===s.focusStop)-(a.id===s.focusStop)||b.relationship.lunches-a.relationship.lunches);
  for(const p of ranked.slice(0,2)) {
    const r=p.relationship;
    leads.push({kind:r.preferred&&r.misses?'risk':'relationship',stopId:p.id,title:r.preferred?(r.misses?`${p.name} needs you back`:`Keep ${p.name} on side`):`${p.name}: ${r.lunches}/3 lunches`,text:r.preferred?(r.misses?'Another missed reliable lunch suspends preferred status.':'Preferred status adds 15% lunch demand. Keep delivering dependable lunches.'):`${relationshipGoal(p)} earns preferred status, $100 and morning trust. Arrive within 15 minutes and meet at least 80% of demand.`});
  }
  for(const p of s.stops) {
    const now=businessAt(s,p,s.day),future=businessAt(s,p,day);
    if(now.activity!==future.activity)leads.push({kind:'town',stopId:p.id,title:`${p.name} changes tomorrow`,text:future.text});
  }
  const plan=s.forecast?.kev || s.rival.plan;
  if(plan){const p=s.stops.find(p=>p.id===plan.targetId);leads.push({kind:'rival',stopId:p.id,title:`Kev is eyeing ${p.name}’s ${plan.slot==='morning'?'coffee':'lunch'} trade`,text:`${plan.reason}${plan.discount?' He will undercut normal prices by 15%.':''}${plan.retaliation?' He plans a 12-minute delay to your first van.':''}${plan.security?' He is buying better HQ security.':''}`});}
  if(s.forecast)leads.push({kind:'weather',stopId:null,title:`Tomorrow: ${s.forecast.weather.toLowerCase()}`,text:s.forecast.weather==='Scorcher'?'Cold drink demand rises 50%. Make room in the esky.':`Wholesale prices will be ${Math.round(s.forecast.supply*100)}% of normal.`});
  if(s.vans.length+s.orders.filter(o=>o.kind==='van').length<3) {
    const gap=Math.max(0,900-s.cash);
    leads.push({kind:'investment',stopId:null,title:gap?`$${Math.ceil(gap)} to another van`:'A second route is within reach',text:'An all-rounder costs $900. Espresso and lunch specialists unlock different routes; retain cash for tomorrow’s stock.'});
  }
  return leads;
}
export function orderInvestment(s,kind,type='general') {
  if(s.phase!=='planning')return 'Order investments before opening.';
  if(kind==='van' && (!VAN_TYPES[type] || s.vans.length+s.orders.filter(o=>o.kind==='van').length>=3))return 'Your depot has room for three vans, including orders.';
  if(kind==='depot' && (s.depots.east||s.orders.some(o=>o.kind==='depot')))return 'Eastside depot is already owned or on order.';
  if(!['van','depot'].includes(kind))return 'Unknown investment.';
  const price=kind==='depot'?650:VAN_TYPES[type].price;
  if(s.cash<price)return `You need $${price} for this investment.`;
  s.cash-=price;s.today.costs+=price;s.orders.push({kind,type,readyDay:s.day+1});return null;
}
export function cancelInvestment(s,index) {
  if(s.phase!=='planning')return 'Cancel orders before opening.';
  if(!Number.isInteger(index)||!s.orders[index])return 'That order is no longer pending.';
  const o=s.orders.splice(index,1)[0],price=o.kind==='depot'?650:VAN_TYPES[o.type].price;
  s.cash+=price;s.today.costs-=price;return null;
}
export function deliverOrders(s,newVan) {
  const delivered=[];
  s.orders=s.orders.filter(o=>{if(o.readyDay>s.day)return true;if(o.kind==='depot')s.depots.east=true;else {
    const v=newVan(Math.max(...s.vans.map(v=>v.id))+1),t=VAN_TYPES[o.type];
    Object.assign(v,{type:o.type,crew:'standard',home:'depot',name:`${t.name} ${v.id}`,capacity:t.capacity,load:{...t.load},route:[],waitUntil:[]});s.vans.push(v);
  }delivered.push(o.kind==='depot'?'Eastside depot':VAN_TYPES[o.type].name);return false;});return delivered;
}
export function validateStrategy(s) {
  if(s.strategyVersion===undefined)return true;
  const n=x=>Number.isFinite(x)&&x>=0;
  if(s.strategyVersion!==1||!n(s.chapterStart)||!s.depots||typeof s.depots.east!=='boolean'||!Array.isArray(s.orders)||s.orders.length>4)return false;
  const ids=new Set(s.stops.map(p=>p.id));
  if(s.focusStop!==null&&!ids.has(s.focusStop))return false;
  if(!s.orders.every(o=>['depot','van'].includes(o.kind)&&VAN_TYPES[o.type]&&n(o.readyDay)))return false;
  if(s.vans.length+s.orders.filter(o=>o.kind==='van').length>3)return false;
  if(!s.vans.every(v=>VAN_TYPES[v.type]&&['standard','fast'].includes(v.crew)&&['depot','east-depot'].includes(v.home)&&(v.home!=='east-depot'||s.depots.east)))return false;
  if(!s.stops.every(p=>n(p.baseActivity)&&p.relationship&&n(p.relationship.lunches)&&p.relationship.lunches<=3&&n(p.relationship.lastGoodDay)&&n(p.relationship.misses)&&['preferred','unlocked','rewarded'].every(k=>typeof p.relationship[k]==='boolean')&&p.trust&&p.kevTrust&&['morning','lunch'].every(k=>n(p.trust[k])&&p.trust[k]<=100&&n(p.kevTrust[k])&&p.kevTrust[k]<=100)&&p.visitHistory))return false;
  const planOK=p=>p&&ids.has(p.targetId)&&['morning','lunch'].includes(p.slot)&&typeof p.reason==='string'&&Array.isArray(p.route)&&p.route.length<=8&&p.route.every(id=>ids.has(id))&&Array.isArray(p.waitUntil)&&p.waitUntil.every(n)&&n(p.day);
  if(s.rival.plan&&!planOK(s.rival.plan))return false;
  if(s.forecast&&(!n(s.forecast.day)||!['Sunny','Scorcher','Showers'].includes(s.forecast.weather)||!n(s.forecast.supply)||!planOK(s.forecast.kev)))return false;
  return n(s.rival.cash)&&n(s.rival.security)&&s.rival.security<=2&&n(s.rival.grudge)&&Array.isArray(s.leads)&&s.leads.every(l=>typeof l.title==='string'&&typeof l.text==='string'&&(!l.stopId||ids.has(l.stopId)));
}
