import * as THREE from "https://esm.sh/three@0.171.0";

import {
  TIERS, TIER_NEXT, TIER_VISUAL, BOND_MAX, BOND_THRESHOLDS, TIER_ROLL_BASE, TIER_ROLL_CAP,
  BREEDS, QUESTS, NPCS, SHELTER_SEED_STRAYS, rollBreedByRarity,
} from "./data.js";

// ===== State =====
const SAVE_KEY = "pawprint_web_v2_3d";
const VET_PRICE = 50_000;

const state = {
  player: { x: 300, y: 0, z: 300, speed: 200 },
  profile: null,
  world: {
    npcs: NPCS.map(n => ({ ...n })),
    questEntities: [],
  },
  active: { quest: null, objectives: {} },
  ui: { dialogNpc: null, nearbyNpc: null, nearbyEntity: null, panel: null },
  followers: [],
  meshes: { npcs: new Map(), entities: new Map(), followers: new Map(), regions: [] },
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

// ===== Three.js setup =====
const canvas = document.getElementById("world");
const renderer = new THREE.WebGLRenderer({ canvas, antialias: false });
renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
renderer.outputColorSpace = THREE.SRGBColorSpace;

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x9bd2ff);
scene.fog = new THREE.Fog(0x9bd2ff, 600, 1600);

const camera = new THREE.PerspectiveCamera(55, 1, 1, 4000);
const camOffset = new THREE.Vector3(0, 110, 140);
const camLookOffset = new THREE.Vector3(0, 18, 0);

const sun = new THREE.DirectionalLight(0xfff8e8, 1.1);
sun.position.set(400, 800, 200);
scene.add(sun);
scene.add(new THREE.AmbientLight(0xffffff, 0.55));

const ground = new THREE.Mesh(
  new THREE.PlaneGeometry(3000, 3000),
  new THREE.MeshLambertMaterial({ color: 0x6cab5a })
);
ground.rotation.x = -Math.PI / 2;
ground.position.y = 0;
scene.add(ground);

// World coordinate convention: world X = data.x, world Z = data.y, Y = up.
const WORLD_SIZE = { w: 1200, h: 900 };

const REGIONS = [
  { name: "house",   color: 0xf0c879, x: 150, z: 150, w: 200, h: 160, label: "🏡 Home" },
  { name: "park",    color: 0x9ed18a, x: 380, z: 180, w: 280, h: 220, label: "🌳 Park" },
  { name: "bakery",  color: 0xd8a070, x: 760, z: 160, w: 260, h: 280, label: "🥐 Bakery" },
  { name: "meadow",  color: 0xa8d894, x: 130, z: 420, w: 240, h: 220, label: "🌾 Meadow" },
  { name: "river",   color: 0x4a8fc8, x: 420, z: 620, w: 360, h: 60,  label: "" },
  { name: "bridge",  color: 0xa8a890, x: 510, z: 600, w: 80,  h: 100, label: "🌉 Bridge" },
  { name: "shelter", color: 0xd0e6f4, x: 820, z: 480, w: 180, h: 140, label: "🏥 Vet" },
];

function buildRegions() {
  for (const r of REGIONS) {
    const isWater = r.name === "river";
    const tile = new THREE.Mesh(
      new THREE.PlaneGeometry(r.w, r.h),
      new THREE.MeshLambertMaterial({ color: r.color })
    );
    tile.rotation.x = -Math.PI / 2;
    tile.position.set(r.x + r.w / 2 - WORLD_SIZE.w / 2, isWater ? -0.4 : 0.4, r.z + r.h / 2 - WORLD_SIZE.h / 2);
    scene.add(tile);
    state.meshes.regions.push(tile);

    if (r.label) {
      const label = makeTextSprite(r.label, 96, "rgba(0,0,0,0.85)", "rgba(255,255,255,0.85)");
      label.position.set(r.x + r.w / 2 - WORLD_SIZE.w / 2, 30, r.z + r.h / 2 - WORLD_SIZE.h / 2);
      label.scale.set(80, 28, 1);
      scene.add(label);
    }
  }

  // Boundary fence: simple low boxes at edges so the world doesn't feel infinite.
  const fenceMat = new THREE.MeshLambertMaterial({ color: 0xcebb96 });
  const halfW = WORLD_SIZE.w / 2, halfH = WORLD_SIZE.h / 2;
  const sides = [
    { p: [0, 6, -halfH], s: [WORLD_SIZE.w, 12, 4] },
    { p: [0, 6,  halfH], s: [WORLD_SIZE.w, 12, 4] },
    { p: [-halfW, 6, 0], s: [4, 12, WORLD_SIZE.h] },
    { p: [ halfW, 6, 0], s: [4, 12, WORLD_SIZE.h] },
  ];
  for (const f of sides) {
    const mesh = new THREE.Mesh(new THREE.BoxGeometry(...f.s), fenceMat);
    mesh.position.set(...f.p);
    scene.add(mesh);
  }
}

