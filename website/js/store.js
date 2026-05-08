/**
 * Persistence + business logic.
 *
 * Everything lives in localStorage so the site is fully functional with no
 * backend. The owner can plug in a real API later by replacing the read/write
 * helpers — the rest of the app calls Store.* and doesn't care where data
 * lives.
 *
 * Keys:
 *   lcr.cart       — current customer cart
 *   lcr.orders     — array of placed orders (queue + history)
 *   lcr.ingCosts   — per-ingredient cost overrides (owner edits)
 *   lcr.ingStock   — per-ingredient stock overrides (decremented on order)
 *   lcr.prices     — per-menu-item price overrides
 *   lcr.loyalty    — { phone: { stars, name } } simple rewards ledger
 */

window.Store = (function () {
  const KEYS = {
    cart: "lcr.cart",
    orders: "lcr.orders",
    ingCosts: "lcr.ingCosts",
    ingStock: "lcr.ingStock",
    prices: "lcr.prices",
    loyalty: "lcr.loyalty",
  };

  // ---------- localStorage helpers ----------
  function read(key, fallback) {
    try {
      const raw = localStorage.getItem(key);
      return raw == null ? fallback : JSON.parse(raw);
    } catch (e) {
      return fallback;
    }
  }
  function write(key, value) {
    localStorage.setItem(key, JSON.stringify(value));
  }

  // ---------- Live ingredient + price views (with overrides applied) ----------
  function getIngredients() {
    const overrides = read(KEYS.ingCosts, {});
    const stock = read(KEYS.ingStock, {});
    return LCR_DATA.ingredients.map((ing) => ({
      ...ing,
      cost: overrides[ing.id] != null ? overrides[ing.id] : ing.cost,
      stock: stock[ing.id] != null ? stock[ing.id] : ing.stock,
    }));
  }
  function getIngredient(id) {
    return getIngredients().find((i) => i.id === id);
  }
  function setIngredientCost(id, cost) {
    const overrides = read(KEYS.ingCosts, {});
    overrides[id] = Number(cost);
    write(KEYS.ingCosts, overrides);
  }
  function setIngredientStock(id, stock) {
    const overrides = read(KEYS.ingStock, {});
    overrides[id] = Number(stock);
    write(KEYS.ingStock, overrides);
  }

  function getMenu() {
    const priceOverrides = read(KEYS.prices, {});
    const ings = Object.fromEntries(getIngredients().map((i) => [i.id, i]));
    return LCR_DATA.menu.map((item) => {
      const baseCost = item.recipe.reduce(
        (sum, r) => sum + (ings[r.id] ? ings[r.id].cost * r.qty : 0),
        0
      );
      const price = priceOverrides[item.id] != null ? priceOverrides[item.id] : item.price;
      return { ...item, baseCost, price };
    });
  }
  function getMenuItem(id) {
    return getMenu().find((m) => m.id === id);
  }
  function setMenuPrice(id, price) {
    const overrides = read(KEYS.prices, {});
    overrides[id] = Number(price);
    write(KEYS.prices, overrides);
  }

  // ---------- Cart ----------
  function getCart() {
    return read(KEYS.cart, []);
  }
  function setCart(cart) {
    write(KEYS.cart, cart);
    document.dispatchEvent(new CustomEvent("cart:changed", { detail: cart }));
  }
  function addToCart(line) {
    // line = { menuItemId, qty, modifiers: { size, milk, addons: [] } }
    const cart = getCart();
    line.lineId = "ln_" + Math.random().toString(36).slice(2, 9);
    cart.push(line);
    setCart(cart);
  }
  function removeFromCart(lineId) {
    setCart(getCart().filter((l) => l.lineId !== lineId));
  }
  function updateCartQty(lineId, qty) {
    const cart = getCart();
    const line = cart.find((l) => l.lineId === lineId);
    if (!line) return;
    line.qty = Math.max(1, qty);
    setCart(cart);
  }
  function clearCart() {
    setCart([]);
  }

  // Compute price + cost for a single cart line (one drink × qty)
  function priceLine(line) {
    const item = getMenuItem(line.menuItemId);
    if (!item) return { price: 0, cost: 0, label: "(removed)" };
    const mods = line.modifiers || {};
    let priceEach = item.price;
    let costEach = item.baseCost;

    const sizeMod = (LCR_DATA.modifiers.size || []).find((m) => m.id === mods.size);
    if (sizeMod) {
      priceEach += sizeMod.priceDelta;
      costEach += sizeMod.costDelta;
    }
    const milkMod = (LCR_DATA.modifiers.milk || []).find((m) => m.id === mods.milk);
    if (milkMod && milkMod.id !== "whole") {
      priceEach += milkMod.priceDelta;
      costEach += milkMod.costDelta;
    }
    (mods.addons || []).forEach((aid) => {
      const a = (LCR_DATA.modifiers.addons || []).find((m) => m.id === aid);
      if (a) {
        priceEach += a.priceDelta;
        costEach += a.costDelta;
      }
    });

    const qty = line.qty || 1;
    return {
      label: item.name,
      priceEach: round(priceEach),
      costEach: round(costEach),
      price: round(priceEach * qty),
      cost: round(costEach * qty),
    };
  }

  function cartTotals() {
    const cart = getCart();
    let subtotal = 0;
    let cost = 0;
    cart.forEach((l) => {
      const p = priceLine(l);
      subtotal += p.price;
      cost += p.cost;
    });
    const tax = round(subtotal * 0.0775); // OH state + Lorain county estimate
    const total = round(subtotal + tax);
    return {
      subtotal: round(subtotal),
      tax,
      total,
      cost: round(cost),
      profit: round(subtotal - cost),
    };
  }

  // ---------- Orders ----------
  function getOrders() {
    return read(KEYS.orders, []);
  }
  function placeOrder(customer) {
    const cart = getCart();
    if (!cart.length) throw new Error("Cart is empty");
    const totals = cartTotals();
    const lines = cart.map((l) => {
      const p = priceLine(l);
      return {
        menuItemId: l.menuItemId,
        label: p.label,
        qty: l.qty,
        modifiers: l.modifiers || {},
        priceEach: p.priceEach,
        costEach: p.costEach,
        price: p.price,
        cost: p.cost,
      };
    });
    const order = {
      id: "ord_" + Date.now().toString(36) + Math.random().toString(36).slice(2, 6),
      placedAt: new Date().toISOString(),
      pickupTime: customer.pickupTime || null,
      customer: {
        name: customer.name || "",
        phone: customer.phone || "",
        notes: customer.notes || "",
      },
      lines,
      subtotal: totals.subtotal,
      tax: totals.tax,
      total: totals.total,
      cost: totals.cost,
      profit: totals.profit,
      status: "queued",
    };

    // Decrement inventory based on recipes
    const stock = read(KEYS.ingStock, {});
    const ings = Object.fromEntries(getIngredients().map((i) => [i.id, i]));
    cart.forEach((l) => {
      const item = getMenuItem(l.menuItemId);
      if (!item) return;
      item.recipe.forEach((r) => {
        const current = stock[r.id] != null ? stock[r.id] : (ings[r.id] ? ings[r.id].stock : 0);
        stock[r.id] = round(current - r.qty * (l.qty || 1));
      });
      // Modifier-driven extra usage (extra shot / boba / syrup)
      ((l.modifiers && l.modifiers.addons) || []).forEach((aid) => {
        const map = { extra_shot: "espresso_shot", boba: "boba_pearls", syrup: "vanilla_syrup" };
        const ingId = map[aid];
        if (!ingId) return;
        const current = stock[ingId] != null ? stock[ingId] : (ings[ingId] ? ings[ingId].stock : 0);
        stock[ingId] = round(current - 1 * (l.qty || 1));
      });
    });
    write(KEYS.ingStock, stock);

    // Award loyalty stars if a phone was provided (1 star per drink)
    if (order.customer.phone) {
      const loyalty = read(KEYS.loyalty, {});
      const key = order.customer.phone.replace(/\D/g, "");
      const cup = loyalty[key] || { stars: 0, name: order.customer.name || "" };
      const drinkQty = lines
        .filter((l) => ["espresso", "brewed", "boba"].includes((getMenuItem(l.menuItemId) || {}).category))
        .reduce((s, l) => s + l.qty, 0);
      cup.stars += drinkQty;
      cup.name = cup.name || order.customer.name;
      cup.lastVisit = order.placedAt;
      loyalty[key] = cup;
      write(KEYS.loyalty, loyalty);
      order.starsEarned = drinkQty;
      order.starsBalance = cup.stars;
    }

    const orders = getOrders();
    orders.unshift(order);
    write(KEYS.orders, orders);
    clearCart();
    return order;
  }
  function updateOrderStatus(id, status) {
    const orders = getOrders();
    const o = orders.find((x) => x.id === id);
    if (!o) return;
    o.status = status;
    write(KEYS.orders, orders);
  }
  function deleteOrder(id) {
    const orders = getOrders().filter((o) => o.id !== id);
    write(KEYS.orders, orders);
  }

  // ---------- Loyalty ----------
  function getLoyalty(phone) {
    const loyalty = read(KEYS.loyalty, {});
    const key = (phone || "").replace(/\D/g, "");
    return loyalty[key] || { stars: 0 };
  }

  // ---------- Reset / seed demo ----------
  function seedDemoOrders(count) {
    const orders = getOrders();
    const menu = getMenu();
    const drinkable = menu.filter((m) => m.category !== "retail");
    const now = Date.now();
    for (let i = 0; i < count; i++) {
      const item = drinkable[Math.floor(Math.random() * drinkable.length)];
      const qty = Math.random() < 0.7 ? 1 : 2;
      const placedAt = new Date(now - Math.floor(Math.random() * 7 * 24 * 60 * 60 * 1000)).toISOString();
      const priceEach = item.price;
      const costEach = item.baseCost;
      const subtotal = round(priceEach * qty);
      const tax = round(subtotal * 0.0775);
      orders.push({
        id: "demo_" + i.toString(36) + Math.random().toString(36).slice(2, 5),
        placedAt,
        pickupTime: null,
        customer: { name: "Walk-in", phone: "", notes: "" },
        lines: [{ menuItemId: item.id, label: item.name, qty, modifiers: {}, priceEach, costEach, price: subtotal, cost: round(costEach * qty) }],
        subtotal, tax, total: round(subtotal + tax),
        cost: round(costEach * qty), profit: round(subtotal - costEach * qty),
        status: "completed",
      });
    }
    write(KEYS.orders, orders);
  }
  function resetAll() {
    Object.values(KEYS).forEach((k) => localStorage.removeItem(k));
    document.dispatchEvent(new CustomEvent("cart:changed", { detail: [] }));
  }

  function round(n) {
    return Math.round(n * 100) / 100;
  }
  function fmtUSD(n) {
    return "$" + (Math.round(n * 100) / 100).toFixed(2);
  }

  return {
    KEYS,
    getIngredients, getIngredient, setIngredientCost, setIngredientStock,
    getMenu, getMenuItem, setMenuPrice,
    getCart, addToCart, removeFromCart, updateCartQty, clearCart,
    priceLine, cartTotals,
    getOrders, placeOrder, updateOrderStatus, deleteOrder,
    getLoyalty,
    seedDemoOrders, resetAll,
    round, fmtUSD,
  };
})();
