/**
 * Checkout: render cart summary, take customer info, place order.
 * On confirmation it shows the order ID + loyalty stars earned.
 */

(function () {
  function init() {
    const root = document.getElementById("checkout-root");
    if (!root) return;
    const cart = Store.getCart();
    if (!cart.length) {
      renderEmpty(root);
      return;
    }
    renderForm(root);
    bindForm();
    fillPickupTimes();
  }

  function renderEmpty(root) {
    root.innerHTML = `
      <div class="confirmation">
        <h1>Your cart is empty</h1>
        <p class="muted">Add a drink to get started.</p>
        <a class="btn btn-primary" href="menu.html">Browse the menu</a>
      </div>`;
  }

  function renderForm(root) {
    root.innerHTML = `
      <div class="checkout-grid">
        <div>
          <p class="eyebrow">Almost there</p>
          <h1>Your order.</h1>
          <p class="lede">Drop your details and we'll have it ready when you arrive.</p>

          <form id="checkout-form" novalidate>
            <div class="form-grid">
              <div class="field"><label for="name">Name</label><input id="name" name="name" required autocomplete="name" /></div>
              <div class="field"><label for="phone">Phone</label><input id="phone" name="phone" required type="tel" autocomplete="tel" placeholder="(440) 555-0123" /></div>
              <div class="field"><label for="pickup">Pickup time</label><select id="pickup" name="pickup"></select></div>
              <div class="field"><label for="payment">Payment</label>
                <select id="payment" name="payment">
                  <option value="card">Credit / debit (pay at counter)</option>
                  <option value="apple">Apple Pay (pay at counter)</option>
                  <option value="cash">Cash</option>
                </select>
              </div>
              <div class="field full"><label for="notes">Notes for the barista (optional)</label><textarea id="notes" name="notes" placeholder="Light ice, please..."></textarea></div>
            </div>
            <button class="btn btn-primary" type="submit" style="margin-top:1.4rem;">Place order</button>
            <p class="muted" style="margin-top:0.8rem; font-size:0.85rem;">We'll text you when it's ready. No spam — just your drink.</p>
          </form>
        </div>

        <aside class="summary" id="summary"></aside>
      </div>`;

    renderSummary();
  }

  function fillPickupTimes() {
    const sel = document.getElementById("pickup");
    if (!sel) return;
    const now = new Date();
    const opts = ["ASAP (10 min)"];
    for (let i = 1; i <= 8; i++) {
      const t = new Date(now.getTime() + (10 + i * 10) * 60 * 1000);
      opts.push(t.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" }));
    }
    sel.innerHTML = opts.map((o) => `<option>${o}</option>`).join("");
  }

  function renderSummary() {
    const wrap = document.getElementById("summary");
    if (!wrap) return;
    const cart = Store.getCart();
    const t = Store.cartTotals();
    wrap.innerHTML = `
      <h3>Order summary</h3>
      ${cart.map((line) => {
        const p = Store.priceLine(line);
        return `<div class="summary-line"><span>${line.qty} × ${p.label}</span><span>${Store.fmtUSD(p.price)}</span></div>`;
      }).join("")}
      <div class="summary-line"><span>Subtotal</span><span>${Store.fmtUSD(t.subtotal)}</span></div>
      <div class="summary-line"><span>Tax</span><span>${Store.fmtUSD(t.tax)}</span></div>
      <div class="summary-line total"><span>Total</span><span>${Store.fmtUSD(t.total)}</span></div>
      <p class="muted" style="margin-top:0.8rem; font-size:0.82rem;">Earn 1 ☆ per drink. 10 ☆ = a free drink on us.</p>`;
  }

  function bindForm() {
    const form = document.getElementById("checkout-form");
    if (!form) return;
    form.addEventListener("submit", (e) => {
      e.preventDefault();
      const data = Object.fromEntries(new FormData(form).entries());
      if (!data.name || !data.phone) {
        UI.toast("Please add your name and phone.");
        return;
      }
      const order = Store.placeOrder({
        name: data.name,
        phone: data.phone,
        pickupTime: data.pickup,
        notes: data.notes,
        payment: data.payment,
      });
      sessionStorage.setItem("lcr.lastOrder", order.id);
      location.href = "checkout.html?confirm=" + order.id;
    });
  }

  // ---------- Confirmation rendering ----------
  function maybeRenderConfirmation() {
    const id = new URLSearchParams(location.search).get("confirm");
    if (!id) return false;
    const root = document.getElementById("checkout-root");
    if (!root) return false;
    const order = Store.getOrders().find((o) => o.id === id);
    if (!order) return false;

    const stars = order.starsEarned || 0;
    const balance = order.starsBalance || 0;
    const earned = stars
      ? `<div class="stars-banner">⭐ +${stars} stars earned · You have ${balance} ☆${balance >= 10 ? " — that's a free drink next visit!" : ""}</div>`
      : "";

    root.innerHTML = `
      <div class="confirmation">
        <div class="check">✓</div>
        <h1>Order placed!</h1>
        <p class="muted">Thank you, ${escapeHtml(order.customer.name || "friend")}. We'll text you when it's ready.</p>
        <p class="order-id">${order.id.toUpperCase()}</p>
        <div class="summary" style="max-width:420px; margin:0 auto; text-align:left;">
          <h3 style="text-align:center;">Pickup at ${escapeHtml(order.pickupTime || "ASAP")}</h3>
          ${order.lines.map((l) => `<div class="summary-line"><span>${l.qty} × ${escapeHtml(l.label)}</span><span>${Store.fmtUSD(l.price)}</span></div>`).join("")}
          <div class="summary-line"><span>Subtotal</span><span>${Store.fmtUSD(order.subtotal)}</span></div>
          <div class="summary-line"><span>Tax</span><span>${Store.fmtUSD(order.tax)}</span></div>
          <div class="summary-line total"><span>Total</span><span>${Store.fmtUSD(order.total)}</span></div>
        </div>
        ${earned}
        <p style="margin-top:1.6rem;"><a class="btn btn-outline" href="menu.html">Order something else</a> <a class="btn btn-primary" href="index.html">Back to home</a></p>
        <p class="muted" style="margin-top:1.4rem; font-size:0.85rem;">Need to change something? Call <a href="tel:+14406539314">(440) 653-9314</a>.</p>
      </div>`;
    return true;
  }

  function escapeHtml(s) {
    return String(s || "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
  }

  document.addEventListener("DOMContentLoaded", () => {
    if (maybeRenderConfirmation()) return;
    init();
  });
})();
