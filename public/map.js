import { EAST_DEPOT } from './strategy.js';
import { DEPOT, RIVAL_HQ, spot } from './engine.js';
export function drawMap(canvas, s, selectedVan, selectedStop) {
  const c = canvas.getContext('2d'); c.imageSmoothingEnabled = false;
  const rect = (x,y,w,h,col) => { c.fillStyle = col; c.fillRect(Math.round(x),Math.round(y),w,h); };
  rect(0,0,960,640,'#b5c797');
  // Deterministic little patches of scrub, rather than moving noise.
  for(let i=0;i<330;i++){ const x=(i*173+29)%960,y=(i*97+33)%640; rect(x,y,3+(i%3)*2,2,i%2?'#a9bd8a':'#bed09f'); }
  // The creek skirts the industrial estate.
  for(let y=0;y<640;y+=8){const x=920+Math.sin(y/80)*13;rect(x,y,40,8,'#8fafa1');rect(x-5,y,6,8,'#cbd5ac');rect(x+8,y,8,2,'#acc6b6');}
  const xs=[80,280,480,680,880], ys=[100,300,500];
  for(const x of xs){rect(x-18,70,36,465,'#8b927b');rect(x-12,70,24,465,'#6b7769');}
  for(const y of ys){rect(45,y-18,862,36,'#8b927b');rect(45,y-12,862,24,'#6b7769');}
  c.strokeStyle='#c2c7a8';c.lineWidth=2;c.setLineDash([8,13]);
  for(const x of xs){c.beginPath();c.moveTo(x,80);c.lineTo(x,520);c.stroke();}
  for(const y of ys){c.beginPath();c.moveTo(55,y);c.lineTo(900,y);c.stroke();}c.setLineDash([]);
  function tree(x,y,k=1){rect(x-2,y,4,12,'#7b7750');rect(x-10,y-12,20,17,'#617f4c');rect(x-6,y-19,13,20,'#719353');rect(x-8,y-11,7,9,'#85a361');if(k)rect(x+1,y-16,6,7,'#91ae6c');}
  for(let i=0;i<60;i++){const x=(i*137+130)%895,y=(i*79+159)%590;if(xs.every(a=>Math.abs(x-a)>33)&&ys.every(a=>Math.abs(y-a)>35))tree(x,y,i%3);}
  function building(x,y,w,h,roof,type){rect(x+6,y+8,w,h,'#8fa17a');rect(x,y+7,w,h,'#ded7ba');rect(x-3,y-2,w+6,h-10,roof);rect(x+2,y+3,w-4,4,'#ffffff22');rect(x+7,y+h-9,11,15,'#566658');for(let xx=x+25;xx<x+w-9;xx+=18)rect(xx,y+h-7,10,7,'#7e9c91');if(type==='Office'){rect(x+12,y+8,w-24,10,'#afc7bb');}else{for(let xx=x+6;xx<x+w;xx+=9)rect(xx,y+5,2,h-22,'#ffffff18');}}
  building(120,150,80,45,'#b6a88b',''); building(340,155,85,55,'#a2af99','Office'); building(740,155,76,45,'#c3b190',''); building(140,360,85,45,'#bd9e80',''); building(540,370,75,50,'#8d9e89','Office');building(735,365,86,50,'#a9a38c','');
  // Oval and cricket pitch.
  c.fillStyle='#a0ba80';c.beginPath();c.ellipse(375,395,59,42,0,0,7);c.fill();c.strokeStyle='#d4dcad';c.lineWidth=2;c.stroke();rect(367,378,16,35,'#ccc49a');rect(365,382,20,2,'#ede6c8');rect(365,407,20,2,'#ede6c8');
  c.font='bold 9px monospace';c.fillStyle='#6b825b';c.textAlign='center';c.fillText('WATTLE OVAL',375,455);
  // Selected van's route follows the same axis-aligned roads as the simulation.
  const v=s.vans.find(v=>v.id===selectedVan)||s.vans[0];let prev=spot(s,v.home||'depot');
  c.strokeStyle='#314f3b';c.lineWidth=7;c.lineJoin='round';c.beginPath();c.moveTo(prev.x,prev.y);
  for(const id of v.route){const p=spot(s,id);c.lineTo(p.x,prev.y);c.lineTo(p.x,p.y);prev=p;}c.stroke();
  prev=spot(s,v.home||'depot');c.strokeStyle='#dcec9d';c.lineWidth=3;c.setLineDash([6,5]);c.beginPath();c.moveTo(prev.x,prev.y);for(const id of v.route){const p=spot(s,id);c.lineTo(p.x,prev.y);c.lineTo(p.x,p.y);prev=p;}c.stroke();c.setLineDash([]);
  function label(text,x,y,bg='#f6f0d7',fg='#344438'){c.font='bold 11px monospace';const w=c.measureText(text).width+16;rect(x-w/2+2,y+2,w,21,'#57684c44');rect(x-w/2,y,w,21,bg);c.fillStyle=fg;c.textAlign='center';c.fillText(text,x,y+14);}
  for(const p of s.stops){const px=p.x,py=p.y;const mine=p.loyalty>p.rival;building(px-39,py-76,76,47,p.type==='Office'?'#8fa99b':p.type==='Construction'?'#c7aa70':'#a89c85',p.type);if(p.type==='Construction'){rect(px-42,py-87,84,4,'#b49b54');rect(px+28,py-100,4,45,'#a99550');rect(px-28,py-85,2,23,'#777d56');}c.strokeStyle=p.id===selectedStop?'#f9d15c':mine?'#e5f3b3':'#b96951';c.lineWidth=p.id===selectedStop?4:2;c.beginPath();c.arc(px,py,12,0,7);c.stroke();rect(px-5,py-5,10,10,mine?'#456e45':'#bd775e');label(p.name.toUpperCase(),px,py+24);c.font='9px monospace';c.fillStyle='#42563d';c.fillText(`${p.type.toUpperCase()} · ${Math.round(p.people*p.activity)} CREW`,px,py+59);const order=v.route.indexOf(p.id);if(order>=0){rect(px+23,py-61,18,18,'#e8c659');c.fillStyle='#324432';c.font='bold 12px monospace';c.fillText(order+1,px+32,py-48);}}
  building(DEPOT.x-34,DEPOT.y-70,68,44,'#4f7960','');rect(DEPOT.x-21,DEPOT.y-40,42,23,'#304a3d');label('YOUR DEPOT',80,540,'#294d38','#e7efb3');building(RIVAL_HQ.x-36,RIVAL_HQ.y-72,72,44,'#a9644e','');label('BIG KEV’S HQ',680,540,'#a65b48','#fff1d6');
  if(s.depots?.east){building(EAST_DEPOT.x-34,EAST_DEPOT.y-70,68,44,'#4f7960','');label('EASTSIDE DEPOT',EAST_DEPOT.x,EAST_DEPOT.y+26,'#294d38','#e7efb3');}
  function van(x,y,color,name){rect(x-16,y-7,35,20,'#3d4d3e66');rect(x-18,y-13,34,19,color);rect(x-20,y-10,8,15,color);rect(x+8,y-10,8,11,'#4e6b64');rect(x-16,y-10,20,5,'#fff5d4');rect(x-15,y+4,7,5,'#2e3a32');rect(x+8,y+4,7,5,'#2e3a32');rect(x-12,y-2,12,4,'#6d7955');if(name){c.font='bold 8px monospace';c.fillStyle='#213d2a';c.textAlign='center';c.fillText(name,x,y-19);}}
  van(s.rival.x,s.rival.y,'#c16f51','KEV');for(const vv of s.vans)van(vv.x,vv.y,vv.type==='espresso'?'#a7d9bf':vv.type==='lunch'?'#e7a26c':'#f1cf67',vv.id===selectedVan?'YOUR VAN':`VAN ${vv.id}`);
  c.textAlign='left';
}