// ===== Sprite/text helpers =====
const spriteCache = new Map();
function makeEmojiSprite(emoji, pixelSize = 128) {
  const key = `e:${emoji}:${pixelSize}`;
  if (spriteCache.has(key)) {
    const m = new THREE.Sprite(spriteCache.get(key).clone());
    return m;
  }
  const c = document.createElement("canvas");
  c.width = c.height = pixelSize;
  const cx = c.getContext("2d");
  cx.font = `${pixelSize * 0.78}px serif, 'Apple Color Emoji', 'Segoe UI Emoji'`;
  cx.textAlign = "center";
  cx.textBaseline = "middle";
  cx.fillText(emoji, pixelSize / 2, pixelSize / 2 + 4);
  const tex = new THREE.CanvasTexture(c);
  tex.minFilter = THREE.LinearFilter;
  tex.colorSpace = THREE.SRGBColorSpace;
  const mat = new THREE.SpriteMaterial({ map: tex, transparent: true, sizeAttenuation: true });
  spriteCache.set(key, mat);
  return new THREE.Sprite(mat);
}

function makeTextSprite(text, pixelSize = 128, fg = "white", bg = null) {
  const c = document.createElement("canvas");
  c.width = pixelSize * 4;
  c.height = pixelSize;
  const cx = c.getContext("2d");
  if (bg) {
    cx.fillStyle = bg;
    cx.fillRect(0, 0, c.width, c.height);
  }
  cx.font = `bold ${pixelSize * 0.55}px system-ui, sans-serif`;
  cx.fillStyle = fg;
  cx.textAlign = "center";
  cx.textBaseline = "middle";
  cx.fillText(text, c.width / 2, c.height / 2);
  const tex = new THREE.CanvasTexture(c);
  tex.minFilter = THREE.LinearFilter;
  tex.colorSpace = THREE.SRGBColorSpace;
  const mat = new THREE.SpriteMaterial({ map: tex, transparent: true });
  return new THREE.Sprite(mat);
}

function makeShadow() {
  const mat = new THREE.MeshBasicMaterial({ color: 0x000000, transparent: true, opacity: 0.25 });
  const mesh = new THREE.Mesh(new THREE.CircleGeometry(14, 16), mat);
  mesh.rotation.x = -Math.PI / 2;
  mesh.position.y = 0.5;
  return mesh;
}

function worldX(dataX) { return dataX - WORLD_SIZE.w / 2; }
function worldZ(dataY) { return dataY - WORLD_SIZE.h / 2; }

// ===== Player =====
const playerGroup = new THREE.Group();
const playerSprite = makeEmojiSprite("🚶", 128);
playerSprite.scale.set(36, 36, 1);
playerSprite.position.y = 22;
playerGroup.add(playerSprite);
const playerShadow = makeShadow();
playerShadow.scale.set(0.9, 0.9, 0.9);
playerGroup.add(playerShadow);
scene.add(playerGroup);

// ===== NPCs =====
function buildNpcs() {
  for (const npc of state.world.npcs) {
    const grp = new THREE.Group();
    const post = new THREE.Mesh(
      new THREE.CylinderGeometry(6, 6, 16, 12),
      new THREE.MeshLambertMaterial({ color: 0xc8a878 })
    );
    post.position.y = 8;
    grp.add(post);
    const sprite = makeEmojiSprite(npc.emoji, 128);
    sprite.scale.set(34, 34, 1);
    sprite.position.y = 28;
    grp.add(sprite);
    const shadow = makeShadow();
    grp.add(shadow);

    const ring = new THREE.Mesh(
      new THREE.RingGeometry(20, 24, 24),
      new THREE.MeshBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0.0, side: THREE.DoubleSide })
    );
    ring.rotation.x = -Math.PI / 2;
    ring.position.y = 0.6;
    grp.add(ring);
    grp.userData.ring = ring;

    grp.position.set(worldX(npc.x), 0, worldZ(npc.y));
    scene.add(grp);
    state.meshes.npcs.set(npc.id, grp);
  }
}

