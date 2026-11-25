import test from 'node:test';
import assert from 'node:assert/strict';
import { newGame, startDay, tick, battleAction, resolveBattle, nextDay, schedule, travel, demand, PRODUCTS, validateSave, planOperation } from '../public/engine.js';
import { migrateStrategy, recordVisit, settleRelationships, businessAt, planKev, orderInvestment, cancelInvestment, spec, runningCost, serviceMinutes, EAST_DEPOT, forecastTomorrow } from '../public/strategy.js';
function run(s){assert.equal(startDay(s),null);for(let i=0;i<2000&&s.phase==='running';i++){if(s.battle){while(!s.battle.result)battleAction(s,s.battle.energy>=2?'pie':'punch');resolveBattle(s);}else tick(s);}assert.equal(s.phase,'summary');}
const good = {sold:20,wanted:20,products:{coffee:2,pie:9,wrap:5,iced:4},at:735};

test('three distinct reliable lunch days unlock preferred service, morning trust and one bonus',()=>{
  const s=newGame(42),p=s.stops.find(p=>p.id==='factory');const trust=p.trust.morning,cash=s.cash;
  for(let day=1;day<=3;day++){s.day=day;recordVisit(s,p,'lunch',good);recordVisit(s,p,'lunch',good);assert.equal(p.relationship.lunches,day);}
  assert.ok(p.relationship.preferred);assert.equal(p.trust.morning,trust+18);assert.equal(s.cash,cash+100);
  s.day++;recordVisit(s,p,'lunch',good);assert.equal(s.cash,cash+100);
  s.day++;settleRelationships(s);assert.ok(p.relationship.preferred);s.day++;settleRelationships(s);assert.equal(p.relationship.preferred,false);
  s.day++;recordVisit(s,p,'lunch',good);assert.ok(p.relationship.preferred);assert.equal(s.cash,cash+100);
});
test('wrong food, lateness and shortages do not advance an office relationship',()=>{
  const s=newGame(42),p=s.stops.find(p=>p.id==='office');
  recordVisit(s,p,'lunch',{...good,at:p.lunchAt,products:{coffee:10,pie:10,wrap:0,iced:0}});
  recordVisit(s,p,'lunch',{...good,at:p.lunchAt+30});
  recordVisit(s,p,'lunch',{...good,at:p.lunchAt,sold:10});
  assert.equal(p.relationship.lunches,0);recordVisit(s,p,'lunch',{...good,at:p.lunchAt});assert.equal(p.relationship.lunches,1);
});
test('actual three-day lunch trading earns the relationship and preserves it through saves',()=>{
  let s=newGame(9);const v=s.vans[0];v.route=['office'];v.waitUntil=[750];v.load={coffee:10,pie:4,wrap:30,iced:20};
  for(let day=0;day<3;day++) {s.rival.route=[];run(s);assert.ok(validateSave(s));if(day<2){s=JSON.parse(JSON.stringify(s));nextDay(s);}}
  const p=s.stops.find(p=>p.id==='office');assert.equal(p.relationship.lunches,3);assert.ok(p.relationship.preferred);assert.equal(s.summary.bonuses,100);
});
test('distant prime coffee stops cannot fit the same reliable window',()=>{
  const s=newGame(1),v=s.vans[0];v.route=['yard','office','clinic'];v.depart=530;v.waitUntil=[];
  const rows=schedule(s,v);assert.ok(rows.some(p=>Math.abs(p.at-p.coffeeAt)>15));
  const clinic=s.stops.find(p=>p.id==='clinic');assert.equal(demand(s,clinic,PRODUCTS[0],clinic.coffeeAt+50),0);
});
test('specialists have real speed, capacity, premium and food storage tradeoffs',()=>{
  const s=newGame(1),v=s.vans[0],office=s.stops.find(p=>p.id==='office');
  const ordinary=travel({x:80,y:500},office,v);v.type='espresso';assert.ok(travel({x:80,y:500},office,v)<ordinary);
  v.type='lunch';assert.ok(travel({x:80,y:500},office,v)>ordinary);assert.ok(runningCost(v)>43);
  v.type='espresso';v.load={coffee:10,pie:11,wrap:0,iced:0};assert.match(startDay(s),/20 food spaces/);
  v.crew='fast';assert.equal(serviceMinutes(v),8);assert.equal(runningCost(v),88);
});
test('depot and van orders arrive tomorrow, charge once and unlock eastern routes',()=>{
  const s=newGame(8);s.cash=5000;assert.equal(orderInvestment(s,'van','espresso'),null);assert.equal(orderInvestment(s,'depot'),null);
  assert.equal(s.vans.length,1);assert.equal(s.depots.east,false);const cash=s.cash;
  assert.match(orderInvestment(s,'depot'),/already/);assert.equal(s.cash,cash);
  run(s);const announced=s.forecast.weather;nextDay(s);assert.equal(s.weather,announced);
  assert.equal(s.vans.length,2);assert.ok(s.depots.east);assert.equal(s.orders.length,0);
  const v=s.vans[1];assert.equal(v.type,'espresso');assert.equal(v.capacity,100);assert.equal(v.route.length,0);
  v.route=['clinic'];v.home='east-depot';const east=schedule(s,v)[0].at;v.home='depot';assert.ok(east<schedule(s,v)[0].at);
  v.home='east-depot';v.route=['clinic','east-depot','shed'];assert.ok(validateSave(s));run(s);assert.ok(validateSave(s));
});
test('Kev targets service gaps and switches to lunch when mornings are strong',()=>{
  const s=newGame(4),p=s.stops.find(p=>p.id==='clinic');p.visitHistory.morning={day:s.day,reliable:false,shortage:true};
  assert.equal(planKev(s).targetId,'clinic');
  delete p.visitHistory.morning;for(const p of s.stops){p.trust.morning=75;p.trust.lunch=10;}
  assert.equal(planKev(s).slot,'lunch');
  for(const p of s.stops){p.trust.morning=85;p.trust.lunch=85;}s.stops[0].trust.lunch=20;assert.equal(planKev(s).targetId,s.stops[0].id);
});
test('Kev countermeasures are announced and paid for; stock and cash are finite',()=>{
  const s=newGame(5);assert.equal(planOperation(s,'emu'),null);const plan=planKev(s);assert.ok(plan.security);s.rival.plan=plan;
  const cash=s.rival.cash;assert.equal(startDay(s),null);assert.equal(s.rival.security,1);assert.ok(s.rival.cash<cash-120);
  assert.ok(Object.values(s.rival.stock).every(n=>Number.isInteger(n)&&n>=0));
  const poor=newGame(2);poor.rival.cash=5;startDay(poor);assert.ok(Object.values(poor.rival.stock).every(n=>n===0));assert.equal(poor.rival.cash,0);
});
test('announced business events and weather match tomorrow and survive reload',()=>{
  const s=newGame(2);s.day=s.chapterStart+2;run(s);const tomorrow=structuredClone(s.forecast);
  assert.ok(s.summary.leads.some(l=>l.stopId==='site'&&l.kind==='town'));
  const copy=JSON.parse(JSON.stringify(s));nextDay(copy);assert.equal(copy.weather,tomorrow.weather);assert.equal(copy.supply,tomorrow.supply);assert.deepEqual(copy.rival.route,tomorrow.kev.route);
  assert.equal(copy.stops.find(p=>p.id==='site').activity,1.8);
  const p=copy.stops.find(p=>p.id==='site');assert.equal(businessAt(copy,p,s.chapterStart+12).activity,0);
});
test('legacy games migrate without losing money, route, progress or battle',()=>{
  const s=newGame(7);startDay(s);while(!s.battle)tick(s);const cash=s.cash,battle=structuredClone(s.battle),route=[...s.vans[0].route];
  delete s.strategyVersion;for(const p of s.stops){delete p.relationship;delete p.trust;delete p.kevTrust;}
  assert.ok(validateSave(s));migrateStrategy(s);assert.equal(s.cash,cash);assert.deepEqual(s.battle,battle);assert.deepEqual(s.vans[0].route,route);assert.ok(validateSave(s));assert.ok(s.windowsPending);
  const copy=structuredClone(s);migrateStrategy(s);assert.deepEqual(s,copy);
});
test('twenty days of expansion stay playable and preserve strategic saves',()=>{
  let s=newGame(120);s.cash=6000;orderInvestment(s,'van','lunch');orderInvestment(s,'depot');
  for(let day=0;day<20;day++){
    if(s.vans.length>1){s.vans[1].route=['factory','shed'];s.vans[1].waitUntil=[735,800];s.vans[1].home='east-depot';}
    run(s);assert.ok(validateSave(s),`valid summary day ${s.day}`);assert.ok(s.cash>=0);assert.ok(s.rival.cash>=0);
    s=JSON.parse(JSON.stringify(s));nextDay(s);assert.ok(validateSave(s),`valid planning day ${s.day}`);
  }
});

test('pending investments can be refunded to recover operating cash',()=>{
  const s=newGame(42),cash=s.cash,costs=s.today.costs;
  assert.equal(orderInvestment(s,'van','espresso'),null);
  assert.equal(cancelInvestment(s,0),null);
  assert.equal(s.cash,cash);assert.equal(s.today.costs,costs);assert.equal(s.orders.length,0);
  assert.ok(cancelInvestment(s,0));assert.equal(s.cash,cash);
});
