import test from 'node:test';
import assert from 'node:assert/strict';
import { newGame as createGame, startDay, tick, schedule, loadSize, loadCost, restock, nextDay, battleAction, resolveBattle, buyVan, validateSave, demand, PRODUCTS } from '../public/engine.js';

const newGame = (seed = 43) => createGame(seed);

function playDay(s) {
  for (let i=0; i<2000 && s.phase==='running'; i++) {
    if(s.battle) {
      for(let n=0;n<50&&!s.battle.result;n++) battleAction(s,s.battle.energy>=2?'pie':'punch');
      assert.ok(s.battle.result, 'Combat must terminate'); resolveBattle(s);
    } else tick(s);
  }
  assert.equal(s.phase,'summary');
}
test('loading spends actual purchase cost once and rejects overload',()=>{
  const s=newGame(),v=s.vans[0];v.load.coffee=200;
  assert.match(startDay(s),/overloaded/);assert.equal(s.cash,1200);
  v.load.coffee=44;assert.equal(loadSize(v.load),120);
  const cost=loadCost(s,v.load)+43;assert.equal(startDay(s),null);assert.equal(s.cash,1200-cost);
  const cash=s.cash;assert.match(startDay(s),/already/);assert.equal(s.cash,cash);
});
test('route forecasts include travel and service; depot detours propagate',()=>{
  const s=newGame(),v=s.vans[0];const base=schedule(s,v);
  assert.equal(base[0].at,500);assert.equal(base[1].at,524);
  v.route.splice(1,0,'depot');const detour=schedule(s,v);
  assert.ok(detour[2].at>base[1].at);assert.equal(detour[1].until-detour[1].at,12);
});
test('demand distinguishes morning and lunch preferences',()=>{
  const s=newGame(),p=s.stops.find(p=>p.id==='office');
  assert.ok(demand(s,p,PRODUCTS[0],p.coffeeAt)>demand(s,p,PRODUCTS[0],p.lunchAt));
  assert.ok(demand(s,p,PRODUCTS[2],p.lunchAt)>demand(s,p,PRODUCTS[2],p.coffeeAt));
});
test('earliest arrival waits for lunch without selling early',()=>{
  const s=newGame(),v=s.vans[0];v.route=['office'];v.waitUntil=[720];s.rival.route=[];
  assert.equal(schedule(s,v)[0].at,720);startDay(s);
  while(s.time<719)tick(s);
  assert.equal(v.stage,'waiting-stop');assert.equal(v.revenue,0);
  playDay(s);assert.ok(v.revenue>0);
});
test('default day includes sales, a rival dispute, finite cash and a recoverable tomorrow',()=>{
  const s=newGame();startDay(s);playDay(s);
  assert.ok(s.today.revenue>0);assert.ok(s.today.fights>0);
  assert.ok(Number.isFinite(s.cash));assert.equal(s.summary.profit,s.today.revenue-s.today.costs);
  for(const v of s.vans)for(const n of Object.values(v.stock))assert.ok(n>=0);
  const route=[...s.vans[0].route];nextDay(s);assert.equal(s.day,2);assert.equal(s.phase,'planning');assert.deepEqual(s.vans[0].route,route);
  assert.equal(Object.values(s.vans[0].stock).reduce((a,b)=>a+b),0);assert.ok(validateSave(s));
});
test('pausing and battle decisions freeze business time',()=>{
  const s=newGame();startDay(s);s.paused=true;tick(s);assert.equal(s.time,480);s.paused=false;
  for(let i=0;i<300&&!s.battle;i++)tick(s);assert.ok(s.battle);
  const time=s.time;tick(s);assert.equal(s.time,time);battleAction(s,'guard');assert.equal(s.time,time);
});
test('restock returns to the same pending route stop and charges for missing stock only',()=>{
  const s=newGame();startDay(s);s.rival.next=900;const v=s.vans[0];
  for(let i=0;i<40;i++)tick(s);
  const index=v.index;v.stock.coffee=0;const cash=s.cash;assert.equal(restock(s,v),null);
  for(let i=0;i<200&&v.returning;i++)tick(s);
  assert.equal(v.index,index);assert.ok(v.stock.coffee>0);assert.ok(s.cash<cash);
});
test('multiple vans run independent routes and survive repeated days',()=>{
  const s=newGame();s.cash=4000;assert.equal(buyVan(s),null);assert.equal(s.vans.length,2);
  for(let d=0;d<6;d++){assert.equal(startDay(s),null);playDay(s);assert.ok(validateSave(JSON.parse(JSON.stringify(s))));nextDay(s);}
  assert.equal(s.day,7);assert.ok(s.cash>=0);
});
test('malformed saves and unknown stop IDs are rejected',()=>{
  assert.equal(validateSave(null),false);const s=newGame();s.vans[0].route.push('missing');assert.equal(validateSave(s),false);
});
test('opening battle favours the player without guaranteeing a win',()=>{
  let wins=0;
  for(let seed=1;seed<=2000;seed++){
    const s=newGame();s.seed=seed;startDay(s);
    while(!s.battle)tick(s);
    while(!s.battle.result)battleAction(s,s.battle.energy>=2?'pie':'punch');
    wins+=s.battle.result==='win';
  }
  const rate=wins/2000;
  console.log(`Baseline combat: ${wins}/2000 wins (${(rate*100).toFixed(1)}%)`);
  assert.ok(rate>=.75&&rate<=.9);
});
test('combat produces misses, weak blows, heavy hits and player criticals',()=>{
  const seen=new Set();
  for(let seed=1;seed<=250;seed++){
    const s=newGame(seed);startDay(s);while(!s.battle)tick(s);
    while(!s.battle.result){
      battleAction(s,s.battle.energy>=2?'pie':'punch');
      for(const phrase of ['Complete miss','barely clips','massive hit','Critical'])if(s.battle.message.includes(phrase))seen.add(phrase);
      assert.ok(s.battle.hp>=0&&s.battle.enemy>=0);
    }
  }
  assert.equal(seen.size,4);
});
test('an emu prevents retaliation and guarding reduces the same random hit',()=>{
  const s=newGame();startDay(s);while(!s.battle)tick(s);
  const hp=s.battle.hp;battleAction(s,'emu');assert.equal(s.battle.hp,hp);
  // Compare the same enemy random roll: an existing guard against a normal punch.
  s.battle.energy=3;const guarded=structuredClone(s);guarded.battle.guard=true;
  battleAction(s,'punch');battleAction(guarded,'punch');
  assert.ok(guarded.battle.hp>=s.battle.hp);
});
test('restocking from a vertical road never drives across a building block',()=>{
  const s=newGame();s.vans[0].route=['office'];s.rival.route=[];startDay(s);const v=s.vans[0];
  while(!(v.stage==='driving'&&v.y<500&&v.y>300))tick(s);
  restock(s,v);
  while(v.stage==='driving'){tick(s);assert.ok([80,280,480,680,880].includes(v.x)||[100,300,500].includes(v.y));}
});
test('saving midway through combat preserves a valid battle and simulation',()=>{
  const s=newGame();startDay(s);while(!s.battle)tick(s);battleAction(s,'emu');
  const copy=JSON.parse(JSON.stringify(s));assert.ok(validateSave(copy));assert.deepEqual(copy.battle,s.battle);
  playDay(copy);assert.ok(copy.summary);
  copy.summary=null;assert.equal(validateSave(copy),false);
});
test('end-of-day product quantities reconcile across vans and survive a save',()=>{
  const s=newGame();s.cash=4000;buyVan(s);
  const loaded=Object.fromEntries(PRODUCTS.map(p=>[p.id,s.vans.reduce((n,v)=>n+v.load[p.id],0)]));
  startDay(s);playDay(s);
  for(const p of PRODUCTS){
    assert.equal(s.summary.soldByProduct[p.id]+s.summary.leftByProduct[p.id],loaded[p.id]);
    assert.equal(s.summary.leftByProduct[p.id],s.vans.reduce((n,v)=>n+v.stock[p.id],0));
  }
  assert.equal(Object.values(s.summary.soldByProduct).reduce((a,b)=>a+b,0),s.summary.customers);
  assert.equal(Object.values(s.summary.leftByProduct).reduce((a,b)=>a+b,0),s.summary.waste);
  const copy=JSON.parse(JSON.stringify(s));assert.ok(validateSave(copy));
  assert.deepEqual(copy.summary,s.summary);nextDay(copy);
  assert.ok(Object.values(copy.today.soldByProduct).every(n=>n===0));
  assert.ok(Object.values(s.summary.soldByProduct).some(n=>n>0));
});
test('restocked items are counted as sales only when actually sold',()=>{
  const s=newGame(),v=s.vans[0];s.rival.route=[];v.route=['workshop','depot','site'];startDay(s);
  while(v.stage!=='loading')tick(s);
  const firstSales={...s.today.soldByProduct};
  assert.equal(Object.values(firstSales).reduce((a,b)=>a+b,0),v.sold);
  for(const p of PRODUCTS)assert.equal(v.stock[p.id],v.load[p.id]);
  playDay(s);
  for(const p of PRODUCTS)assert.equal(s.summary.soldByProduct[p.id]+s.summary.leftByProduct[p.id],v.load[p.id]+firstSales[p.id]);
});
test('older saves remain compatible without inventing historical product sales',()=>{
  const s=newGame();delete s.today.soldByProduct;startDay(s);playDay(s);
  assert.ok(s.summary.soldByProduct);
  const legacy=newGame();legacy.today.customers=5;delete legacy.today.soldByProduct;
  startDay(legacy);playDay(legacy);assert.equal(legacy.summary.soldByProduct,undefined);
  assert.ok(legacy.summary.leftByProduct);assert.ok(validateSave(legacy));nextDay(legacy);
  assert.ok(Object.values(legacy.today.soldByProduct).every(n=>n===0));
});
test('stop feedback names even a one-item shortage instead of reporting good service',()=>{
  const setup=()=>{const s=newGame();s.rival.route=[];const v=s.vans[0];v.route=['workshop'];v.capacity=300;v.load={coffee:50,pie:50,wrap:50,iced:50};return s;};
  const reference=setup();startDay(reference);playDay(reference);
  const s=setup();s.vans[0].load.coffee=reference.summary.soldByProduct.coffee-1;startDay(s);playDay(s);
  const feedback=s.feed.find(f=>f.text.startsWith('Spanner & Sons:'));
  assert.match(feedback.text,/Flat whites ran out — sales lost/);
  assert.doesNotMatch(feedback.text,/Meat pies|Salad wraps|Iced coffee|Right on time|more wanted/);
  assert.equal(feedback.kind,'warn');
});
test('feedback lists multiple shortages but does not mistake empty stock for unmet demand',()=>{
  const s=newGame();s.rival.route=[];s.vans[0].route=['workshop'];s.vans[0].load={coffee:0,pie:0,wrap:0,iced:0};
  startDay(s);playDay(s);
  const feedback=s.feed.find(f=>f.text.startsWith('Spanner & Sons:'));
  assert.match(feedback.text,/Flat whites/);
  assert.match(feedback.text,/Meat pies/);
  assert.match(feedback.text,/Iced coffee/);
  assert.match(feedback.text,/ran out — sales lost/);
  assert.doesNotMatch(feedback.text,/more wanted/);
  const quiet=newGame();quiet.rival.route=[];quiet.vans[0].route=['workshop'];quiet.vans[0].waitUntil=[850];quiet.vans[0].load={coffee:0,pie:0,wrap:0,iced:0};
  startDay(quiet);playDay(quiet);
  assert.doesNotMatch(quiet.feed.find(f=>f.text.startsWith('Spanner & Sons:')).text,/ran out|sales lost/);
});