// ===== Quest entity meshes =====
function buildEntityMesh(e) {
  const grp = new THREE.Group();
  const color = e.kind === "scentTrail" ? 0xffb066 : e.kind === "digSpot" ? 0xb88a4a : 0xffd866;
  const pillar = new THREE.Mesh(
    new THREE.CylinderGeometry(6, 6, 28, 12),
    new THREE.MeshBasicMaterial({ color, transparent: true, opacity: 0.65 })
  );
  pillar.position.y = 14;
  grp.add(pillar);
  const halo = new THREE.Mesh(
    new THREE.RingGeometry(8, 14, 24),
    new THREE.MeshBasicMaterial({ color, transparent: true, opacity: 0.6, side: THREE.DoubleSide })
  );
  halo.rotation.x = -Math.PI / 2;
  halo.position.y = 0.7;
  grp.add(halo);
  grp.userData.halo = halo;
  grp.userData.pillar = pillar;
  grp.userData.color = color;

  if (e.kind === "scentTrail") {
    const num = makeTextSprite(String(e.ord), 64, "white", "rgba(0,0,0,0.6)");
    num.scale.set(18, 9, 1);
    num.position.y = 36;
    grp.add(num);
  } else if (e.kind === "digSpot") {
    const bone = makeEmojiSprite("🦴", 96);
    bone.scale.set(20, 20, 1);
    bone.position.y = 36;
    grp.add(bone);
  } else {
    const box = makeEmojiSprite("📦", 96);
    box.scale.set(20, 20, 1);
    box.position.y = 36;
    grp.add(box);
  }

  grp.position.set(worldX(e.x), 0, worldZ(e.y));
  return grp;
}

// ===== Followers =====
function rebuildFollowers() {
  for (const [id, mesh] of state.meshes.followers) scene.remove(mesh);
  state.meshes.followers.clear();

  state.followers = [];
  (state.profile.followers || []).slice(0, 3).forEach((dogId, i) => {
    const dog = state.profile.dogs[dogId];
    if (!dog) return;
    const breed = BREEDS[dog.breed];
    const grp = new THREE.Group();
    const sprite = makeEmojiSprite(breed.emoji, 128);
    sprite.scale.set(28, 28, 1);
    sprite.position.y = 14;
    grp.add(sprite);
    const shadow = makeShadow();
    shadow.scale.set(0.7, 0.7, 0.7);
    grp.add(shadow);

    const visual = TIER_VISUAL[dog.tier];
    if (visual.ring !== "transparent") {
      const ringColor = new THREE.Color(visual.ring);
      const ring = new THREE.Mesh(
        new THREE.RingGeometry(12, 16, 24),
        new THREE.MeshBasicMaterial({ color: ringColor, transparent: true, opacity: 0.85, side: THREE.DoubleSide })
      );
      ring.rotation.x = -Math.PI / 2;
      ring.position.y = 0.6;
      grp.add(ring);
      grp.userData.ring = ring;
    }

    grp.position.set(state.player.x - 24 - i * 18, 0, state.player.z + 16);
    scene.add(grp);

    state.followers.push({ dogId, group: grp, vx: 0, vz: 0 });
    state.meshes.followers.set(dogId, grp);
  });
}

// ===== Movement =====
const input = { joyX: 0, joyY: 0, keys: new Set() };

function updateMovement(dt) {
  let mx = input.joyX;
  let mz = input.joyY;
  if (input.keys.has("w") || input.keys.has("ArrowUp"))    mz -= 1;
  if (input.keys.has("s") || input.keys.has("ArrowDown"))  mz += 1;
  if (input.keys.has("a") || input.keys.has("ArrowLeft"))  mx -= 1;
  if (input.keys.has("d") || input.keys.has("ArrowRight")) mx += 1;
  const mag = Math.hypot(mx, mz);
  if (mag > 1) { mx /= mag; mz /= mag; }

  const halfW = WORLD_SIZE.w / 2 - 20;
  const halfH = WORLD_SIZE.h / 2 - 20;
  state.player.x = Math.max(-halfW, Math.min(halfW, state.player.x + mx * state.player.speed * dt));
  state.player.z = Math.max(-halfH, Math.min(halfH, state.player.z + mz * state.player.speed * dt));

  playerGroup.position.set(state.player.x, 0, state.player.z);

  // Camera follow
  const target = new THREE.Vector3(state.player.x, 0, state.player.z);
  camera.position.set(target.x + camOffset.x, target.y + camOffset.y, target.z + camOffset.z);
  camera.lookAt(target.x + camLookOffset.x, target.y + camLookOffset.y, target.z + camLookOffset.z);

  // Followers trail loosely
  let leadX = state.player.x, leadZ = state.player.z + 20;
  for (const f of state.followers) {
    const cx = f.group.position.x, cz = f.group.position.z;
    const dx = leadX - cx, dz = leadZ - cz;
    const d = Math.hypot(dx, dz);
    if (d > 26) {
      const move = state.player.speed * 0.9 * dt;
      f.group.position.x += (dx / d) * Math.min(move, d - 25);
      f.group.position.z += (dz / d) * Math.min(move, d - 25);
    }
    leadX = f.group.position.x;
    leadZ = f.group.position.z + 16;
  }
}

