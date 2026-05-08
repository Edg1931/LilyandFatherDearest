import {
  TIERS, TIER_NEXT, TIER_VISUAL, BOND_MAX, BOND_THRESHOLDS, TIER_ROLL_BASE, TIER_ROLL_CAP,
  BREEDS, QUESTS, NPCS, SHELTER_SEED_STRAYS, rollBreedByRarity,
} from "./data.js";

// ===== State =====
const SAVE_KEY = "pawprint_web_v1";
const VET_PRICE = 50_000;

const state = {
  player: { x: 300, y: 300, vx: 0, vy: 0, speed: 180 },
  profile: null,
  world: {
    npcs: NPCS.map(n => ({ ...n })),
    questEntities: [],
  },
  active: { quest: null, objectives: {} },
  ui: {
    dialogNpc: null,
    nearbyNpc: null,
    nearbyEntity: null,
    panel: null,
  },
  cameraOffset: { x: 0, y: 0 },
  followers: [],
};

function emptyProfile() {
  return {
    coins: 250, treats: 5,
    dogs: {},
    discoveredBreeds: {},
    followers: [],
    questsDone: [],
    grooming: { lastGroomedAt: 0, streak: 0 },
    rollChargesByDog: {},
    house: { displayed: [] },
    shelter: { owned: false, strays: [], intakeTotals: 0, adoptOutTotals: 0 },
    seenIntro: false,
  };
}

function load() {
  try {
    const raw = localStorage.getItem(SAVE_KEY);
    if (!raw) return null;
    const p = JSON.parse(raw);
    if (!p || typeof p !== "object") return null;
    return Object.assign(emptyProfile(), p);
  } catch { return null; }
}

let saveScheduled = false;
function save() {
  if (saveScheduled) return;
  saveScheduled = true;
  setTimeout(() => {
    saveScheduled = false;
    try { localStorage.setItem(SAVE_KEY, JSON.stringify(state.profile)); }
    catch (e) { console.warn("save failed", e); }
  }, 250);
}

function uid() {
  return Math.random().toString(36).slice(2, 10) + Date.now().toString(36).slice(-4);
}

function addDog(breedId, tier = "Regular", bond = 0) {
  const dog = {
    id: uid(),
    breed: breedId,
    tier,
    bond,
    groomingStreak: 0,
    createdAt: Date.now(),
  };
  state.profile.dogs[dog.id] = dog;
  state.profile.discoveredBreeds[breedId] = true;
  save();
  return dog;
}

function ensureSeed() {
  if (Object.keys(state.profile.dogs).length === 0) {
    const starterPool = ["golden_retriever", "labrador", "beagle", "pug", "dachshund"];
    const breed = starterPool[Math.floor(Math.random() * starterPool.length)];
    const dog = addDog(breed, "Regular", 50);
    state.profile.followers = [dog.id];
    save();
  }
}

function activeDog() {
  const id = state.profile.followers[0];
  return id ? state.profile.dogs[id] : null;
}

// ===== Canvas =====
const canvas = document.getElementById("world");
const ctx = canvas.getContext("2d");

const WORLD = { w: 1200, h: 900 };

function resizeCanvas() {
  const dpr = window.devicePixelRatio || 1;
  canvas.width = window.innerWidth * dpr;
  canvas.height = window.innerHeight * dpr;
  canvas.style.width = window.innerWidth + "px";
  canvas.style.height = window.innerHeight + "px";
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
}
window.addEventListener("resize", resizeCanvas);
resizeCanvas();

// ===== World rendering =====
const REGIONS = [
  { name: "house",   color: "#f0c879", x: 150, y: 150, w: 200, h: 160, label: "🏡 Home" },
  { name: "park",    color: "#7ab86a", x: 380, y: 180, w: 280, h: 220, label: "🌳 Park" },
  { name: "bakery",  color: "#d8a070", x: 760, y: 160, w: 260, h: 280, label: "🥐 Bakery" },
  { name: "meadow",  color: "#8acc78", x: 130, y: 420, w: 240, h: 220, label: "🌾 Meadow" },
  { name: "river",   color: "#4a8fc8", x: 420, y: 620, w: 360, h: 60,  label: "" },
  { name: "bridge",  color: "#a8a890", x: 510, y: 600, w: 80,  h: 100, label: "🌉 Bridge" },
  { name: "shelter", color: "#c0d8e8", x: 820, y: 480, w: 180, h: 140, label: "🏥 Vet" },
];

