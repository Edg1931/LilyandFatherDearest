/**
 * Owner dashboard.
 *
 * Reads orders + ingredients + menu from Store and renders:
 *   • KPI cards (revenue, profit, orders, avg margin)
 *   • Live order queue with status controls
 *   • Item-by-item profitability table
 *   • Top items chart (horizontal bars)
 *   • Inventory levels (editable cost, editable stock, low-stock highlight)
 *   • Loyalty ledger
 *   • CSV export of orders, products P&L, and inventory
 *
 * Date filter applies to the KPIs and the orders/products tables. Inventory and
 * loyalty are global. All data lives in localStorage.
 */

(function () {
  let activeRange = "today"; // today, week, month, all

  function init() {
    bindNav();
    bindActions();
    renderAll();
    document.addEventListener("cart:changed", () => {}); // noop
  }

  function bindNav() {
    document.querySelectorAll(".admin-nav a[data-tab]").forEach((a) => {
      a.addEventListener("click", (e) => {
        e.preventDefault();
        const tab = a.getAttribute("data-tab");
        document.querySelectorAll(".admin-nav a[data-tab]").forEach((x) => x.classList.toggle("active", x === a));
        document.querySelectorAll("[data-panel]").forEach((p) => {
          p.style.display = p.getAttribute("data-panel") === tab ? "block" : "none";
        });
      });
    });
  }

  function bindActions() {
    const seed = document.getElementById("btn-seed");
    if (seed) seed.addEventListener("click", () => {
      Store.seedDemoOrders(40);
      UI.toast("Seeded 40 demo orders");
      renderAll();
    });
    const reset = document.getElementById("btn-reset");
    if (reset) reset.addEventListener("click", () => {
      if (!confirm("Wipe all orders, inventory, and loyalty data? This cannot be undone.")) return;
      Store.resetAll();
      UI.toast("All data reset");
      renderAll();
    });
    const csvOrders = document.getElementById("csv-orders");
    if (csvOrders) csvOrders.addEventListener("click", () => exportOrdersCSV());
    const csvProducts = document.getElementById("csv-products");
    if (csvProducts) csvProducts.addEventListener("click", () => exportProductsCSV());
    const csvInventory = document.getElementById("csv-inventory");
    if (csvInventory) csvInventory.addEventListener("click", () => exportInventoryCSV());

    document.querySelectorAll(".filters button[data-range]").forEach((b) => {
      b.addEventListener("click", () => {
        activeRange = b.getAttribute("data-range");
        document.querySelectorAll(".filters button[data-range]").forEach((x) => x.classList.toggle("active", x === b));
        renderAll();
      });
    });
  }

  function inRange(iso) {
    const t = new Date(iso).getTime();
    const now = Date.now();
    if (activeRange === "today") {
      const start = new Date(); start.setHours(0,0,0,0);
      return t >= start.getTime();
    }
    if (activeRange === "week") return t >= now - 7 * 24 * 60 * 60 * 1000;
    if (activeRange === "month") return t >= now - 30 * 24 * 60 * 60 * 1000;
    return true;
  }

  function renderAll() {
    renderKPIs();
    renderQueue();
    renderProductsTable();
    renderTopItems();
    renderInventory();
    renderLoyalty();
  }

  function getFilteredOrders() {
    return Store.getOrders().filter((o) => inRange(o.placedAt));
  }

  function renderKPIs() {
    const orders = getFilteredOrders();
    const revenue = orders.reduce((s, o) => s + (o.subtotal || 0), 0);
    const cost = orders.reduce((s, o) => s + (o.cost || 0), 0);
    const profit = revenue - cost;
    const margin = revenue > 0 ? (profit / revenue) * 100 : 0;
    const drinkCount = orders.reduce((s, o) => s + (o.lines || []).reduce((a, l) => a + l.qty, 0), 0);
    const aov = orders.length ? revenue / orders.length : 0;

    setKPI("kpi-revenue", Store.fmtUSD(revenue));
    setKPI("kpi-profit", Store.fmtUSD(profit));
    setKPI("kpi-orders", String(orders.length));
    setKPI("kpi-margin", margin.toFixed(1) + "%");
    setKPI("kpi-aov", Store.fmtUSD(aov));
    setKPI("kpi-cost", Store.fmtUSD(cost));
    setKPI("kpi-items", String(drinkCount));
    const range = { today: "today", week: "last 7 days", month: "last 30 days", all: "all time" }[activeRange];
    document.querySelectorAll("[data-range-label]").forEach((el) => el.textContent = range);
  }
  function setKPI(id, value) {
    const el = document.getElementById(id);
    if (el) el.textContent = value;
  }

  function renderQueue() {
    const tbody = document.getElementById("queue-body");
    if (!tbody) return;
    const queue = Store.getOrders().filter((o) => o.status !== "completed" && o.status !== "cancelled");
    if (!queue.length) {
      tbody.innerHTML = `<tr><td colspan="6" class="empty" style="padding:2rem;">No orders in queue. <button class="btn btn-outline btn-sm" id="btn-seed-2">Seed demo data</button></td></tr>`;
      const seed = document.getElementById("btn-seed-2");
      if (seed) seed.addEventListener("click", () => { Store.seedDemoOrders(20); renderAll(); });
      return;
    }
    tbody.innerHTML = queue.map((o) => `
      <tr>
        <td><strong>${o.id.slice(0, 10)}</strong><br><small>${new Date(o.placedAt).toLocaleTimeString([], { hour: "numeric", minute: "2-digit" })}</small></td>
        <td>${o.customer ? escapeHtml(o.customer.name || "Walk-in") : "Walk-in"}<br><small>${escapeHtml((o.customer && o.customer.phone) || "")}</small></td>
        <td>${(o.lines || []).map((l) => `${l.qty} × ${escapeHtml(l.label)}`).join("<br>")}</td>
        <td class="num">${Store.fmtUSD(o.total || 0)}</td>
        <td><span class="status ${o.status}">${o.status}</span></td>
        <td class="num">
          <select data-set-status="${o.id}">
            <option value="queued" ${o.status === "queued" ? "selected" : ""}>Queued</option>
            <option value="in-progress" ${o.status === "in-progress" ? "selected" : ""}>In progress</option>
            <option value="completed" ${o.status === "completed" ? "selected" : ""}>Completed</option>
            <option value="cancelled" ${o.status === "cancelled" ? "selected" : ""}>Cancelled</option>
          </select>
        </td>
      </tr>`).join("");
    tbody.querySelectorAll("[data-set-status]").forEach((sel) => {
      sel.addEventListener("change", () => {
        Store.updateOrderStatus(sel.getAttribute("data-set-status"), sel.value);
        renderAll();
      });
    });
  }

  function renderProductsTable() {
    const tbody = document.getElementById("products-body");
    if (!tbody) return;
    const orders = getFilteredOrders();
    const acc = {};
    const menu = Object.fromEntries(Store.getMenu().map((m) => [m.id, m]));
    orders.forEach((o) => (o.lines || []).forEach((l) => {
      const a = acc[l.menuItemId] || (acc[l.menuItemId] = { id: l.menuItemId, label: l.label, qty: 0, revenue: 0, cost: 0 });
      a.qty += l.qty;
      a.revenue += l.price;
      a.cost += l.cost;
    }));
    let rows = Object.values(acc).map((r) => ({
      ...r,
      profit: r.revenue - r.cost,
      margin: r.revenue ? ((r.revenue - r.cost) / r.revenue) * 100 : 0,
      price: menu[r.id] ? menu[r.id].price : 0,
      baseCost: menu[r.id] ? menu[r.id].baseCost : 0,
    })).sort((a, b) => b.profit - a.profit);

    if (!rows.length) {
      tbody.innerHTML = `<tr><td colspan="7" class="empty" style="padding:1.6rem;">No sales in this range yet.</td></tr>`;
      return;
    }
    tbody.innerHTML = rows.map((r) => `
      <tr>
        <td><strong>${escapeHtml(r.label)}</strong></td>
        <td class="num">${r.qty}</td>
        <td class="num">${Store.fmtUSD(r.price)}</td>
        <td class="num">${Store.fmtUSD(r.baseCost)}</td>
        <td class="num">${Store.fmtUSD(r.revenue)}</td>
        <td class="num">${Store.fmtUSD(r.cost)}</td>
        <td class="num pos">${Store.fmtUSD(r.profit)}<br><small style="color:var(--muted); font-weight:400;">${r.margin.toFixed(1)}%</small></td>
      </tr>`).join("");
  }

  function renderTopItems() {
    const wrap = document.getElementById("top-items");
    if (!wrap) return;
    const orders = getFilteredOrders();
    const acc = {};
    orders.forEach((o) => (o.lines || []).forEach((l) => {
      acc[l.menuItemId] = acc[l.menuItemId] || { label: l.label, profit: 0 };
      acc[l.menuItemId].profit += l.price - l.cost;
    }));
    const rows = Object.values(acc).sort((a, b) => b.profit - a.profit).slice(0, 8);
    const max = rows.length ? rows[0].profit : 1;
    if (!rows.length) {
      wrap.innerHTML = `<p class="muted">No sales yet.</p>`;
      return;
    }
    wrap.innerHTML = rows.map((r) => `
      <div class="bar-row">
        <span>${escapeHtml(r.label)}</span>
        <div class="bar"><div style="width:${Math.max(2, (r.profit / max) * 100)}%;"></div></div>
        <span class="num">${Store.fmtUSD(r.profit)}</span>
      </div>`).join("");
  }

  function renderInventory() {
    const tbody = document.getElementById("inventory-body");
    if (!tbody) return;
    const ings = Store.getIngredients();
    tbody.innerHTML = ings.map((ing) => {
      const low = ing.stock <= ing.reorderAt;
      return `
        <tr>
          <td><strong>${escapeHtml(ing.name)}</strong> <small class="muted">/${escapeHtml(ing.unit)}</small></td>
          <td class="num"><input type="number" min="0" step="0.01" value="${ing.cost}" data-cost="${ing.id}" /></td>
          <td class="num"><input type="number" min="0" step="0.1" value="${ing.stock}" data-stock="${ing.id}" /></td>
          <td class="num">${ing.reorderAt}</td>
          <td class="num ${low ? "warn" : "pos"}">${low ? "Low" : "OK"}</td>
        </tr>`;
    }).join("");
    tbody.querySelectorAll("input[data-cost]").forEach((inp) => {
      inp.addEventListener("change", () => {
        Store.setIngredientCost(inp.getAttribute("data-cost"), inp.value);
        UI.toast("Cost updated");
        renderProductsTable();
      });
    });
    tbody.querySelectorAll("input[data-stock]").forEach((inp) => {
      inp.addEventListener("change", () => {
        Store.setIngredientStock(inp.getAttribute("data-stock"), inp.value);
        UI.toast("Stock updated");
        renderInventory();
      });
    });
  }

  function renderLoyalty() {
    const tbody = document.getElementById("loyalty-body");
    if (!tbody) return;
    const raw = JSON.parse(localStorage.getItem(Store.KEYS.loyalty) || "{}");
    const rows = Object.entries(raw).map(([phone, v]) => ({ phone, ...v }))
      .sort((a, b) => (b.stars || 0) - (a.stars || 0));
    if (!rows.length) {
      tbody.innerHTML = `<tr><td colspan="4" class="empty" style="padding:1.6rem;">No loyalty members yet.</td></tr>`;
      return;
    }
    tbody.innerHTML = rows.map((r) => `
      <tr>
        <td>${escapeHtml(r.name || "Unknown")}</td>
        <td>${escapeHtml(formatPhone(r.phone))}</td>
        <td class="num">${r.stars || 0} ☆</td>
        <td><small class="muted">${r.lastVisit ? new Date(r.lastVisit).toLocaleDateString() : "—"}</small></td>
      </tr>`).join("");
  }

  function formatPhone(p) {
    const d = (p || "").replace(/\D/g, "");
    if (d.length === 10) return `(${d.slice(0,3)}) ${d.slice(3,6)}-${d.slice(6)}`;
    if (d.length === 11 && d[0] === "1") return `(${d.slice(1,4)}) ${d.slice(4,7)}-${d.slice(7)}`;
    return p;
  }

  function escapeHtml(s) {
    return String(s || "").replace(/[&<>"']/g, (c) => ({ "&":"&amp;","<":"&lt;",">":"&gt;","\"":"&quot;","'":"&#39;" }[c]));
  }

  // ---------- CSV exports (the "spreadsheet" the owner wanted) ----------
  function downloadCSV(filename, rows) {
    const csv = rows.map((row) => row.map(csvEscape).join(",")).join("\n");
    const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url; a.download = filename;
    document.body.appendChild(a); a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  }
  function csvEscape(v) {
    if (v == null) return "";
    const s = String(v);
    if (/[",\n]/.test(s)) return '"' + s.replace(/"/g, '""') + '"';
    return s;
  }

  function exportOrdersCSV() {
    const orders = getFilteredOrders();
    const header = ["Order ID","Date","Time","Customer","Phone","Item","Qty","Modifiers","Price ea","Cost ea","Line revenue","Line cost","Line profit","Order subtotal","Order tax","Order total","Order cost","Order profit","Order margin %","Status"];
    const rows = [header];
    orders.forEach((o) => {
      (o.lines || []).forEach((l) => {
        const mods = [];
        if (l.modifiers) {
          if (l.modifiers.size) mods.push(l.modifiers.size);
          if (l.modifiers.milk) mods.push(l.modifiers.milk + " milk");
          (l.modifiers.addons || []).forEach((a) => mods.push(a));
        }
        const margin = o.subtotal ? ((o.subtotal - o.cost) / o.subtotal) * 100 : 0;
        rows.push([
          o.id,
          new Date(o.placedAt).toISOString().split("T")[0],
          new Date(o.placedAt).toLocaleTimeString([], { hour: "numeric", minute: "2-digit" }),
          (o.customer && o.customer.name) || "",
          (o.customer && o.customer.phone) || "",
          l.label,
          l.qty,
          mods.join(" "),
          l.priceEach.toFixed(2),
          l.costEach.toFixed(2),
          l.price.toFixed(2),
          l.cost.toFixed(2),
          (l.price - l.cost).toFixed(2),
          o.subtotal.toFixed(2),
          o.tax.toFixed(2),
          o.total.toFixed(2),
          o.cost.toFixed(2),
          o.profit.toFixed(2),
          margin.toFixed(1),
          o.status,
        ]);
      });
    });
    downloadCSV(`lcr-orders-${activeRange}-${todayStamp()}.csv`, rows);
    UI.toast("Orders CSV downloaded");
  }

  function exportProductsCSV() {
    const orders = getFilteredOrders();
    const acc = {};
    const menu = Object.fromEntries(Store.getMenu().map((m) => [m.id, m]));
    orders.forEach((o) => (o.lines || []).forEach((l) => {
      const a = acc[l.menuItemId] || (acc[l.menuItemId] = { label: l.label, qty: 0, revenue: 0, cost: 0 });
      a.qty += l.qty;
      a.revenue += l.price;
      a.cost += l.cost;
    }));
    const header = ["Item","Sale price","Recipe COGS","Units sold","Revenue","Cost","Profit","Margin %"];
    const rows = [header];
    Object.entries(acc).forEach(([id, r]) => {
      const m = menu[id];
      const profit = r.revenue - r.cost;
      const margin = r.revenue ? (profit / r.revenue) * 100 : 0;
      rows.push([
        r.label,
        m ? m.price.toFixed(2) : "",
        m ? m.baseCost.toFixed(2) : "",
        r.qty,
        r.revenue.toFixed(2),
        r.cost.toFixed(2),
        profit.toFixed(2),
        margin.toFixed(1),
      ]);
    });
    downloadCSV(`lcr-products-${activeRange}-${todayStamp()}.csv`, rows);
    UI.toast("Products P&L CSV downloaded");
  }

  function exportInventoryCSV() {
    const ings = Store.getIngredients();
    const header = ["Ingredient","Unit","Cost per unit","Stock on hand","Reorder at","Status"];
    const rows = [header];
    ings.forEach((i) => {
      rows.push([
        i.name,
        i.unit,
        i.cost.toFixed(2),
        i.stock,
        i.reorderAt,
        i.stock <= i.reorderAt ? "LOW" : "OK",
      ]);
    });
    downloadCSV(`lcr-inventory-${todayStamp()}.csv`, rows);
    UI.toast("Inventory CSV downloaded");
  }

  function todayStamp() {
    const d = new Date();
    return d.toISOString().slice(0, 10);
  }

  document.addEventListener("DOMContentLoaded", init);
})();