// ===== Proximity (XZ) =====
function nearestNpc() {
  let best = null, bestD = 60;
  for (const npc of state.world.npcs) {
    const d = Math.hypot(worldX(npc.x) - state.player.x, worldZ(npc.y) - state.player.z);
    if (d < bestD) { best = npc; bestD = d; }
  }
  return best;
}
function nearestEntity() {
  let best = null, bestD = 38;
  for (const e of state.world.questEntities) {
    if (e.consumed) continue;
    const d = Math.hypot(worldX(e.x) - state.player.x, worldZ(e.y) - state.player.z);
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
  // Tear down old entity meshes
  for (const [id, m] of state.meshes.entities) scene.remove(m);
  state.meshes.entities.clear();
  state.world.questEntities = [];

  q.waypoints.forEach((wp, i) => {
    const objId = wp.kind || q.objectives[0].id;
    const obj = q.objectives.find(o => o.id === objId);
    const e = {
      id: uid(),
      x: wp.x, y: wp.y,
      kind: obj.kind,
      objectiveId: obj.id,
      ord: i + 1,
      consumed: false,
    };
    state.world.questEntities.push(e);
    const mesh = buildEntityMesh(e);
    scene.add(mesh);
    state.meshes.entities.set(e.id, mesh);
  });
  toast(`Quest started: ${q.title}`, "good");
  refreshHUD();
}

function recordInteraction(entity) {
  const q = QUESTS[state.active.quest];
  if (!q) return;
  const obj = q.objectives.find(o => o.id === entity.objectiveId);
  if (!obj) return;
  const objSt = state.active.objectives[obj.id];

  if (obj.kind === "scentTrail" && entity.ord !== objSt.count + 1) {
    toast("Wrong order — start from the nearest", "bad");
    return;
  }
  entity.consumed = true;
  const mesh = state.meshes.entities.get(entity.id);
  if (mesh) { scene.remove(mesh); state.meshes.entities.delete(entity.id); }

  objSt.count += 1;
  if (objSt.count >= objSt.required) objSt.done = true;

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
  for (const [id, m] of state.meshes.entities) scene.remove(m);
  state.meshes.entities.clear();
  save();
  refreshHUD();
}

function cancelQuest() {
  state.active.quest = null;
  state.active.objectives = {};
  state.world.questEntities = [];
  for (const [id, m] of state.meshes.entities) scene.remove(m);
  state.meshes.entities.clear();
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
    rebuildFollowers();
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

// ===== Resize =====
function resize() {
  const w = window.innerWidth, h = window.innerHeight;
  renderer.setSize(w, h, false);
  camera.aspect = w / h;
  camera.updateProjectionMatrix();
}
window.addEventListener("resize", resize);
resize();

// ===== Loop =====
let last = performance.now();
let bondAccumulator = 0;
function loop(now) {
  const dt = Math.min(0.05, (now - last) / 1000);
  last = now;

  updateMovement(dt);

  const npc = nearestNpc();
  state.ui.nearbyNpc = npc;
  for (const [id, mesh] of state.meshes.npcs) {
    const ring = mesh.userData.ring;
    if (ring) ring.material.opacity = (npc && id === npc.id) ? 0.7 : 0.0;
  }

  state.ui.nearbyEntity = nearestEntity();

  // Pulse markers
  const pulse = 1 + 0.18 * Math.sin(now / 250);
  for (const [id, mesh] of state.meshes.entities) {
    if (mesh.userData.halo) {
      mesh.userData.halo.scale.set(pulse, pulse, 1);
      mesh.userData.halo.material.opacity = 0.45 + 0.25 * Math.sin(now / 280);
    }
    if (mesh.userData.pillar) {
      mesh.userData.pillar.position.y = 14 + 1.2 * Math.sin(now / 220);
    }
  }

  // Pulse follower tier rings (Neon / Mythic shimmer)
  for (const [id, mesh] of state.meshes.followers) {
    const dog = state.profile.dogs[id];
    if (dog && (dog.tier === "Neon" || dog.tier === "Mythic") && mesh.userData.ring) {
      mesh.userData.ring.material.opacity = 0.6 + 0.35 * Math.sin(now / 180);
    }
  }

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

  renderer.render(scene, camera);
  requestAnimationFrame(loop);
}

// ===== Boot =====
async function boot() {
  state.profile = load() || emptyProfile();
  ensureSeed();

  // Initial player position in world coords
  state.player.x = worldX(state.player.x);
  state.player.z = worldZ(state.player.z);
  playerGroup.position.set(state.player.x, 0, state.player.z);

  buildRegions();
  buildNpcs();
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
