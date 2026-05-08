/**
 * Master data: ingredients (with costs), menu items (with recipes & prices),
 * and modifiers (sizes / milk swaps). Everything the customer site and the
 * owner dashboard read from. Ingredient costs and menu prices can be edited
 * live in the admin and are persisted to localStorage; this file is the seed.
 */

window.LCR_DATA = (function () {
  // --------------------------------------------------------------------------
  // Ingredients (raw inventory)
  // cost  = wholesale cost per unit to the shop
  // unit  = the unit a recipe consumes (oz, shot, ea, scoop)
  // stock = on-hand units; reorder threshold triggers a low-stock alert
  // --------------------------------------------------------------------------
  const ingredients = [
    { id: "espresso_shot",   name: "Espresso shot",         unit: "shot",  cost: 0.32, stock: 1400, reorderAt: 200 },
    { id: "drip_coffee_oz",  name: "Drip coffee",           unit: "oz",    cost: 0.05, stock: 1800, reorderAt: 300 },
    { id: "cold_brew_oz",    name: "Cold brew concentrate", unit: "oz",    cost: 0.18, stock: 800,  reorderAt: 150 },
    { id: "whole_milk_oz",   name: "Whole milk",            unit: "oz",    cost: 0.06, stock: 1600, reorderAt: 250 },
    { id: "oat_milk_oz",     name: "Oat milk",              unit: "oz",    cost: 0.14, stock: 900,  reorderAt: 200 },
    { id: "almond_milk_oz",  name: "Almond milk",           unit: "oz",    cost: 0.12, stock: 600,  reorderAt: 150 },
    { id: "matcha_g",        name: "Ceremonial matcha",     unit: "g",     cost: 0.95, stock: 400,  reorderAt: 80 },
    { id: "chai_concentrate", name: "Chai concentrate",      unit: "oz",    cost: 0.22, stock: 500,  reorderAt: 100 },
    { id: "lavender_syrup",  name: "Lavender syrup",        unit: "oz",    cost: 0.30, stock: 220,  reorderAt: 40 },
    { id: "vanilla_syrup",   name: "Vanilla syrup",         unit: "oz",    cost: 0.18, stock: 300,  reorderAt: 60 },
    { id: "brown_sugar_oz",  name: "Brown sugar syrup",     unit: "oz",    cost: 0.16, stock: 280,  reorderAt: 50 },
    { id: "tiramisu_cream",  name: "Tiramisu cream",        unit: "oz",    cost: 0.45, stock: 180,  reorderAt: 40 },
    { id: "cocoa_dust",      name: "Cocoa dust",            unit: "g",     cost: 0.04, stock: 600,  reorderAt: 100 },
    { id: "boba_pearls",     name: "Tapioca pearls",        unit: "oz",    cost: 0.20, stock: 700,  reorderAt: 120 },
    { id: "black_tea_oz",    name: "Black tea",             unit: "oz",    cost: 0.08, stock: 900,  reorderAt: 150 },
    { id: "green_tea_oz",    name: "Green tea",             unit: "oz",    cost: 0.09, stock: 700,  reorderAt: 120 },
    { id: "cup_12oz",        name: "12oz cup + lid",        unit: "ea",    cost: 0.22, stock: 800,  reorderAt: 150 },
    { id: "cup_16oz",        name: "16oz cup + lid",        unit: "ea",    cost: 0.26, stock: 900,  reorderAt: 150 },
    { id: "cup_20oz",        name: "20oz cup + lid",        unit: "ea",    cost: 0.30, stock: 600,  reorderAt: 120 },
    { id: "straw",           name: "Reusable-grade straw",  unit: "ea",    cost: 0.04, stock: 1200, reorderAt: 200 },
    { id: "sleeve",          name: "Cup sleeve",            unit: "ea",    cost: 0.05, stock: 1400, reorderAt: 250 },
    { id: "croissant_choc",  name: "Chocolate croissant",   unit: "ea",    cost: 1.10, stock: 40,   reorderAt: 12 },
    { id: "scone",           name: "Seasonal scone",        unit: "ea",    cost: 0.95, stock: 36,   reorderAt: 12 },
    { id: "cookie",          name: "House cookie",          unit: "ea",    cost: 0.55, stock: 60,   reorderAt: 18 },
    { id: "bean_bag_12oz",   name: "Bean bag (12oz, retail)", unit: "ea",  cost: 6.50, stock: 80,   reorderAt: 20 },
  ];

  // --------------------------------------------------------------------------
  // Menu items
  // Each `recipe` lists ingredient ids and quantities consumed per drink.
  // Prices and costs are computed live from this so the admin stays accurate.
  // --------------------------------------------------------------------------
  const menu = [
    // ---------- Espresso ----------
    {
      id: "lavender_vanilla_latte",
      category: "espresso",
      name: "Lavender Vanilla Latte",
      tagline: "House-made lavender, Madagascar vanilla, velvety double shot.",
      price: 6.00,
      featured: true,
      caffeine: "high",
      flavor: ["floral", "sweet", "creamy"],
      recipe: [
        { id: "espresso_shot", qty: 2 },
        { id: "whole_milk_oz", qty: 10 },
        { id: "lavender_syrup", qty: 0.5 },
        { id: "vanilla_syrup", qty: 0.5 },
        { id: "cup_16oz", qty: 1 },
        { id: "sleeve", qty: 1 },
      ],
    },
    {
      id: "tiramisu_latte",
      category: "espresso",
      name: "Tiramisu Latte",
      tagline: "Espresso, mascarpone-style cream, dust of cocoa.",
      price: 6.50,
      featured: true,
      caffeine: "high",
      flavor: ["sweet", "creamy", "chocolate"],
      recipe: [
        { id: "espresso_shot", qty: 2 },
        { id: "whole_milk_oz", qty: 8 },
        { id: "tiramisu_cream", qty: 1 },
        { id: "cocoa_dust", qty: 1 },
        { id: "cup_16oz", qty: 1 },
        { id: "sleeve", qty: 1 },
      ],
    },
    {
      id: "classic_latte",
      category: "espresso",
      name: "Classic Latte",
      tagline: "Double shot, steamed whole milk, microfoam.",
      price: 5.00,
      caffeine: "high",
      flavor: ["balanced", "creamy"],
      recipe: [
        { id: "espresso_shot", qty: 2 },
        { id: "whole_milk_oz", qty: 10 },
        { id: "cup_16oz", qty: 1 },
        { id: "sleeve", qty: 1 },
      ],
    },
    {
      id: "cappuccino",
      category: "espresso",
      name: "Cappuccino",
      tagline: "Equal parts espresso, milk, and microfoam.",
      price: 4.50,
      caffeine: "high",
      flavor: ["balanced", "bold"],
      recipe: [
        { id: "espresso_shot", qty: 2 },
        { id: "whole_milk_oz", qty: 4 },
        { id: "cup_12oz", qty: 1 },
        { id: "sleeve", qty: 1 },
      ],
    },
    {
      id: "cortado",
      category: "espresso",
      name: "Cortado",
      tagline: "Equal espresso, equal warm milk. Tiny but mighty.",
      price: 4.25,
      caffeine: "high",
      flavor: ["balanced", "bold"],
      recipe: [
        { id: "espresso_shot", qty: 2 },
        { id: "whole_milk_oz", qty: 2 },
        { id: "cup_12oz", qty: 1 },
      ],
    },
    {
      id: "americano",
      category: "espresso",
      name: "Americano",
      tagline: "Double shot pulled long over hot water.",
      price: 3.75,
      caffeine: "high",
      flavor: ["bold", "clean"],
      recipe: [
        { id: "espresso_shot", qty: 2 },
        { id: "cup_12oz", qty: 1 },
        { id: "sleeve", qty: 1 },
      ],
    },

    // ---------- Brewed ----------
    {
      id: "pour_over",
      category: "brewed",
      name: "Pour Over",
      tagline: "Single-origin, brewed to order. Ask what's pouring today.",
      price: 4.50,
      caffeine: "med",
      flavor: ["clean", "bright"],
      recipe: [
        { id: "drip_coffee_oz", qty: 12 },
        { id: "cup_12oz", qty: 1 },
        { id: "sleeve", qty: 1 },
      ],
    },
    {
      id: "drip_coffee",
      category: "brewed",
      name: "Drip Coffee",
      tagline: "Our daily roast, hot and ready.",
      price: 3.25,
      caffeine: "med",
      flavor: ["balanced"],
      recipe: [
        { id: "drip_coffee_oz", qty: 12 },
        { id: "cup_12oz", qty: 1 },
        { id: "sleeve", qty: 1 },
      ],
    },
    {
      id: "cold_brew",
      category: "brewed",
      name: "Cold Brew",
      tagline: "Steeped 18 hours. Smooth, mellow, never bitter.",
      price: 4.75,
      caffeine: "high",
      flavor: ["smooth", "bold"],
      recipe: [
        { id: "cold_brew_oz", qty: 10 },
        { id: "cup_16oz", qty: 1 },
        { id: "straw", qty: 1 },
      ],
    },

    // ---------- Boba & Tea ----------
    {
      id: "brown_sugar_boba",
      category: "boba",
      name: "Brown Sugar Boba Milk",
      tagline: "Slow-cooked tapioca, caramelized brown sugar, whole milk.",
      price: 6.00,
      featured: true,
      caffeine: "low",
      flavor: ["sweet", "creamy"],
      recipe: [
        { id: "boba_pearls", qty: 2 },
        { id: "whole_milk_oz", qty: 12 },
        { id: "brown_sugar_oz", qty: 1.5 },
        { id: "cup_20oz", qty: 1 },
        { id: "straw", qty: 1 },
      ],
    },
    {
      id: "matcha_latte",
      category: "boba",
      name: "Iced Matcha Latte",
      tagline: "Stone-ground ceremonial matcha, oat milk, lightly sweet.",
      price: 5.75,
      caffeine: "med",
      flavor: ["earthy", "creamy", "balanced"],
      recipe: [
        { id: "matcha_g", qty: 3 },
        { id: "oat_milk_oz", qty: 12 },
        { id: "vanilla_syrup", qty: 0.5 },
        { id: "cup_16oz", qty: 1 },
        { id: "straw", qty: 1 },
      ],
    },
    {
      id: "chai_latte",
      category: "boba",
      name: "Spiced Chai Latte",
      tagline: "Hand-mixed masala chai, steamed whole milk.",
      price: 5.25,
      caffeine: "med",
      flavor: ["spiced", "creamy"],
      recipe: [
        { id: "chai_concentrate", qty: 4 },
        { id: "whole_milk_oz", qty: 8 },
        { id: "cup_16oz", qty: 1 },
        { id: "sleeve", qty: 1 },
      ],
    },
    {
      id: "jasmine_milk_tea",
      category: "boba",
      name: "Jasmine Milk Tea",
      tagline: "Floral jasmine green, whole milk, optional boba.",
      price: 5.25,
      caffeine: "low",
      flavor: ["floral", "creamy"],
      recipe: [
        { id: "green_tea_oz", qty: 8 },
        { id: "whole_milk_oz", qty: 6 },
        { id: "vanilla_syrup", qty: 0.5 },
        { id: "cup_16oz", qty: 1 },
        { id: "straw", qty: 1 },
      ],
    },

    // ---------- Pastries / Retail ----------
    {
      id: "chocolate_croissant",
      category: "pastry",
      name: "Chocolate Croissant",
      tagline: "Buttery layers around a ribbon of dark chocolate.",
      price: 4.00,
      caffeine: "none",
      flavor: ["sweet", "chocolate"],
      recipe: [{ id: "croissant_choc", qty: 1 }],
    },
    {
      id: "seasonal_scone",
      category: "pastry",
      name: "Seasonal Scone",
      tagline: "Tender, crumbly, rotating with the season.",
      price: 3.75,
      caffeine: "none",
      flavor: ["sweet"],
      recipe: [{ id: "scone", qty: 1 }],
    },
    {
      id: "house_cookie",
      category: "pastry",
      name: "House Cookie",
      tagline: "Brown-butter, sea salt, big chocolate chunks.",
      price: 2.75,
      caffeine: "none",
      flavor: ["sweet", "chocolate"],
      recipe: [{ id: "cookie", qty: 1 }],
    },
    {
      id: "bean_bag",
      category: "retail",
      name: "Whole Bean — 12oz",
      tagline: "Take the daily roast home. Whole bean or ground at request.",
      price: 19.00,
      caffeine: "none",
      flavor: [],
      recipe: [{ id: "bean_bag_12oz", qty: 1 }],
    },
  ];

  // --------------------------------------------------------------------------
  // Modifiers — small price/cost deltas customers can pick at order time.
  // costDelta is added to the line cost; priceDelta is added to the line price.
  // --------------------------------------------------------------------------
  const modifiers = {
    size: [
      { id: "12oz", label: "12 oz", priceDelta: -0.50, costDelta: -0.04 },
      { id: "16oz", label: "16 oz", priceDelta: 0,     costDelta: 0,     default: true },
      { id: "20oz", label: "20 oz", priceDelta: 0.75,  costDelta: 0.10 },
    ],
    milk: [
      { id: "whole",   label: "Whole milk",  priceDelta: 0,    costDelta: 0, default: true },
      { id: "oat",     label: "Oat milk",    priceDelta: 0.75, costDelta: 0.30 },
      { id: "almond",  label: "Almond milk", priceDelta: 0.75, costDelta: 0.25 },
      { id: "skim",    label: "Skim milk",   priceDelta: 0,    costDelta: -0.02 },
    ],
    addons: [
      { id: "extra_shot", label: "Extra espresso shot", priceDelta: 1.00, costDelta: 0.32 },
      { id: "boba",       label: "Add boba",            priceDelta: 1.00, costDelta: 0.20 },
      { id: "syrup",      label: "Extra flavor pump",   priceDelta: 0.75, costDelta: 0.18 },
    ],
  };

  return { ingredients, menu, modifiers };
})();
