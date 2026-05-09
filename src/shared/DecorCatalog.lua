local DecorCatalog = {}

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

DecorCatalog.CATEGORIES = { "Beds", "Bowls", "Furniture", "Lighting", "WallArt", "Outdoor", "Themed" }

DecorCatalog.ITEMS = {
	-- ============ BEDS ============
	bed_basic_blue   = { name = "Blue Dog Bed",     category = "Beds",      price = 80,   size = Vector3.new(4, 1, 3),   color = rgb(80, 130, 200),  material = Enum.Material.Fabric,    icon = "🛏️" },
	bed_basic_pink   = { name = "Pink Dog Bed",     category = "Beds",      price = 80,   size = Vector3.new(4, 1, 3),   color = rgb(220, 140, 180), material = Enum.Material.Fabric,    icon = "🛏️" },
	bed_plush_cream  = { name = "Cream Plush Bed",  category = "Beds",      price = 220,  size = Vector3.new(5, 1.4, 4), color = rgb(245, 235, 220), material = Enum.Material.Fabric,    icon = "🛌" },
	bed_royal        = { name = "Royal Velvet Bed", category = "Beds",      price = 1200, size = Vector3.new(5, 1.6, 4), color = rgb(120, 40, 60),   material = Enum.Material.Fabric,    icon = "👑" },
	bed_neon         = { name = "Neon Float Bed",   category = "Beds",      price = 4500, size = Vector3.new(5, 1.4, 4), color = rgb(80, 220, 220),  material = Enum.Material.Neon,      icon = "✨" },

	-- ============ BOWLS ============
	bowl_metal       = { name = "Metal Bowl",       category = "Bowls",     price = 30,   size = Vector3.new(1.6, 0.8, 1.6), color = rgb(180, 180, 190), material = Enum.Material.Metal,  icon = "🥣" },
	bowl_ceramic     = { name = "Ceramic Bowl",     category = "Bowls",     price = 70,   size = Vector3.new(1.6, 0.8, 1.6), color = rgb(220, 200, 180), material = Enum.Material.Marble, icon = "🍚" },
	bowl_double      = { name = "Double Diner",     category = "Bowls",     price = 200,  size = Vector3.new(3.2, 1, 1.6),   color = rgb(60, 60, 70),    material = Enum.Material.Metal,  icon = "🍽️" },

	-- ============ FURNITURE ============
	sofa_leather     = { name = "Leather Sofa",     category = "Furniture", price = 600,  size = Vector3.new(8, 3, 3.5), color = rgb(80, 50, 40),    material = Enum.Material.Fabric,    icon = "🛋️" },
	sofa_pastel      = { name = "Pastel Sofa",      category = "Furniture", price = 500,  size = Vector3.new(8, 3, 3.5), color = rgb(220, 200, 230), material = Enum.Material.Fabric,    icon = "🛋️" },
	armchair         = { name = "Reading Chair",    category = "Furniture", price = 250,  size = Vector3.new(3, 3.4, 3), color = rgb(150, 100, 80),  material = Enum.Material.Fabric,    icon = "🪑" },
	table_round      = { name = "Round Table",      category = "Furniture", price = 180,  size = Vector3.new(4, 2.4, 4), color = rgb(180, 130, 80),  material = Enum.Material.Wood,      icon = "🛋️" },
	bookshelf        = { name = "Bookshelf",        category = "Furniture", price = 400,  size = Vector3.new(2, 8, 5),   color = rgb(120, 80, 50),   material = Enum.Material.Wood,      icon = "📚" },
	rug_persian      = { name = "Persian Rug",      category = "Furniture", price = 350,  size = Vector3.new(8, 0.2, 5), color = rgb(180, 60, 60),   material = Enum.Material.Fabric,    icon = "🟧" },
	piano            = { name = "Upright Piano",    category = "Furniture", price = 2200, size = Vector3.new(2, 5, 6),   color = rgb(20, 20, 25),    material = Enum.Material.Wood,      icon = "🎹" },

	-- ============ LIGHTING ============
	floor_lamp       = { name = "Floor Lamp",       category = "Lighting",  price = 150,  size = Vector3.new(1.4, 7, 1.4), color = rgb(255, 240, 200), material = Enum.Material.SmoothPlastic, light = true, icon = "💡" },
	pendant_light    = { name = "Pendant Light",    category = "Lighting",  price = 220,  size = Vector3.new(2.4, 1.6, 2.4), color = rgb(255, 220, 160), material = Enum.Material.Neon, light = true, icon = "🔆" },
	fairy_lights     = { name = "Fairy Lights",     category = "Lighting",  price = 180,  size = Vector3.new(8, 0.4, 0.4), color = rgb(255, 220, 150), material = Enum.Material.Neon, light = true, icon = "🌟" },
	chandelier       = { name = "Chandelier",       category = "Lighting",  price = 1400, size = Vector3.new(4, 3, 4), color = rgb(255, 240, 200), material = Enum.Material.Glass, light = true, icon = "🕯️" },

	-- ============ WALL ART ============
	painting_dog     = { name = "Dog Painting",     category = "WallArt",   price = 200,  size = Vector3.new(4, 3, 0.2), color = rgb(220, 200, 160), material = Enum.Material.Fabric,    icon = "🖼️" },
	painting_landscape = { name = "Landscape",      category = "WallArt",   price = 280,  size = Vector3.new(5, 3, 0.2), color = rgb(120, 180, 220), material = Enum.Material.Fabric,    icon = "🏞️" },
	clock            = { name = "Wall Clock",       category = "WallArt",   price = 140,  size = Vector3.new(3, 3, 0.3), color = rgb(245, 245, 240), material = Enum.Material.SmoothPlastic, icon = "🕐" },
	paw_decal        = { name = "Paw Decal",        category = "WallArt",   price = 60,   size = Vector3.new(1.6, 1.6, 0.1), color = rgb(60, 40, 20), material = Enum.Material.SmoothPlastic, icon = "🐾" },

	-- ============ OUTDOOR ============
	garden_gnome     = { name = "Garden Gnome",     category = "Outdoor",   price = 180,  size = Vector3.new(1.5, 3, 1.5), color = rgb(220, 60, 60),   material = Enum.Material.SmoothPlastic, icon = "🧙" },
	flower_planter   = { name = "Flower Planter",   category = "Outdoor",   price = 90,   size = Vector3.new(3, 2.4, 3), color = rgb(160, 100, 60),  material = Enum.Material.Wood,      icon = "🌸" },
	picnic_table     = { name = "Picnic Table",     category = "Outdoor",   price = 320,  size = Vector3.new(8, 3, 4),   color = rgb(180, 130, 80),  material = Enum.Material.Wood,      icon = "🪑" },
	swing_set        = { name = "Swing Set",        category = "Outdoor",   price = 800,  size = Vector3.new(8, 7, 4),   color = rgb(200, 60, 60),   material = Enum.Material.Metal,     icon = "🛝" },
	bird_bath        = { name = "Bird Bath",        category = "Outdoor",   price = 180,  size = Vector3.new(3, 3.4, 3), color = rgb(220, 215, 200), material = Enum.Material.Marble,    icon = "🐦" },
	fence_picket     = { name = "Picket Fence",     category = "Outdoor",   price = 220,  size = Vector3.new(8, 4, 0.4), color = rgb(245, 245, 240), material = Enum.Material.Wood,      icon = "🪵" },
	mailbox_red      = { name = "Red Mailbox",      category = "Outdoor",   price = 140,  size = Vector3.new(1.4, 5, 1.4), color = rgb(220, 80, 80),   material = Enum.Material.SmoothPlastic, icon = "📮" },

	-- ============ THEMED ============
	dog_statue       = { name = "Dog Statue",       category = "Themed",    price = 700,  size = Vector3.new(2.5, 4, 2.5), color = rgb(180, 180, 180), material = Enum.Material.Marble,    icon = "🗿" },
	trophy_shelf     = { name = "Trophy Shelf",     category = "Themed",    price = 950,  size = Vector3.new(6, 3, 1.4), color = rgb(255, 220, 100), material = Enum.Material.Metal,     icon = "🏆" },
	paw_archway      = { name = "Paw Archway",      category = "Themed",    price = 1400, size = Vector3.new(8, 8, 1.6), color = rgb(240, 200, 80),  material = Enum.Material.Neon,      icon = "🎡" },
	moon_orb         = { name = "Moon Orb",         category = "Themed",    price = 3500, size = Vector3.new(4, 4, 4),   color = rgb(220, 230, 255), material = Enum.Material.Neon,      icon = "🌙", light = true },
}

return DecorCatalog
