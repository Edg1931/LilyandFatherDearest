/**
 * Shared UI: nav drawer, cart drawer, toast, modal, footer year.
 * Loaded on every customer page.
 */

window.UI = (function () {
  function $(sel, root) { return (root || document).querySelector(sel); }
  function $all(sel, root) { return Array.from((root || document).querySelectorAll(sel)); }

  function init() {
    bindNav();
    bindCartDrawer();
    renderCart();
    setYear();
    document.addEventListener("cart:changed", renderCart);
  }

  function bindNav() {
    const toggle = $(".nav-toggle");
    const links = $(".nav-links");
    if (!toggle || !links) return;
    toggle.addEventListener("click", () => {
      const open = links.classList.toggle("open");
      toggle.setAttribute("aria-expanded", String(open));
    });
    links.addEventListener("click", (e) => {
      if (e.target.tagName === "A") {
        links.classList.remove("open");
        toggle.setAttribute("aria-expanded", "false");
      }
    });
  }

  function bindCartDrawer() {
    const openBtn = $("[data-open-cart]");
    const drawer = $("#cart-drawer");
    if (!openBtn || !drawer) return;
    const closeBtn = drawer.querySelector("[data-close-cart]");
    const backdrop = drawer.querySelector(".drawer-backdrop");
    function open() { drawer.classList.add("open"); document.body.classList.add("no-scroll"); }
    function close() { drawer.classList.remove("open"); document.body.classList.remove("no-scroll"); }
    openBtn.addEventListener("click", open);
    closeBtn && closeBtn.addEventListener("click", close);
    backdrop && backdrop.addEventListener("click", close);
    document.addEventListener("keydown", (e) => { if (e.key === "Escape") close(); });
    drawer.addEventListener("click", (e) => {
      const lineId = e.target.getAttribute && e.target.getAttribute("data-remove");
      if (lineId) Store.removeFromCart(lineId);
      const incId = e.target.getAttribute && e.target.getAttribute("data-inc");
      if (incId) {
        const cart = Store.getCart();
        const ln = cart.find((l) => l.lineId === incId);
        if (ln) Store.updateCartQty(incId, (ln.qty || 1) + 1);
      }
      const decId = e.target.getAttribute && e.target.getAttribute("data-dec");
      if (decId) {
        const cart = Store.getCart();
        const ln = cart.find((l) => l.lineId === decId);
        if (ln) {
          if ((ln.qty || 1) <= 1) Store.removeFromCart(decId);
          else Store.updateCartQty(decId, ln.qty - 1);
        }
      }
    });
  }

  function renderCart() {
    const drawer = $("#cart-drawer");
    if (!drawer) {
      const badge = $("[data-cart-count]");
      if (badge) {
        const n = Store.getCart().reduce((s, l) => s + (l.qty || 1), 0);
        badge.textContent = n;
        badge.style.display = n ? "inline-grid" : "none";
      }
      return;
    }
    const cart = Store.getCart();
    const list = drawer.querySelector("[data-cart-list]");
    const totals = drawer.querySelector("[data-cart-totals]");
    const count = $("[data-cart-count]");
    if (count) {
      const n = cart.reduce((s, l) => s + (l.qty || 1), 0);
      count.textContent = n;
      count.style.display = n ? "inline-grid" : "none";
    }
    if (!cart.length) {
      list.innerHTML = `<p class="cart-empty">Your cart is empty.<br><a class="btn btn-outline" href="menu.html">Browse the menu</a></p>`;
      totals.innerHTML = "";
      return;
    }
    list.innerHTML = cart.map((line) => {
      const p = Store.priceLine(line);
      const mods = describeMods(line.modifiers);
      return `
        <article class="cart-line">
          <header><strong>${p.label}</strong><span>${Store.fmtUSD(p.price)}</span></header>
          ${mods ? `<small class="cart-mods">${mods}</small>` : ""}
          <div class="cart-line-actions">
            <button class="qty-btn" aria-label="Decrease" data-dec="${line.lineId}">−</button>
            <span class="qty">${line.qty}</span>
            <button class="qty-btn" aria-label="Increase" data-inc="${line.lineId}">+</button>
            <button class="text-btn" data-remove="${line.lineId}">Remove</button>
          </div>
        </article>`;
    }).join("");

    const t = Store.cartTotals();
    totals.innerHTML = `
      <div class="row"><span>Subtotal</span><span>${Store.fmtUSD(t.subtotal)}</span></div>
      <div class="row"><span>Tax</span><span>${Store.fmtUSD(t.tax)}</span></div>
      <div class="row total"><span>Total</span><span>${Store.fmtUSD(t.total)}</span></div>
      <a class="btn btn-primary btn-block" href="checkout.html">Checkout</a>
    `;
  }

  function describeMods(mods) {
    if (!mods) return "";
    const parts = [];
    if (mods.size && mods.size !== "16oz") parts.push(mods.size);
    if (mods.milk && mods.milk !== "whole") parts.push(mods.milk + " milk");
    (mods.addons || []).forEach((a) => parts.push(a.replace("_", " ")));
    return parts.join(" · ");
  }

  function toast(msg) {
    let el = $("#toast");
    if (!el) {
      el = document.createElement("div");
      el.id = "toast";
      el.className = "toast";
      document.body.appendChild(el);
    }
    el.textContent = msg;
    el.classList.add("show");
    clearTimeout(el._t);
    el._t = setTimeout(() => el.classList.remove("show"), 2200);
  }

  function setYear() {
    const y = $("#year");
    if (y) y.textContent = String(new Date().getFullYear());
  }

  document.addEventListener("DOMContentLoaded", init);

  return { renderCart, toast };
})();