function regionAt(x, y) {
  for (const r of REGIONS) {
    if (x >= r.x && x <= r.x + r.w && y >= r.y && y <= r.y + r.h) return r;
  }
  return null;
}

function drawWorld() {
  ctx.fillStyle = "#5a9a4c";
  ctx.fillRect(0, 0, window.innerWidth, window.innerHeight);

  const camX = state.cameraOffset.x;
  const camY = state.cameraOffset.y;

  for (const r of REGIONS) {
    ctx.fillStyle = r.color;
    ctx.fillRect(r.x - camX, r.y - camY, r.w, r.h);
    if (r.label) {
      ctx.fillStyle = "rgba(255,255,255,0.85)";
      ctx.font = "bold 14px system-ui";
      ctx.textAlign = "left";
      ctx.fillText(r.label, r.x - camX + 8, r.y - camY + 18);
    }
  }

  // Quest entities (gold beams)
  const t = performance.now() / 400;
  for (const e of state.world.questEntities) {
    if (e.consumed) continue;
    const sx = e.x - camX, sy = e.y - camY;
    const pulse = 0.5 + 0.3 * Math.sin(t + e.x);
    ctx.fillStyle = `rgba(255, 215, 80, ${pulse})`;
    ctx.beginPath();
    ctx.arc(sx, sy, 18, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = "rgba(255, 215, 80, 0.95)";
    ctx.beginPath();
    ctx.arc(sx, sy, 8, 0, Math.PI * 2);
    ctx.fill();
    if (e.kind === "findItem") {
      ctx.font = "20px serif";
      ctx.textAlign = "center";
      ctx.fillStyle = "white";
      ctx.fillText("📦", sx, sy + 6);
    }
    if (e.kind === "scentTrail") {
      ctx.font = "16px serif";
      ctx.textAlign = "center";
      ctx.fillStyle = "white";
      ctx.fillText(String(e.ord), sx, sy + 5);
    }
    if (e.kind === "digSpot") {
      ctx.font = "16px serif";
      ctx.textAlign = "center";
      ctx.fillStyle = "white";
      ctx.fillText("🦴", sx, sy + 5);
    }
  }

  // NPCs
  for (const npc of state.world.npcs) {
    const sx = npc.x - camX, sy = npc.y - camY;
    ctx.font = "30px serif";
    ctx.textAlign = "center";
    ctx.fillText(npc.emoji, sx, sy);
    if (state.ui.nearbyNpc === npc) {
      ctx.fillStyle = "rgba(255,255,255,0.9)";
      ctx.beginPath();
      ctx.arc(sx, sy + 10, 18, 0, Math.PI * 2, false);
      ctx.lineWidth = 2;
      ctx.strokeStyle = "white";
      ctx.stroke();
    }
  }

  // Followers
  state.followers.forEach((f, i) => {
    const dog = state.profile.dogs[f.dogId];
    if (!dog) return;
    const breed = BREEDS[dog.breed];
    const sx = f.x - camX, sy = f.y - camY;
    const visual = TIER_VISUAL[dog.tier];
    if (visual.ring !== "transparent") {
      ctx.beginPath();
      ctx.arc(sx, sy + 4, 18, 0, Math.PI * 2);
      ctx.strokeStyle = visual.ring;
      ctx.lineWidth = 3;
      ctx.shadowColor = visual.ring;
      ctx.shadowBlur = dog.tier === "Neon" || dog.tier === "Mythic" ? 16 : 8;
      ctx.stroke();
      ctx.shadowBlur = 0;
    }
    ctx.font = "26px serif";
    ctx.textAlign = "center";
    ctx.fillText(breed.emoji, sx, sy + 8);
  });

  // Player
  const px = state.player.x - camX, py = state.player.y - camY;
  ctx.font = "30px serif";
  ctx.textAlign = "center";
  ctx.fillText("🚶", px, py + 8);

  // Nearby entity hint
  if (state.ui.nearbyEntity) {
    const e = state.ui.nearbyEntity;
    const sx = e.x - camX, sy = e.y - camY;
    ctx.fillStyle = "white";
    ctx.font = "12px system-ui";
    ctx.fillText("Tap 🐾", sx, sy - 24);
  }
}

// ===== Movement =====
const input = { joyX: 0, joyY: 0, keys: new Set() };

function updateMovement(dt) {
  let mx = input.joyX;
  let my = input.joyY;
  if (input.keys.has("w") || input.keys.has("ArrowUp"))    my -= 1;
  if (input.keys.has("s") || input.keys.has("ArrowDown"))  my += 1;
  if (input.keys.has("a") || input.keys.has("ArrowLeft"))  mx -= 1;
  if (input.keys.has("d") || input.keys.has("ArrowRight")) mx += 1;
  const mag = Math.hypot(mx, my);
  if (mag > 1) { mx /= mag; my /= mag; }

  const speed = state.player.speed;
  state.player.x = Math.max(20, Math.min(WORLD.w - 20, state.player.x + mx * speed * dt));
  state.player.y = Math.max(20, Math.min(WORLD.h - 20, state.player.y + my * speed * dt));

  // Camera centers on player
  state.cameraOffset.x = state.player.x - window.innerWidth / 2;
  state.cameraOffset.y = state.player.y - window.innerHeight / 2;

  // Followers track loosely
  let target = { x: state.player.x, y: state.player.y };
  for (const f of state.followers) {
    const dx = target.x - f.x, dy = target.y - f.y;
    const d = Math.hypot(dx, dy);
    if (d > 36) {
      f.x += (dx / d) * speed * 0.85 * dt;
      f.y += (dy / d) * speed * 0.85 * dt;
    }
    target = { x: f.x, y: f.y };
  }
}

// ===== Followers spawn =====
function rebuildFollowers() {
  state.followers = (state.profile.followers || []).slice(0, 3).map((dogId, i) => ({
    dogId,
    x: state.player.x - 24 - i * 18,
    y: state.player.y + 8,
  }));
}

// ===== Proximity =====
function nearestNpc() {
  let best = null, bestD = 60;
  for (const npc of state.world.npcs) {
    const d = Math.hypot(npc.x - state.player.x, npc.y - state.player.y);
    if (d < bestD) { best = npc; bestD = d; }
  }
  return best;
}
function nearestEntity() {
  let best = null, bestD = 40;
  for (const e of state.world.questEntities) {
    if (e.consumed) continue;
    const d = Math.hypot(e.x - state.player.x, e.y - state.player.y);
    if (d < bestD) { best = e; bestD = d; }
  }
  return best;
}

// ===== Quest flow =====
function startQuest(questId) {
  if (state.active.quest) {
    toast("Finish your current quest first.", "bad");
    return;
  }
  const q = QUESTS[questId];
  if (!q) return;
  state.active.quest = questId;
  state.active.objectives = {};
  for (const obj of q.objectives) {
    state.active.objectives[obj.id] = { done: false, count: 0, required: obj.count };
  }
  state.world.questEntities = [];
  q.waypoints.forEach((wp, i) => {
    const objId = wp.kind || q.objectives[0].id;
    const obj = q.objectives.find(o => o.id === objId);
    state.world.questEntities.push({
      id: uid(),
      x: wp.x, y: wp.y,
      kind: obj.kind,
      objectiveId: obj.id,
      ord: i + 1,
      consumed: false,
    });
  });
  toast(`Quest started: ${q.title}`, "good");
  refreshHUD();
}

function recordInteraction(entity) {
  const q = QUESTS[state.active.quest];
  if (!q) return;
  const obj = q.objectives.find(o => o.id === entity.objectiveId);
  if (!obj) return;
  const state_ = state.active.objectives[obj.id];

  if (obj.kind === "scentTrail" && entity.ord !== state_.count + 1) {
    toast("Wrong order — start from the nearest", "bad");
    return;
  }
  entity.consumed = true;
  state_.count += 1;
  if (state_.count >= state_.required) state_.done = true;

  for (const o of q.objectives) {
    if (!state.active.objectives[o.id].done) {
      refreshHUD();
      return;
    }
  }
  completeQuest();
}

function completeQuest() {
  const q = QUESTS[state.active.quest];
  if (!q) return;

  const dog = activeDog();
  let coinMul = 1;
  if (dog) {
    const breed = BREEDS[dog.breed];
    if (breed && breed.affinity === q.category) coinMul = 1.2;
  }
  const coins = Math.floor(q.coinReward * coinMul);
  state.profile.coins += coins;

  for (const id of state.profile.followers) {
    const d = state.profile.dogs[id];
    if (d) d.bond = Math.min(BOND_MAX, d.bond + q.bondReward);
  }

  if (q.breedReward) {
    addDog(q.breedReward, "Regular", 0);
    toast(`A new ${BREEDS[q.breedReward].name} joined your pack!`, "good");
  }

  state.profile.questsDone.push(state.active.quest);
  toast(`+${coins} 💰  +${q.bondReward} bond — quest complete!`, "good");

  state.active.quest = null;
  state.active.objectives = {};
  state.world.questEntities = [];
  save();
  refreshHUD();
}

function cancelQuest() {
  state.active.quest = null;
  state.active.objectives = {};
  state.world.questEntities = [];
  refreshHUD();
}

// ===== Tier roll =====
function highestThresholdReached(bond) {
  let n = 0;
  for (const t of BOND_THRESHOLDS) if (bond >= t) n++;
  return n;
}

function tierRollProb(dog) {
  const base = TIER_ROLL_BASE[dog.tier] ?? 0;
  const above = Math.max(0, dog.bond - BOND_THRESHOLDS[0]);
  const groomBonus = Math.min(0.20, 0.05 * (dog.groomingStreak || 0));
  return Math.min(TIER_ROLL_CAP, base + 0.001 * above + groomBonus);
}

function attemptTierRoll() {
  const dog = activeDog();
  if (!dog) return;
  if (!TIER_NEXT[dog.tier] || dog.tier === "Neon" || dog.tier === "Mythic") {
    toast("This dog needs to be combined with others to reach this tier.", "bad");
    return;
  }
  if (highestThresholdReached(dog.bond) === 0) {
    toast("Bond too low for a roll.", "bad");
    return;
  }
  const charges = state.profile.rollChargesByDog[dog.id] ?? 1;
  if (charges <= 0) {
    toast("No tier-roll charges. Come back tomorrow.", "bad");
    return;
  }
  state.profile.rollChargesByDog[dog.id] = charges - 1;

  const p = tierRollProb(dog);
  if (Math.random() < p) {
    const next = TIER_NEXT[dog.tier];
    dog.tier = next;
    toast(`✨ Tier up! ${BREEDS[dog.breed].name} → ${next} (${(p*100).toFixed(0)}%)`, "good");
  } else {
    toast(`Roll failed (${(p*100).toFixed(0)}%). Bond keeps growing.`, "bad");
  }
  save();
  refreshHUD();
}

// ===== HUD =====
function refreshHUD() {
  document.getElementById("coins").textContent = `💰 ${state.profile.coins}`;
  document.getElementById("treats").textContent = `🍪 ${state.profile.treats}`;

  const dog = activeDog();
  const nameEl = document.getElementById("active-name");
  const emojiEl = document.getElementById("active-emoji");
  const tierEl = document.getElementById("active-tier");
  const fillEl = document.getElementById("bond-fill");
  const rollBtn = document.getElementById("tier-roll-btn");
  if (dog) {
    const breed = BREEDS[dog.breed];
    nameEl.textContent = breed.name;
    emojiEl.textContent = breed.emoji;
    tierEl.textContent = TIER_VISUAL[dog.tier].label || "Common";
    tierEl.style.color = TIER_VISUAL[dog.tier].ring;
    fillEl.style.width = `${(dog.bond / BOND_MAX) * 100}%`;

    const canRoll = TIER_NEXT[dog.tier] && dog.tier !== "Neon" && dog.tier !== "Mythic" && highestThresholdReached(dog.bond) > 0;
    rollBtn.classList.toggle("hidden", !canRoll);
    if (canRoll) {
      const p = tierRollProb(dog);
      rollBtn.textContent = `Tier Roll ✨ (${(p*100).toFixed(0)}%)`;
    }
  } else {
    nameEl.textContent = "No dog";
    emojiEl.textContent = "🐶";
    tierEl.textContent = "";
    fillEl.style.width = "0%";
    rollBtn.classList.add("hidden");
  }

  refreshQuestPanel();
  refreshInventoryPanel();
  refreshHousePanel();
  refreshShelterPanel();
}

// ===== Action ring verbs =====
function applyAction(verb) {
  if (verb === "interact") {
    if (state.ui.nearbyEntity) { recordInteraction(state.ui.nearbyEntity); refreshHUD(); return; }
    if (state.ui.nearbyNpc) { openDialog(state.ui.nearbyNpc); return; }
    toast("Nothing nearby to interact with.", "bad");
    return;
  }
  const dog = activeDog();
  if (!dog) { toast("No active dog. Open inventory.", "bad"); return; }

  const gain = { groom: 12, feed: 6, play: 9, pet: 3 }[verb];
  if (!gain) return;

  const cd = { groom: 30, feed: 120, play: 15, pet: 3 }[verb];
  state._cooldowns ||= {};
  const key = dog.id + ":" + verb;
  const last = state._cooldowns[key] || 0;
  if (Date.now() - last < cd * 1000) {
    toast(`${verb} on cooldown`, "bad");
    return;
  }
  state._cooldowns[key] = Date.now();
  dog.bond = Math.min(BOND_MAX, dog.bond + gain);
  if (verb === "groom") {
    dog.groomingStreak = (dog.groomingStreak || 0) + 1;
    state.profile.rollChargesByDog[dog.id] = Math.min(3, (state.profile.rollChargesByDog[dog.id] ?? 1) + 0.25);
  }
  toast(`+${gain} bond (${verb})`, "good");
  save();
  refreshHUD();
}

// ===== NPC dialog =====
function openDialog(npc) {
  state.ui.dialogNpc = npc;
  document.getElementById("dialog-emoji").textContent = npc.emoji;
  document.getElementById("dialog-text").textContent = `"${npc.line}"`;
  const accept = document.getElementById("dialog-accept");
  accept.textContent = state.active.quest === npc.quest ? "In progress" : "Accept";
  accept.disabled = state.active.quest === npc.quest;
  document.getElementById("dialog").classList.remove("hidden");
}
function closeDialog() {
  state.ui.dialogNpc = null;
  document.getElementById("dialog").classList.add("hidden");
}
document.getElementById("dialog-accept").addEventListener("click", () => {
  if (state.ui.dialogNpc) startQuest(state.ui.dialogNpc.quest);
  closeDialog();
});
document.getElementById("dialog-cancel").addEventListener("click", closeDialog);

// ===== Toast =====
function toast(msg, kind = "") {
  const el = document.createElement("div");
  el.className = "toast " + kind;
  el.textContent = msg;
  document.getElementById("toast-container").appendChild(el);
  setTimeout(() => el.remove(), 3500);
}

// ===== Joystick =====
const joystick = document.getElementById("joystick");
const nub = document.getElementById("joystick-nub");
let joyActive = false, joyOrigin = null, joyPointer = null;
joystick.addEventListener("pointerdown", e => {
  joyActive = true;
  joyPointer = e.pointerId;
  const r = joystick.getBoundingClientRect();
  joyOrigin = { x: r.left + r.width / 2, y: r.top + r.height / 2 };
  joystick.setPointerCapture(e.pointerId);
});
joystick.addEventListener("pointermove", e => {
  if (!joyActive || e.pointerId !== joyPointer) return;
  const dx = e.clientX - joyOrigin.x;
  const dy = e.clientY - joyOrigin.y;
  const r = joystick.clientWidth / 2 - 30;
  const mag = Math.min(Math.hypot(dx, dy), r);
  const ang = Math.atan2(dy, dx);
  nub.style.transform = `translate(${Math.cos(ang) * mag}px, ${Math.sin(ang) * mag}px)`;
  input.joyX = (Math.cos(ang) * mag) / r;
  input.joyY = (Math.sin(ang) * mag) / r;
});
function joyEnd() {
  joyActive = false; joyPointer = null;
  nub.style.transform = "";
  input.joyX = 0; input.joyY = 0;
}
joystick.addEventListener("pointerup", joyEnd);
joystick.addEventListener("pointercancel", joyEnd);
joystick.addEventListener("pointerleave", e => { if (joyActive && e.pointerId === joyPointer) joyEnd(); });

// ===== Action ring =====
document.querySelectorAll(".action-btn").forEach(btn => {
  btn.addEventListener("click", () => applyAction(btn.dataset.verb));
});

// ===== Keyboard =====
window.addEventListener("keydown", e => {
  input.keys.add(e.key);
  if (e.key === "e" || e.key === "E") applyAction("interact");
  if (e.key === "f" || e.key === "F") applyAction("groom");
  if (e.key === "g" || e.key === "G") applyAction("feed");
  if (e.key === "h" || e.key === "H") applyAction("play");
  if (e.key === "j" || e.key === "J") applyAction("pet");
  if (e.key === "i" || e.key === "I") togglePanel("inventory");
});
window.addEventListener("keyup", e => input.keys.delete(e.key));

// ===== Tier roll button =====
document.getElementById("tier-roll-btn").addEventListener("click", attemptTierRoll);

// ===== Panels =====
function togglePanel(name) {
  for (const p of document.querySelectorAll(".modal")) p.classList.add("hidden");
  if (state.ui.panel === name) { state.ui.panel = null; return; }
  state.ui.panel = name;
  const el = document.getElementById("panel-" + name);
  if (el) el.classList.remove("hidden");
}
document.querySelectorAll(".menu-btn").forEach(btn => {
  btn.addEventListener("click", () => togglePanel(btn.dataset.panel));
});
document.querySelectorAll("[data-close]").forEach(btn => {
  btn.addEventListener("click", () => togglePanel(state.ui.panel));
});

function refreshInventoryPanel() {
  const grid = document.getElementById("inventory-grid");
  if (!grid) return;
  grid.innerHTML = "";
  const dogs = Object.values(state.profile.dogs);
  if (dogs.length === 0) { grid.innerHTML = `<div class="hint">No dogs yet.</div>`; return; }
  for (const dog of dogs) {
    const breed = BREEDS[dog.breed];
    const isFollower = (state.profile.followers || []).includes(dog.id);
    const card = document.createElement("div");
    card.className = "dog-card" + (isFollower ? " active-follower" : "");
    const visual = TIER_VISUAL[dog.tier];
    card.innerHTML = `
      <div class="emoji">${breed.emoji}</div>
      <div class="name">${breed.name}</div>
      <div class="meta">
        <span class="tier-badge ${dog.tier !== 'Regular' ? 'glow' : ''}" style="color:${visual.ring};background:rgba(255,255,255,0.06)">${visual.label || "Common"}</span>
        ❤ ${Math.floor(dog.bond)}/${BOND_MAX}
      </div>
      <div class="actions">
        <button data-toggle-follower>${isFollower ? "Send home" : "Follow me"}</button>
        <button data-display>${state.profile.house.displayed.includes(dog.id) ? "Hide" : "Display"}</button>
      </div>
    `;
    card.querySelector("[data-toggle-follower]").addEventListener("click", () => {
      const followers = state.profile.followers;
      if (isFollower) state.profile.followers = followers.filter(x => x !== dog.id);
      else if (followers.length < 3) followers.push(dog.id);
      else toast("Max 3 followers.", "bad");
      save(); rebuildFollowers(); refreshHUD();
    });
    card.querySelector("[data-display]").addEventListener("click", () => {
      const d = state.profile.house.displayed;
      const i = d.indexOf(dog.id);
      if (i >= 0) d.splice(i, 1); else d.push(dog.id);
      save(); refreshHUD();
    });
    grid.appendChild(card);
  }
}

function refreshQuestPanel() {
  const card = document.getElementById("active-quest-card");
  if (!card) return;
  if (!state.active.quest) { card.classList.add("hidden"); return; }
  const q = QUESTS[state.active.quest];
  card.classList.remove("hidden");
  let objsHtml = "";
  for (const obj of q.objectives) {
    const s = state.active.objectives[obj.id];
    const cls = s.done ? "objective-row done" : "objective-row";
    objsHtml += `<div class="${cls}">${obj.hint} (${s.count}/${s.required})</div>`;
  }
  card.innerHTML = `
    <h3>${q.title}</h3>
    <p>${q.summary}</p>
    ${objsHtml}
    <div class="actions">
      <button class="btn-secondary" id="cancel-quest-btn">Cancel</button>
    </div>
  `;
  document.getElementById("cancel-quest-btn").addEventListener("click", cancelQuest);
}

function refreshHousePanel() {
  const yard = document.getElementById("house-yard");
  if (!yard) return;
  yard.innerHTML = "";
  const ids = state.profile.house.displayed;
  if (ids.length === 0) {
    yard.innerHTML = `<div class="hint" style="grid-column: 1 / -1;">No dogs displayed yet. Open inventory and tap "Display" on a dog.</div>`;
    return;
  }
  for (const id of ids) {
    const dog = state.profile.dogs[id];
    if (!dog) continue;
    const breed = BREEDS[dog.breed];
    const visual = TIER_VISUAL[dog.tier];
    const tile = document.createElement("div");
    tile.className = "display-tile";
    tile.style.borderColor = visual.ring === "transparent" ? "rgba(255,255,255,0.2)" : visual.ring;
    tile.innerHTML = `${breed.emoji}<small>${breed.name.split(" ")[0]}</small>`;
    yard.appendChild(tile);
  }
}

function refreshShelterPanel() {
  const status = document.getElementById("shelter-status");
  const buyBtn = document.getElementById("buy-vet-btn");
  const list = document.getElementById("shelter-list");
  if (!status) return;

  if (!state.profile.shelter.owned) {
    status.textContent = "Buy the Vet to open your shelter and start taking in strays.";
    buyBtn.classList.remove("hidden");
    list.innerHTML = "";
    return;
  }
  buyBtn.classList.add("hidden");
  status.textContent = `Strays: ${state.profile.shelter.strays.length} • intakes: ${state.profile.shelter.intakeTotals} • adoptions: ${state.profile.shelter.adoptOutTotals}`;
  list.innerHTML = "";
  state.profile.shelter.strays.forEach((stray, i) => {
    const breed = BREEDS[stray.breed];
    const card = document.createElement("div");
    card.className = "dog-card";
    card.innerHTML = `
      <div class="emoji">${breed.emoji}</div>
      <div class="name">${breed.name}</div>
      <div class="meta">${stray.tier} • ❤${stray.bond}</div>
      <div class="actions">
        <button data-intake>Intake</button>
      </div>
    `;
    card.querySelector("[data-intake]").addEventListener("click", () => {
      state.profile.shelter.strays.splice(i, 1);
      const dog = addDog(stray.breed, stray.tier, stray.bond);
      state.profile.shelter.intakeTotals += 1;
      toast(`Took in ${BREEDS[stray.breed].name}`, "good");
      save(); refreshHUD();
    });
    list.appendChild(card);
  });
}

document.getElementById("buy-vet-btn").addEventListener("click", () => {
  if (state.profile.coins < VET_PRICE) { toast("Not enough coins.", "bad"); return; }
  state.profile.coins -= VET_PRICE;
  state.profile.shelter.owned = true;
  state.profile.shelter.strays = SHELTER_SEED_STRAYS.map(s => ({ ...s }));
  toast("Vet purchased! Strays available for intake.", "good");
  save(); refreshHUD();
});

document.getElementById("reset-progress").addEventListener("click", () => {
  if (!confirm("Erase all progress?")) return;
  localStorage.removeItem(SAVE_KEY);
  location.reload();
});

// ===== Loop =====
let last = performance.now();
let bondAccumulator = 0;
function loop(now) {
  const dt = Math.min(0.05, (now - last) / 1000);
  last = now;

  updateMovement(dt);

  state.ui.nearbyNpc = nearestNpc();
  state.ui.nearbyEntity = nearestEntity();

  bondAccumulator += dt;
  if (bondAccumulator >= 5) {
    bondAccumulator = 0;
    let bumped = false;
    for (const id of state.profile.followers) {
      const d = state.profile.dogs[id];
      if (d && d.bond < BOND_MAX) {
        d.bond = Math.min(BOND_MAX, d.bond + 1);
        bumped = true;
      }
    }
    if (bumped) { save(); refreshHUD(); }
  }

  drawWorld();
  requestAnimationFrame(loop);
}

// ===== Boot =====
function boot() {
  state.profile = load() || emptyProfile();
  ensureSeed();
  rebuildFollowers();
  refreshHUD();
  if (!state.profile.seenIntro) {
    togglePanel("help");
    state.profile.seenIntro = true;
    save();
  }
  requestAnimationFrame(now => { last = now; loop(now); });
}
boot();
