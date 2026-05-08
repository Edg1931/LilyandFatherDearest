/**
 * Menu page: render items by category, drink customization modal,
 * add-to-cart with selected size/milk/addons/qty.
 */

(function () {
  const CATEGORIES = [
    { id: "all",      label: "All" },
    { id: "espresso", label: "Espresso" },
    { id: "brewed",   label: "Brewed coffee" },
    { id: "boba",     label: "Boba & Tea" },
    { id: "pastry",   label: "Pastries" },
    { id: "retail",   label: "Take home" },
  ];

  let activeCategory = "all";

  function init() {
    renderTabs();
    renderItems();
    bindModal();

    // Deep-link: scroll to and open an item if URL hash matches
    if (location.hash) {
      const id = location.hash.slice(1);
      const item = Store.getMenuItem(id);
      if (item) setTimeout(() => openCustomizer(id), 100);
    }
  }

  function renderTabs() {
    const tabs = document.getElementById("category-tabs");
    if (!tabs) return;
    tabs.innerHTML = CATEGORIES.map((c) =>
      `<button data-cat="${c.id}" class="${c.id === activeCategory ? "active" : ""}">${c.label}</button>`
    ).join("");
    tabs.addEventListener("click", (e) => {
      const cat = e.target.getAttribute("data-cat");
      if (!cat) return;
      activeCategory = cat;
      tabs.querySelectorAll("button").forEach((b) =>
        b.classList.toggle("active", b.getAttribute("data-cat") === cat)
      );
      renderItems();
    });
  }

  function renderItems() {
    const grid = document.getElementById("menu-grid");
    if (!grid) return;
    const items = Store.getMenu().filter(
      (m) => activeCategory === "all" || m.category === activeCategory
    );
    if (!items.length) {
      grid.innerHTML = `<p class="muted">Nothing here yet.</p>`;
      return;
    }
    grid.innerHTML = items.map((m) => `
      <article class="menu-item ${m.featured ? "featured" : ""}" id="${m.id}">
        ${m.featured ? '<span class="badge">Favorite</span>' : ""}
        <h3>${m.name}</h3>
        <p>${m.tagline}</p>
        <div class="flavor-tags">${(m.flavor || []).map((f) => `<span>${f}</span>`).join("")}</div>
        <div class="row">
          <span class="price">${Store.fmtUSD(m.price)}</span>
          <button class="btn ${m.featured ? "btn-outline" : "btn-primary"} btn-sm" data-add="${m.id}">Add</button>
        </div>
      </article>`).join("");

    grid.addEventListener("click", function onClick(e) {
      const id = e.target.getAttribute && e.target.getAttribute("data-add");
      if (id) openCustomizer(id);
    });
  }

  // ---------- Drink customizer modal ----------
  let modalState = {};

  function openCustomizer(id) {
    const item = Store.getMenuItem(id);
    if (!item) return;
    const offersSize = ["espresso", "brewed", "boba"].includes(item.category);
    const offersMilk = ["espresso", "boba"].includes(item.category);
    const offersAddons = item.category !== "retail";

    modalState = {
      id,
      qty: 1,
      size: offersSize ? "16oz" : null,
      milk: offersMilk ? "whole" : null,
      addons: [],
    };
    renderModal(item, offersSize, offersMilk, offersAddons);
    document.getElementById("modal").classList.add("open");
  }

  function closeCustomizer() {
    document.getElementById("modal").classList.remove("open");
  }

  function renderModal(item, offersSize, offersMilk, offersAddons) {
    const m = document.getElementById("modal-content");
    if (!m) return;
    m.innerHTML = `
      <div class="modal-head">
        <h2>${item.name}</h2>
        <button class="drawer-close" data-close-modal aria-label="Close">×</button>
      </div>
      <div class="modal-body">
        <p class="muted" style="margin-top:-0.4rem;">${item.tagline}</p>

        ${offersSize ? `
          <div class="modal-section">
            <h4>Size</h4>
            <div class="option-grid">
              ${LCR_DATA.modifiers.size.map((s) => `
                <button class="option ${modalState.size === s.id ? "selected" : ""}" data-size="${s.id}">
                  ${s.label}${s.priceDelta ? `<br><small>${s.priceDelta > 0 ? "+" : ""}${Store.fmtUSD(s.priceDelta)}</small>` : ""}
                </button>`).join("")}
            </div>
          </div>` : ""}

        ${offersMilk ? `
          <div class="modal-section">
            <h4>Milk</h4>
            <div class="option-grid cols-2">
              ${LCR_DATA.modifiers.milk.map((mk) => `
                <button class="option ${modalState.milk === mk.id ? "selected" : ""}" data-milk="${mk.id}">
                  ${mk.label}${mk.priceDelta ? `<br><small>+${Store.fmtUSD(mk.priceDelta)}</small>` : ""}
                </button>`).join("")}
            </div>
          </div>` : ""}

        ${offersAddons ? `
          <div class="modal-section">
            <h4>Add-ons</h4>
            ${LCR_DATA.modifiers.addons.map((a) => `
              <div class="option-row ${modalState.addons.includes(a.id) ? "selected" : ""}" data-addon="${a.id}">
                <span>${a.label}</span><small>+${Store.fmtUSD(a.priceDelta)}</small>
              </div>`).join("")}
          </div>` : ""}
      </div>
      <div class="modal-foot">
        <div class="qty-stepper">
          <button data-qty="-1" aria-label="Decrease">−</button>
          <span id="modal-qty">${modalState.qty}</span>
          <button data-qty="1" aria-label="Increase">+</button>
        </div>
        <span class="modal-total" id="modal-total">${Store.fmtUSD(currentPrice(item))}</span>
        <button class="btn btn-primary" data-confirm>Add to cart</button>
      </div>`;
  }

  function currentPrice(item) {
    const fakeLine = {
      menuItemId: item.id,
      qty: modalState.qty,
      modifiers: { size: modalState.size, milk: modalState.milk, addons: modalState.addons },
    };
    return Store.priceLine(fakeLine).price;
  }

  function bindModal() {
    const wrap = document.getElementById("modal");
    if (!wrap) return;
    wrap.addEventListener("click", (e) => {
      if (e.target === wrap) closeCustomizer();
      if (e.target.hasAttribute("data-close-modal")) closeCustomizer();

      const size = e.target.getAttribute && e.target.getAttribute("data-size");
      if (size) {
        modalState.size = size;
        const item = Store.getMenuItem(modalState.id);
        renderModal(item, true, modalState.milk != null, true);
        return;
      }
      const milk = e.target.getAttribute && e.target.getAttribute("data-milk");
      if (milk) {
        modalState.milk = milk;
        const item = Store.getMenuItem(modalState.id);
        renderModal(item, modalState.size != null, true, true);
        return;
      }
      const row = e.target.closest && e.target.closest("[data-addon]");
      if (row) {
        const aid = row.getAttribute("data-addon");
        const idx = modalState.addons.indexOf(aid);
        if (idx >= 0) modalState.addons.splice(idx, 1);
        else modalState.addons.push(aid);
        const item = Store.getMenuItem(modalState.id);
        renderModal(item, modalState.size != null, modalState.milk != null, true);
        return;
      }
      const dq = e.target.getAttribute && e.target.getAttribute("data-qty");
      if (dq) {
        modalState.qty = Math.max(1, modalState.qty + parseInt(dq, 10));
        const item = Store.getMenuItem(modalState.id);
        renderModal(item, modalState.size != null, modalState.milk != null, ["espresso","brewed","boba","pastry"].includes(item.category));
        return;
      }
      if (e.target.hasAttribute("data-confirm")) {
        Store.addToCart({
          menuItemId: modalState.id,
          qty: modalState.qty,
          modifiers: { size: modalState.size, milk: modalState.milk, addons: modalState.addons.slice() },
        });
        const item = Store.getMenuItem(modalState.id);
        UI.toast(`${modalState.qty} × ${item.name} added`);
        closeCustomizer();
      }
    });
    document.addEventListener("keydown", (e) => { if (e.key === "Escape") closeCustomizer(); });
  }

  document.addEventListener("DOMContentLoaded", init);
})();
