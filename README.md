# Tower-Defense

[Open helper script: `open-readme.sh`](./open-readme.sh) — click to open the script in VS Code or your Markdown preview.

[Play the game (local): `play.html`](./play.html)

xdg-open http://127.0.0.1:8000/play.html


To run the playable page locally:

```bash
python3 -m http.server 8000 --directory /workspaces/Tower-Defense
# then open http://127.0.0.1:8000/play.html
```
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>Hydro Heroes — DOM Tower Defense</title>
<style>
  :root{
    --bg:#0f0f12;
    --lane:#14161b;
    --ui:#bdfcff;
    --good:#a7e8ff;   /* water */
    --good2:#6dd5ff;
    --evil:#65ff4b;   /* pollutants */
    --evil2:#2fd14a;
    --ring:#2a2e36;
    --hpGood:#56d1ff;
    --hpBad:#6dfc68;
    --hpBack:#2a2e36;
    --warn:#ffd66d;
    --win:#ffe07a;
    --lose:#ff7a7a;
  }
  *{box-sizing:border-box}
  html,body{height:100%}
  body{
    margin:0;
    font-family:Inter, system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif;
    background:var(--bg);
    color:#e9f6ff;
    display:flex;
    flex-direction:column;
    align-items:center;
    gap:10px;
    user-select:none;
  }

  /* HUD */
  .hud{
    width:min(1100px,96vw);
    margin-top:10px;
    display:grid;
    grid-template-columns:1fr auto 1fr;
    align-items:center;
    gap:10px;
  }
  .title{
    text-align:center;
    font-weight:900;
    letter-spacing:1px;
    font-size:clamp(22px,4vw,40px);
    color:var(--ui);
  }
  .bank{
    display:flex; gap:12px; align-items:center; justify-content:flex-start;
    font-weight:800;
  }
  .bank .pill{
    border:2px solid var(--ui);
    border-radius:999px;
    padding:.35rem .8rem;
    display:flex; align-items:center; gap:.5rem;
  }
  .bank small{opacity:.75; font-weight:600}
  .rightControls{
    display:flex; gap:8px; justify-content:flex-end; align-items:center;
  }
  button{
    background:transparent; color:var(--ui);
    border:2px solid var(--ui);
    border-radius:999px;
    padding:.4rem .8rem;
    font-weight:800; cursor:pointer;
  }
  button[disabled]{opacity:.45; cursor:not-allowed}
  .meter{
    height:10px; width:160px; border:2px solid var(--ui); border-radius:999px; position:relative;
    overflow:hidden;
  }
  .meter>span{position:absolute; inset:0; width:0%; background:linear-gradient(90deg,var(--good),var(--good2));}

  /* Playfield */
  .arena{
    width:min(1100px,96vw);
    aspect-ratio: 16 / 7;
    max-height: 68vh;
    background: radial-gradient(80% 120% at 50% 120%, #0b0c0f 0%, var(--lane) 60%);
    border:3px solid var(--ring);
    border-radius:16px;
    position:relative;
    overflow:hidden;
    box-shadow:0 24px 60px rgba(0,0,0,.35);
  }
  .ground{
    position:absolute; left:0; right:0; bottom:0; height:44%;
    background:linear-gradient(#15181f,#0c0e13);
    border-top:2px solid #1d212a;
  }
  .laneLine{
    position:absolute; left:4%; right:4%; top:54%;
    height:2px; background:#2a303a; border-radius:2px;
  }

  /* Bases */
  .base{
    position:absolute; bottom:25%; width:100px; height:140px; display:grid; place-items:center;
  }
  .base .tower{
    width:84px; height:120px; border-radius:18px;
    background:linear-gradient(180deg, #1e2430, #0f1218);
    border:3px solid #323846;
    position:relative;
    box-shadow:0 12px 24px rgba(0,0,0,.45);
  }
  .base.good{right:10px}
  .base.bad{left:10px}
  .dropTop, .pollutantTop{
    position:absolute; width:58px; height:58px; top:-22px; left:50%; transform:translateX(-50%);
    border-radius:50%;
    filter:drop-shadow(0 6px 4px rgba(0,0,0,.4));
  }
  .dropTop{ background: radial-gradient(circle at 35% 30%, #ffffff 0 12%, #bfefff 13% 25%, #8be2ff 26% 60%, #6dd5ff 61% 100%); }
  .pollutantTop{ background: radial-gradient(circle at 35% 30%, #d8ffd8 0 12%, #8dff76 13% 25%, #65ff4b 26% 60%, #2fd14a 61% 100%); }

  .hpbar{
    position:absolute; top:-14px; left:50%; transform:translateX(-50%);
    height:10px; width:96px; border:2px solid var(--ring); border-radius:8px;
    background:var(--hpBack); overflow:hidden;
  }
  .hpbar>span{position:absolute; inset:0; width:100%}
  .good .hpbar>span{background: linear-gradient(90deg, var(--hpGood), #7fe0ff)}
  .bad  .hpbar>span{background: linear-gradient(90deg, var(--hpBad), #aaff9f)}

  /* Units (DOM nodes that move) */
  .unit{
    position:absolute; bottom:34%; width:54px; height:54px; transform:translate(-50%,0);
    display:grid; place-items:center;
  }
  .ally{ z-index:4 }
  .enemy{ z-index:3 }

  /* water droplet look */
  .unit .sprite{
    width:50px; height:50px; border-radius:50%;
    border:2px solid rgba(255,255,255,.35);
    background: radial-gradient(circle at 35% 30%, #ffffff 0 12%, #c9f1ff 13% 25%, #9fe6ff 26% 60%, #6dd5ff 61% 100%);
    box-shadow:0 8px 10px rgba(0,0,0,.4);
  }
  .ally.tank .sprite{ width:58px; height:58px }
  .ally.ranger .sprite{ box-shadow:0 0 0 3px rgba(255,255,255,.15) inset, 0 8px 10px rgba(0,0,0,.4) }
  .ally.splasher .sprite{ background: radial-gradient(circle at 40% 25%, #fff 0 10%, #d2f4ff 11% 22%, #a7ecff 23% 55%, #56d1ff 56% 100%)}
  .ally.speedy .sprite{ width:46px; height:46px }

  /* pollutant look */
  .enemy .sprite{
    width:50px; height:50px; border-radius:50%;
    border:2px solid rgba(0,0,0,.32);
    background: radial-gradient(circle at 35% 30%, #d8ffd8 0 12%, #b9ff9f 13% 25%, #65ff4b 26% 60%, #2fd14a 61% 100%);
    box-shadow:0 8px 10px rgba(0,0,0,.45);
  }
  .enemy.big .sprite{ width:60px; height:60px }
  .enemy.spitter .sprite{ box-shadow:0 0 0 3px rgba(0,0,0,.18) inset, 0 8px 10px rgba(0,0,0,.45) }

  .bar{
    position:absolute; top:-10px; left:50%; transform:translateX(-50%);
    height:6px; width:46px; border-radius:6px; background:var(--hpBack); border:1px solid #2b2f39; overflow:hidden;
  }
  .bar>span{position:absolute; inset:0}
  .ally .bar>span{background:linear-gradient(90deg, var(--hpGood), #7fe0ff)}
  .enemy .bar>span{background:linear-gradient(90deg, var(--hpBad), #aaff9f)}

  /* Command panel */
  .panel{
    width:min(1100px,96vw);
    display:grid;
    grid-template-columns: repeat(4, 1fr) auto;
    gap:10px; padding:10px 0 18px 0;
  }
  .card{
    background:#11151c; border:2px solid #263041; border-radius:14px;
    padding:.6rem; display:flex; flex-direction:column; gap:.35rem; align-items:flex-start;
  }
  .card h4{margin:0; font-size:.98rem; color:#d4f4ff}
  .cost{font-weight:800; color:var(--warn)}
  .spawnBtn{
    margin-top:.2rem; width:100%; background:linear-gradient(#141a22,#0f141b); border-color:#4fd1ff; color:#c6f4ff
  }
  .spawnBtn[disabled]{opacity:.45}
  .note{opacity:.6; font-size:.86rem}
  .storage{
    display:flex; gap:10px; align-items:center; justify-content:flex-end;
  }
  .storage button{border-color:#ffd66d; color:#ffd66d}
  .storage small{opacity:.8}

  /* Overlay */
  .overlay{
    position:fixed; inset:0; display:none; place-items:center; background:rgba(0,0,0,.55); z-index:20;
  }
  .overlay .box{
    background:#10151d; border:3px solid #2a3344; border-radius:18px; padding:22px 26px; min-width:280px; text-align:center;
    box-shadow:0 30px 80px rgba(0,0,0,.45);
  }
  .overlay h2{margin:.4rem 0 .2rem; font-size:1.8rem}
  .overlay.win h2{color:var(--win)}
  .overlay.lose h2{color:var(--lose)}
  .overlay p{opacity:.8}
  .overlay.show{display:grid}
</style>
</head>
<body>
  <div class="hud">
    <div class="bank">
      <div class="pill">💧 Water: <span id="waterVal">0</span>/<span id="capVal">100</span></div>
      <div class="pill">Income: <span id="rateVal">3</span>/s</div>
      <div class="meter" title="Storage fill"><span id="meterFill"></span></div>
    </div>
    <div class="title">HYDRO&nbsp;HEROES</div>
    <div class="rightControls">
      <button id="pauseBtn">Pause</button>
      <button id="restartBtn">Restart</button>
    </div>
  </div>

  <div class="arena" id="arena" aria-label="battlefield">
    <div class="base bad" id="badBase">
      <div class="hpbar"><span id="badHP"></span></div>
      <div class="tower"></div>
      <div class="pollutantTop"></div>
    </div>
    <div class="base good" id="goodBase">
      <div class="hpbar"><span id="goodHP"></span></div>
      <div class="tower"></div>
      <div class="dropTop"></div>
    </div>
    <div class="laneLine"></div>
    <div class="ground"></div>
  </div>

  <div class="panel">
    <div class="card">
      <h4>Drip (cheap, fast)</h4>
      <div class="note">Quick melee poke.</div>
      <div class="cost">Cost: 15</div>
      <button class="spawnBtn" data-type="speedy">Spawn</button>
    </div>
    <div class="card">
      <h4>Bubble (tank)</h4>
      <div class="note">High HP, slow.</div>
      <div class="cost">Cost: 35</div>
      <button class="spawnBtn" data-type="tank">Spawn</button>
    </div>
    <div class="card">
      <h4>Sprinkler (ranged)</h4>
      <div class="note">Shoots from afar.</div>
      <div class="cost">Cost: 45</div>
      <button class="spawnBtn" data-type="ranger">Spawn</button>
    </div>
    <div class="card">
      <h4>Splash (AoE)</h4>
      <div class="note">Slow, splashes group.</div>
      <div class="cost">Cost: 60</div>
      <button class="spawnBtn" data-type="splasher">Spawn</button>
    </div>

    <div class="storage">
      <button id="upgradeBtn">Upgrade Storage (+50 cap, +1/s) – 40💧</button>
      <small id="upgradeInfo"></small>
    </div>
  </div>

  <!-- Overlay messages -->
  <div class="overlay" id="overlay">
    <div class="box">
      <h2 id="endTitle">Area Purified!</h2>
      <p id="endMsg">You defeated the pollutant horde.</p>
      <button id="playAgain">Play Again</button>
    </div>
  </div>

<script>
(() => {
  /************** Config **************/
  const arena = document.getElementById('arena');
  const W = () => arena.clientWidth;
  const GROUND_Y = 0; // we position via bottom %, so not used

  // Bases
  const baseGood = { el: document.getElementById('goodBase'), hpEl: document.getElementById('goodHP'), maxHP: 600, hp: 600, x: () => W() - 60 };
  const baseBad  = { el: document.getElementById('badBase'),  hpEl: document.getElementById('badHP'),  maxHP: 600, hp: 600,  x: () => 60 };

  // Economy
  let water = 0, capacity = 100, income = 3, upgradeCost = 40, upgrades = 0;
  const waterVal = document.getElementById('waterVal');
  const capVal   = document.getElementById('capVal');
  const rateVal  = document.getElementById('rateVal');
  const meterFill= document.getElementById('meterFill');
  const upgradeBtn = document.getElementById('upgradeBtn');
  const upgradeInfo= document.getElementById('upgradeInfo');

  // Overlay & controls
  const overlay = document.getElementById('overlay');
  const endTitle = document.getElementById('endTitle');
  const endMsg = document.getElementById('endMsg');
  const playAgain = document.getElementById('playAgain');
  const pauseBtn = document.getElementById('pauseBtn');
  const restartBtn = document.getElementById('restartBtn');

  // Ally buttons
  const spawnButtons = Array.from(document.querySelectorAll('.spawnBtn'));

  // Unit templates
  // speed in px/s, dps per second, range (0 = melee), aoeRadius (optional)
  const allyTypes = {
    speedy:  {name:'Drip',     class:'speedy',   hp: 55,  speed: 85,  dps: 14, range: 0,  cost:15},
    tank:    {name:'Bubble',   class:'tank',     hp: 180, speed: 45,  dps: 10, range: 0,  cost:35},
    ranger:  {name:'Sprinkler',class:'ranger',   hp: 70,  speed: 60,  dps: 18, range: 120,cost:45},
    splasher:{name:'Splash',   class:'splasher', hp: 120, speed: 40,  dps: 40, range: 40, aoe:60, atkInterval:0.9, cost:60},
  };
  const enemyTypes = {
    grub:    {name:'Grub',     class:'',         hp: 60,  speed: 70,  dps: 12, range: 0,  cost:10},
    glob:    {name:'Glob',     class:'big',      hp: 150, speed: 42,  dps: 12, range: 0,  cost:20},
    spitter: {name:'Spitter',  class:'spitter',  hp: 70,  speed: 55,  dps: 16, range: 110,cost:25},
    swarm:   {name:'Swarm',    class:'',         hp: 35,  speed: 95,  dps: 10, range: 0,  cost:8 },
  };
  const enemyPool = ['grub','glob','spitter','swarm'];

  // State
  let allies = []; // {el,x,side, type, ...}
  let enemies = [];
  let lastTime = performance.now();
  let paused = false;
  let gameOver = false;

  /************** Helpers **************/
  function clamp(v, a, b){ return Math.max(a, Math.min(b, v)); }
  function fmt(n){ return Math.floor(n); }
  function updateEconomyUI(){
    waterVal.textContent = fmt(water);
    capVal.textContent   = capacity;
    rateVal.textContent  = income;
    meterFill.style.width = `${(water/capacity)*100}%`;
    upgradeBtn.disabled = water < upgradeCost;
    upgradeInfo.textContent = `Upgrades: ${upgrades}`;
    // enable/disable spawn buttons based on cost
    spawnButtons.forEach(btn=>{
      const t = allyTypes[btn.dataset.type];
      btn.disabled = (water < t.cost) || gameOver || paused;
    });
  }
  function updateBaseHPBars(){
    baseGood.hpEl.style.width = `${(baseGood.hp/baseGood.maxHP)*100}%`;
    baseBad.hpEl.style.width  = `${(baseBad.hp/baseBad.maxHP)*100}%`;
  }

  function makeUnit(isAlly, tkey){
    const T = isAlly ? allyTypes[tkey] : enemyTypes[tkey];
    const el = document.createElement('div');
    el.className = `unit ${isAlly ? 'ally' : 'enemy'} ${T.class||''}`;
    el.style.left = (isAlly ? W()-120 : 120) + 'px';
    const bar = document.createElement('div'); bar.className='bar';
    const barFill = document.createElement('span'); bar.appendChild(barFill);
    const sprite = document.createElement('div'); sprite.className='sprite';
    el.appendChild(bar); el.appendChild(sprite);
    arena.appendChild(el);

    const u = {
      side: isAlly?'ally':'enemy',
      typeKey:tkey,
      T,
      el,
      barFill,
      hp:T.hp,
      maxHP:T.hp,
      x: isAlly ? W()-120 : 120,
      speed: T.speed,
      range: T.range||0,
      dps: T.dps,
      aoe: T.aoe||0,
      atkInterval: T.atkInterval || 0.5,
      atkCooldown: 0,
      fighting:false,
      target:null,
    };
    (isAlly?allies:enemies).push(u);
    return u;
  }
  function removeUnit(list, u){
    u.el.remove();
    const idx = list.indexOf(u);
    if(idx>=0) list.splice(idx,1);
  }
  function rectHit(a,b,dist=34){ return Math.abs(a.x - b.x) <= dist; }

  /************** Spawning **************/
  function spawnEnemyRandom(){
    if(gameOver || paused) return;
    // weighted simple choice
    const pick = enemyPool[Math.floor(Math.random()*enemyPool.length)];
    makeUnit(false, pick);
    // next spawn random 900–1700ms
    const next = 900 + Math.random()*800;
    setTimeout(spawnEnemyRandom, next);
  }

  // Player buttons
  spawnButtons.forEach(btn=>{
    btn.addEventListener('click', () => {
      const k = btn.dataset.type;
      const T = allyTypes[k];
      if(paused || gameOver) return;
      if(water >= T.cost){
        water -= T.cost;
        updateEconomyUI();
        makeUnit(true, k);
      }
    });
  });

  // Upgrades
  upgradeBtn.addEventListener('click', ()=>{
    if(water < upgradeCost || paused || gameOver) return;
    water -= upgradeCost;
    capacity += 50;
    income += 1;
    upgrades += 1;
    upgradeCost = Math.ceil(upgradeCost * 1.45);
    upgradeBtn.textContent = `Upgrade Storage (+50 cap, +1/s) – ${upgradeCost}💧`;
    updateEconomyUI();
  });

  pauseBtn.addEventListener('click', ()=>{
    paused = !paused;
    pauseBtn.textContent = paused ? 'Resume' : 'Pause';
    if(!paused) { lastTime = performance.now(); requestAnimationFrame(tick); }
  });
  restartBtn.addEventListener('click', resetGame);
  playAgain.addEventListener('click', ()=>{ overlay.classList.remove('show'); resetGame(); });

  /************** Combat **************/
  function tryAcquireTarget(u){
    const foes = u.side==='ally'? enemies : allies;
    // prefer nearest foe in front
    let best=null, bestD=1e9;
    for(const e of foes){
      const d = Math.abs(u.x - e.x);
      if(d < bestD && d <= (u.range?u.range:36)) { best=e; bestD=d; }
    }
    if(best){
      u.target = best;
      u.fighting = (u.range===0 ? rectHit(u,best,36) : bestD<=u.range);
    }else{
      u.target=null; u.fighting=false;
    }
  }
  function dealDamage(attacker, dt){
    if(!attacker.target) return;
    attacker.atkCooldown -= dt;
    if(attacker.atkCooldown <= 0){
      attacker.atkCooldown = attacker.atkInterval;
      const dmg = attacker.dps * attacker.atkInterval;
      if(attacker.aoe){
        const foes = attacker.side==='ally'? enemies : allies;
        for(const f of foes){
          if(Math.abs(f.x - attacker.target.x) <= attacker.aoe) {
            f.hp -= dmg;
            updateUnitHP(f);
          }
        }
      }else{
        attacker.target.hp -= dmg;
        updateUnitHP(attacker.target);
      }
    }
  }
  function updateUnitHP(u){
    u.barFill.style.width = `${clamp(u.hp/u.maxHP,0,1)*100}%`;
    if(u.hp <= 0){
      const list = (u.side==='ally')?allies:enemies;
      removeUnit(list, u);
    }
  }

  /************** Bases damage **************/
  function unitAttacksBase(u, base){
    u.atkCooldown -= frameDt;
    if(u.atkCooldown<=0){
      u.atkCooldown = u.atkInterval;
      base.hp -= u.dps * u.atkInterval;
      base.hp = Math.max(0, base.hp);
      updateBaseHPBars();
      if(base.hp<=0) endGame(base===baseBad ? 'win' : 'lose');
    }
  }

  /************** Economy & Loop **************/
  let econAccum = 0;
  let frameDt = 0;

  function gameStep(dt){
    econAccum += dt;
    if(econAccum >= 0.2){ // update every 0.2s
      water = Math.min(capacity, water + income * 0.2);
      econAccum = 0;
      updateEconomyUI();
    }

    // Move / fight Allies
    for(const u of allies){
      // If base in range (left base)
      if(u.x - baseBad.x() <= (u.range?u.range:46)){
        u.fighting = true;
        unitAttacksBase(u, baseBad);
      }else{
        tryAcquireTarget(u);
        if(u.target){
          // if ranged, keep distance; else stand and fight when touching
          const dist = Math.abs(u.x - u.target.x);
          if(u.range>0){
            if(dist>u.range) u.x -= u.speed * dt; // move closer
            else dealDamage(u, dt);
          }else{
            // melee: stop on contact
            if(dist<=36){ u.fighting=true; dealDamage(u, dt); }
            else u.x -= u.speed * dt;
          }
        }else{
          u.x -= u.speed * dt;
        }
      }
      u.el.style.left = `${u.x}px`;
    }

    // Move / fight Enemies
    for(const u of enemies){
      if(baseGood.x() - u.x <= (u.range?u.range:46)){
        u.fighting = true;
        unitAttacksBase(u, baseGood);
      }else{
        tryAcquireTarget(u);
        if(u.target){
          const dist = Math.abs(u.x - u.target.x);
          if(u.range>0){
            if(dist>u.range) u.x += u.speed * dt;
            else dealDamage(u, dt);
          }else{
            if(dist<=36){ u.fighting=true; dealDamage(u, dt); }
            else u.x += u.speed * dt;
          }
        }else{
          u.x += u.speed * dt;
        }
      }
      u.el.style.left = `${u.x}px`;
    }
  }

  function tick(now){
    if(paused || gameOver) return;
    frameDt = Math.min(0.05, (now - lastTime)/1000); // clamp to avoid jumps
    lastTime = now;
    gameStep(frameDt);
    requestAnimationFrame(tick);
  }

  function endGame(result){
    gameOver = true;
    overlay.classList.add('show');
    overlay.classList.remove('win','lose');
    if(result==='win'){
      overlay.classList.add('win');
      endTitle.textContent = 'Area Purified!';
      endMsg.textContent = 'Your droplets washed away the pollutants!';
    }else{
      overlay.classList.add('lose');
      endTitle.textContent = 'You Were Contaminated!';
      endMsg.textContent = 'The pollutant horde overwhelmed your base.';
    }
  }

  function clearUnits(){
    for(const u of allies) u.el.remove();
    for(const u of enemies) u.el.remove();
    allies.length=0; enemies.length=0;
  }

  function resetGame(){
    gameOver=false; paused=false;
    pauseBtn.textContent='Pause';
    clearUnits();
    baseGood.hp = baseGood.maxHP;
    baseBad.hp  = baseBad.maxHP;
    updateBaseHPBars();

    water = 30; capacity = 100; income = 3; upgradeCost=40; upgrades=0;
    upgradeBtn.textContent = `Upgrade Storage (+50 cap, +1/s) – ${upgradeCost}💧`;
    updateEconomyUI();

    overlay.classList.remove('show');
    lastTime = performance.now();
    requestAnimationFrame(tick);

    // start enemy spawns
    setTimeout(spawnEnemyRandom, 600);
  }

  // Initial UI and game start
  updateEconomyUI();
  updateBaseHPBars();
  resetGame();

  // Resize handling to keep starting positions sensible
  window.addEventListener('resize', ()=>{
    // snap units relatively; keep them where they are visually by updating left to numeric position already tracked
    allies.forEach(u=>u.el.style.left = `${u.x}px`);
    enemies.forEach(u=>u.el.style.left = `${u.x}px`);
  });
})();
</script>
</body>
</html>
