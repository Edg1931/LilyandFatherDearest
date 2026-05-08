local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local WorldBuilder = {}

local CONTAINER_NAME = "PawprintWorld"

-- ============================================================ helpers
local function makePart(props)
	local p = Instance.new("Part")
	p.Anchored = props.anchored == nil and true or props.anchored
	p.CanCollide = props.collide ~= false
	p.CastShadow = props.shadow ~= false
	p.Material = props.material or Enum.Material.SmoothPlastic
	p.Size = props.size or Vector3.new(4, 4, 4)
	p.Color = props.color or Color3.fromRGB(220, 220, 220)
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if props.transparency then p.Transparency = props.transparency end
	if props.shape then p.Shape = props.shape end
	if props.cframe then p.CFrame = props.cframe
	elseif props.position then p.Position = props.position end
	if props.parent then p.Parent = props.parent end
	if props.name then p.Name = props.name end
	if props.reflectance then p.Reflectance = props.reflectance end
	return p
end

local function group(name, parent)
	local m = Instance.new("Folder")
	m.Name = name
	m.Parent = parent
	return m
end

local function colorJitter(c, range)
	local r = math.clamp(c.R + (math.random() - 0.5) * (range or 0.1), 0, 1)
	local g = math.clamp(c.G + (math.random() - 0.5) * (range or 0.1), 0, 1)
	local b = math.clamp(c.B + (math.random() - 0.5) * (range or 0.1), 0, 1)
	return Color3.new(r, g, b)
end

-- ============================================================ districts
WorldBuilder.DISTRICTS = {
	{ name = "Plaza",    x = 0,     z = 0,     w = 160, d = 160, color = Color3.fromRGB(204, 200, 178) },
	{ name = "Park",     x = 0,     z = -350,  w = 220, d = 220, color = Color3.fromRGB(120, 180, 90) },
	{ name = "Bakery",   x = 350,   z = -250,  w = 200, d = 200, color = Color3.fromRGB(216, 168, 110) },
	{ name = "Vet",      x = 350,   z = 200,   w = 200, d = 200, color = Color3.fromRGB(208, 224, 240) },
	{ name = "DogPark",  x = 200,   z = 450,   w = 240, d = 200, color = Color3.fromRGB(150, 200, 110) },
	{ name = "Beach",    x = -100,  z = 700,   w = 500, d = 220, color = Color3.fromRGB(245, 230, 180) },
	{ name = "Riverside",x = -100,  z = 350,   w = 360, d = 100, color = Color3.fromRGB(160, 200, 130) },
	{ name = "Downtown", x = 650,   z = 0,     w = 240, d = 320, color = Color3.fromRGB(180, 180, 200) },
	{ name = "Meadow",   x = -300,  z = 400,   w = 260, d = 260, color = Color3.fromRGB(150, 200, 110) },
	{ name = "MountainPass", x = -550, z = 0,  w = 200, d = 220, color = Color3.fromRGB(170, 170, 175) },
	{ name = "Home",     x = -1100, z = 0,     w = 280, d = 280, color = Color3.fromRGB(174, 200, 140) },
}

local DISTRICT_BY_NAME = {}
for _, d in ipairs(WorldBuilder.DISTRICTS) do DISTRICT_BY_NAME[d.name] = d end

function WorldBuilder.districtCenter(name)
	local d = DISTRICT_BY_NAME[name]
	return d and Vector3.new(d.x, 0, d.z) or Vector3.new(0, 0, 0)
end

-- ============================================================ decorations
local function tile(parent, x, z, w, d, color, material)
	makePart({ parent = parent,
		size = Vector3.new(w, 1, d),
		position = Vector3.new(x, 0.5, z),
		color = color,
		material = material or Enum.Material.Grass,
		shadow = false,
	})
end

local function tree(parent, x, z, scale)
	scale = scale or 1
	local trunkH = 8 * scale
	makePart({ parent = parent,
		size = Vector3.new(2 * scale, trunkH, 2 * scale),
		position = Vector3.new(x, trunkH / 2 + 1, z),
		color = Color3.fromRGB(110, 75, 45),
		material = Enum.Material.Wood,
	})
	for i = 1, 3 do
		local r = (4 + i) * scale
		makePart({ parent = parent,
			size = Vector3.new(r * 1.6, r, r * 1.6),
			position = Vector3.new(x + math.random(-1, 1), trunkH + r / 2 + (i - 1) * 2 + 1, z + math.random(-1, 1)),
			color = colorJitter(Color3.fromRGB(60, 130, 60), 0.15),
			material = Enum.Material.LeafyGrass,
			shape = Enum.PartType.Ball,
		})
	end
end

local function pineTree(parent, x, z, scale)
	scale = scale or 1
	local trunkH = 10 * scale
	makePart({ parent = parent,
		size = Vector3.new(1.6 * scale, trunkH, 1.6 * scale),
		position = Vector3.new(x, trunkH / 2 + 1, z),
		color = Color3.fromRGB(90, 60, 35),
		material = Enum.Material.Wood,
	})
	for i = 1, 4 do
		local r = (6 - i * 0.8) * scale
		makePart({ parent = parent,
			size = Vector3.new(r * 2.2, r * 0.8, r * 2.2),
			position = Vector3.new(x, trunkH + i * 2 * scale, z),
			color = colorJitter(Color3.fromRGB(40, 90, 50), 0.1),
			material = Enum.Material.LeafyGrass,
		})
	end
end

local function bush(parent, x, z, scale)
	scale = scale or 1
	makePart({ parent = parent,
		size = Vector3.new(4, 3, 4) * scale,
		position = Vector3.new(x, 1.5 * scale + 0.5, z),
		color = colorJitter(Color3.fromRGB(70, 140, 70), 0.12),
		material = Enum.Material.LeafyGrass,
		shape = Enum.PartType.Ball,
	})
end

local function flowerPatch(parent, x, z)
	for _ = 1, 6 do
		local fx = x + math.random(-3, 3)
		local fz = z + math.random(-3, 3)
		makePart({ parent = parent,
			size = Vector3.new(0.6, 0.6, 0.6),
			position = Vector3.new(fx, 1.4, fz),
			color = ({
				Color3.fromRGB(255, 100, 130),
				Color3.fromRGB(255, 200, 100),
				Color3.fromRGB(170, 130, 255),
				Color3.fromRGB(255, 255, 130),
			})[math.random(1, 4)],
			material = Enum.Material.Neon,
			shape = Enum.PartType.Ball,
			shadow = false,
		})
	end
end

local function lamppost(parent, x, z)
	makePart({ parent = parent,
		size = Vector3.new(0.6, 14, 0.6),
		position = Vector3.new(x, 8, z),
		color = Color3.fromRGB(60, 60, 70),
		material = Enum.Material.Metal,
	})
	local bulb = makePart({ parent = parent,
		size = Vector3.new(2, 2, 2),
		position = Vector3.new(x, 15, z),
		color = Color3.fromRGB(255, 240, 180),
		material = Enum.Material.Neon,
		shape = Enum.PartType.Ball,
		name = "LampBulb",
	})
	local light = Instance.new("PointLight")
	light.Brightness = 1.4
	light.Range = 24
	light.Color = Color3.fromRGB(255, 230, 170)
	light.Enabled = false  -- TimeService toggles at night
	light.Parent = bulb
	return bulb
end

local function bench(parent, x, z, rotateY)
	rotateY = rotateY or 0
	local cf = CFrame.new(x, 2, z) * CFrame.Angles(0, math.rad(rotateY), 0)
	makePart({ parent = parent,
		size = Vector3.new(8, 0.6, 2),
		cframe = cf,
		color = Color3.fromRGB(150, 100, 60),
		material = Enum.Material.Wood,
	})
	makePart({ parent = parent,
		size = Vector3.new(8, 3, 0.5),
		cframe = cf * CFrame.new(0, 1.5, -1),
		color = Color3.fromRGB(150, 100, 60),
		material = Enum.Material.Wood,
	})
	for _, dx in ipairs({ -3.5, 3.5 }) do
		makePart({ parent = parent,
			size = Vector3.new(0.5, 1.5, 2),
			cframe = cf * CFrame.new(dx, -1, 0),
			color = Color3.fromRGB(80, 60, 40),
			material = Enum.Material.Wood,
		})
	end
end

local function fireHydrant(parent, x, z)
	makePart({ parent = parent,
		size = Vector3.new(1.4, 2.4, 1.4),
		position = Vector3.new(x, 2.2, z),
		color = Color3.fromRGB(200, 50, 50),
		material = Enum.Material.SmoothPlastic,
	})
	makePart({ parent = parent,
		size = Vector3.new(1.6, 0.4, 1.6),
		position = Vector3.new(x, 3.6, z),
		color = Color3.fromRGB(200, 50, 50),
		material = Enum.Material.SmoothPlastic,
	})
end

local function fountain(parent, x, z)
	for i = 0, 3 do
		local angle = math.rad(i * 90 + 45)
		makePart({ parent = parent,
			size = Vector3.new(14, 2.5, 3),
			cframe = CFrame.new(x + math.cos(angle) * 7, 2.25, z + math.sin(angle) * 7) * CFrame.Angles(0, angle, 0),
			color = Color3.fromRGB(200, 195, 180),
			material = Enum.Material.Marble,
		})
	end
	makePart({ parent = parent,
		size = Vector3.new(13, 1, 13),
		position = Vector3.new(x, 2.5, z),
		color = Color3.fromRGB(80, 160, 220),
		material = Enum.Material.Water,
		transparency = 0.2,
		shadow = false,
	})
	makePart({ parent = parent,
		size = Vector3.new(2.4, 5, 2.4),
		position = Vector3.new(x, 5, z),
		color = Color3.fromRGB(220, 215, 200),
		material = Enum.Material.Marble,
	})
	local spout = makePart({ parent = parent,
		size = Vector3.new(1.2, 1.2, 1.2),
		position = Vector3.new(x, 8, z),
		color = Color3.fromRGB(200, 230, 255),
		material = Enum.Material.Neon,
		shape = Enum.PartType.Ball,
		shadow = false,
	})
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(Color3.fromRGB(180, 220, 255))
	emitter.Size = NumberSequence.new(0.6, 0.05)
	emitter.Lifetime = NumberRange.new(0.8, 1.4)
	emitter.Rate = 60
	emitter.Speed = NumberRange.new(10, 16)
	emitter.SpreadAngle = Vector2.new(20, 20)
	emitter.Acceleration = Vector3.new(0, -30, 0)
	emitter.Parent = spout
end

-- ============================================================ buildings (with optional interior)
-- Front of building faces +Z (so the door is at z + d/2).
-- Interior includes a hollow room with door cutout, an NPC podium and a vendor sign.
local function building(parent, opts)
	local g = group(opts.name or "Building", parent)
	local x, z = opts.x, opts.z
	local w, d, h = opts.w, opts.d, opts.h or 14
	local body = opts.bodyColor
	local accent = opts.accentColor
	local hasInterior = opts.hasInterior ~= false
	local doorWidth = math.min(w * 0.25, 6)

	-- Foundation
	makePart({ parent = g,
		size = Vector3.new(w + 2, 1, d + 2),
		position = Vector3.new(x, 0.5, z),
		color = Color3.fromRGB(140, 140, 145),
		material = Enum.Material.Concrete,
	})

	-- Floor (interior)
	makePart({ parent = g,
		size = Vector3.new(w - 0.4, 0.4, d - 0.4),
		position = Vector3.new(x, 1.2, z),
		color = Color3.fromRGB(180, 150, 110),
		material = Enum.Material.Wood,
	})

	-- Walls (back, left, right) - solid
	makePart({ parent = g,
		size = Vector3.new(w, h, 0.4),
		position = Vector3.new(x, h / 2 + 1, z - d / 2),
		color = body, material = Enum.Material.Brick,
	})
	makePart({ parent = g,
		size = Vector3.new(0.4, h, d),
		position = Vector3.new(x - w / 2, h / 2 + 1, z),
		color = body, material = Enum.Material.Brick,
	})
	makePart({ parent = g,
		size = Vector3.new(0.4, h, d),
		position = Vector3.new(x + w / 2, h / 2 + 1, z),
		color = body, material = Enum.Material.Brick,
	})

	-- Front wall: 3 segments around the door cutout
	local sideWidth = (w - doorWidth) / 2
	makePart({ parent = g,
		size = Vector3.new(sideWidth, h, 0.4),
		position = Vector3.new(x - (sideWidth + doorWidth) / 2, h / 2 + 1, z + d / 2),
		color = body, material = Enum.Material.Brick,
	})
	makePart({ parent = g,
		size = Vector3.new(sideWidth, h, 0.4),
		position = Vector3.new(x + (sideWidth + doorWidth) / 2, h / 2 + 1, z + d / 2),
		color = body, material = Enum.Material.Brick,
	})
	-- Lintel above door
	makePart({ parent = g,
		size = Vector3.new(doorWidth + 1, h - 7, 0.4),
		position = Vector3.new(x, h - (h - 7) / 2 + 1, z + d / 2),
		color = body, material = Enum.Material.Brick,
	})

	-- Roof
	makePart({ parent = g,
		size = Vector3.new(w + 2, 1.5, d + 2),
		position = Vector3.new(x, h + 1.5, z),
		color = accent,
		material = Enum.Material.Slate,
	})

	-- Door frame
	makePart({ parent = g,
		size = Vector3.new(doorWidth + 0.8, 7, 0.6),
		position = Vector3.new(x, 4.5, z + d / 2 + 0.1),
		color = Color3.fromRGB(80, 50, 30),
		material = Enum.Material.Wood,
	})
	-- Open door (recessed)
	makePart({ parent = g,
		size = Vector3.new(doorWidth, 6.5, 0.2),
		position = Vector3.new(x, 4.25, z + d / 2 - 0.4),
		color = Color3.fromRGB(40, 20, 10),
		material = Enum.Material.Wood,
		transparency = 0.6,
		collide = false,
	})

	-- Awning over door
	makePart({ parent = g,
		size = Vector3.new(w * 0.45, 0.5, 5),
		position = Vector3.new(x, 8.5, z + d / 2 + 2.5),
		color = accent,
		material = Enum.Material.SmoothPlastic,
	})

	-- Windows on front
	for _, sx in ipairs({ -1, 1 }) do
		makePart({ parent = g,
			size = Vector3.new(2.5, 3, 0.2),
			position = Vector3.new(x + sx * (sideWidth / 2 + doorWidth / 2 - 0.1), 7, z + d / 2),
			color = Color3.fromRGB(180, 220, 255),
			material = Enum.Material.Glass,
			transparency = 0.2,
		})
	end
	-- Windows on sides
	for _, side in ipairs({ -1, 1 }) do
		for i = -1, 1 do
			makePart({ parent = g,
				size = Vector3.new(0.2, 3, 2.5),
				position = Vector3.new(x + side * w / 2, 7, z + i * (d / 4)),
				color = Color3.fromRGB(180, 220, 255),
				material = Enum.Material.Glass,
				transparency = 0.2,
			})
		end
	end

	-- Sign above door
	if opts.sign then
		local sign = makePart({ parent = g,
			size = Vector3.new(doorWidth * 1.8, 1.4, 0.3),
			position = Vector3.new(x, 9.6, z + d / 2 + 0.4),
			color = Color3.fromRGB(40, 30, 25),
			material = Enum.Material.Wood,
		})
		local sgui = Instance.new("SurfaceGui")
		sgui.Face = Enum.NormalId.Front
		sgui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sgui.PixelsPerStud = 80
		sgui.Parent = sign
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamBold
		lbl.TextColor3 = Color3.fromRGB(255, 230, 130)
		lbl.TextScaled = true
		lbl.Text = opts.sign
		lbl.Parent = sgui
	end

	-- Interior decor + NPC anchor (NpcSpawner uses this location)
	if hasInterior then
		-- Counter
		makePart({ parent = g,
			size = Vector3.new(w * 0.6, 2.5, 1.5),
			position = Vector3.new(x, 2.6, z - d / 4),
			color = Color3.fromRGB(180, 130, 80),
			material = Enum.Material.Wood,
		})
		-- Interior light
		local interiorLight = makePart({ parent = g,
			size = Vector3.new(2, 0.4, 2),
			position = Vector3.new(x, h, z),
			color = Color3.fromRGB(255, 240, 200),
			material = Enum.Material.Neon,
			shadow = false,
		})
		local pl = Instance.new("PointLight")
		pl.Range = 20
		pl.Brightness = 1.0
		pl.Color = Color3.fromRGB(255, 240, 200)
		pl.Parent = interiorLight
	end

	return g, Vector3.new(x, 1.5, z - d / 4 - 2)  -- NPC stand position (behind counter)
end

local function skyscraper(parent, x, z, w, d, floors, color, name)
	local g = group(name or "Skyscraper", parent)
	local h = floors * 8
	makePart({ parent = g,
		size = Vector3.new(w + 2, 1, d + 2),
		position = Vector3.new(x, 0.5, z),
		color = Color3.fromRGB(110, 110, 120),
		material = Enum.Material.Concrete,
	})
	makePart({ parent = g,
		size = Vector3.new(w, h, d),
		position = Vector3.new(x, h / 2 + 1, z),
		color = color,
		material = Enum.Material.Concrete,
		reflectance = 0.05,
	})
	-- Window grid (just front face for clarity)
	for f = 1, floors do
		for i = -math.floor(w / 8), math.floor(w / 8) do
			if i ~= 0 then
				makePart({ parent = g,
					size = Vector3.new(2.5, 4, 0.2),
					position = Vector3.new(x + i * 5, 3 + (f - 1) * 8, z + d / 2 + 0.05),
					color = Color3.fromRGB(150, 200, 255),
					material = Enum.Material.Glass,
					transparency = 0.15,
				})
			end
		end
	end
	-- Roof beacon (red light)
	makePart({ parent = g,
		size = Vector3.new(2, 1.5, 2),
		position = Vector3.new(x, h + 1.8, z),
		color = Color3.fromRGB(255, 60, 60),
		material = Enum.Material.Neon,
		shape = Enum.PartType.Ball,
	})
	return g
end

local function house(parent, x, z, color, accentColor, name)
	local g = group(name or "House", parent)
	local w, d, h = 22, 18, 10
	-- Foundation
	makePart({ parent = g,
		size = Vector3.new(w + 1, 1, d + 1),
		position = Vector3.new(x, 0.5, z),
		color = Color3.fromRGB(160, 150, 140),
		material = Enum.Material.Concrete,
	})
	-- Walls (hollow)
	local doorW = 4
	-- Back, sides
	makePart({ parent = g, size = Vector3.new(w, h, 0.4), position = Vector3.new(x, h / 2 + 1, z - d / 2), color = color, material = Enum.Material.WoodPlanks })
	makePart({ parent = g, size = Vector3.new(0.4, h, d), position = Vector3.new(x - w / 2, h / 2 + 1, z), color = color, material = Enum.Material.WoodPlanks })
	makePart({ parent = g, size = Vector3.new(0.4, h, d), position = Vector3.new(x + w / 2, h / 2 + 1, z), color = color, material = Enum.Material.WoodPlanks })
	-- Front with door cut
	local sideW = (w - doorW) / 2
	makePart({ parent = g, size = Vector3.new(sideW, h, 0.4), position = Vector3.new(x - (sideW + doorW) / 2, h / 2 + 1, z + d / 2), color = color, material = Enum.Material.WoodPlanks })
	makePart({ parent = g, size = Vector3.new(sideW, h, 0.4), position = Vector3.new(x + (sideW + doorW) / 2, h / 2 + 1, z + d / 2), color = color, material = Enum.Material.WoodPlanks })
	makePart({ parent = g, size = Vector3.new(doorW + 0.5, h - 6, 0.4), position = Vector3.new(x, h - (h - 6) / 2 + 1, z + d / 2), color = color, material = Enum.Material.WoodPlanks })
	-- Floor
	makePart({ parent = g, size = Vector3.new(w - 0.4, 0.3, d - 0.4), position = Vector3.new(x, 1.15, z), color = Color3.fromRGB(150, 110, 70), material = Enum.Material.Wood })
	-- Pitched roof (two wedges via boxes)
	for i = 1, 4 do
		makePart({ parent = g,
			size = Vector3.new(w + 2, 1, d + 2 - (i - 1) * 4),
			position = Vector3.new(x, h + 1 + i * 1.2, z),
			color = accentColor,
			material = Enum.Material.Slate,
		})
	end
	-- Chimney
	makePart({ parent = g,
		size = Vector3.new(2, 4, 2),
		position = Vector3.new(x + w / 4, h + 4, z - d / 4),
		color = Color3.fromRGB(180, 80, 60),
		material = Enum.Material.Brick,
	})
	-- Mailbox out front
	makePart({ parent = g,
		size = Vector3.new(0.4, 4, 0.4),
		position = Vector3.new(x + w / 2 + 4, 3, z + d / 2 + 2),
		color = Color3.fromRGB(120, 80, 40),
		material = Enum.Material.Wood,
	})
	makePart({ parent = g,
		size = Vector3.new(2, 1.2, 1.2),
		position = Vector3.new(x + w / 2 + 4, 5.5, z + d / 2 + 2),
		color = Color3.fromRGB(220, 80, 80),
		material = Enum.Material.SmoothPlastic,
	})
	return g, Vector3.new(x, 1.5, z)
end

-- ============================================================ special features
local function river(parent, x, z, length, width)
	makePart({ parent = parent,
		size = Vector3.new(length, 1.4, width),
		position = Vector3.new(x, 0, z),
		color = Color3.fromRGB(60, 130, 200),
		material = Enum.Material.Water,
		transparency = 0.25,
		shadow = false,
	})
	for _, dz in ipairs({ -width / 2 - 2, width / 2 + 2 }) do
		makePart({ parent = parent,
			size = Vector3.new(length, 2, 4),
			position = Vector3.new(x, 0.8, z + dz),
			color = Color3.fromRGB(150, 130, 100),
			material = Enum.Material.Sand,
			shadow = false,
		})
	end
end

local function ocean(parent, x, z, w, d)
	makePart({ parent = parent,
		size = Vector3.new(w, 2, d),
		position = Vector3.new(x, -0.2, z),
		color = Color3.fromRGB(45, 110, 180),
		material = Enum.Material.Water,
		transparency = 0.3,
		shadow = false,
	})
end

local function beachSand(parent, x, z, w, d)
	makePart({ parent = parent,
		size = Vector3.new(w, 1, d),
		position = Vector3.new(x, 0.55, z),
		color = Color3.fromRGB(245, 230, 180),
		material = Enum.Material.Sand,
		shadow = false,
	})
end

local function bridge(parent, x, z)
	local g = group("Bridge", parent)
	makePart({ parent = g,
		size = Vector3.new(24, 1, 8),
		position = Vector3.new(x, 4, z),
		color = Color3.fromRGB(170, 120, 70),
		material = Enum.Material.Wood,
	})
	for _, dz in ipairs({ -3.5, 3.5 }) do
		makePart({ parent = g,
			size = Vector3.new(24, 1.5, 0.4),
			position = Vector3.new(x, 5.5, z + dz),
			color = Color3.fromRGB(140, 95, 55),
			material = Enum.Material.Wood,
		})
		for i = -2, 2 do
			makePart({ parent = g,
				size = Vector3.new(0.4, 2, 0.4),
				position = Vector3.new(x + i * 5, 5, z + dz),
				color = Color3.fromRGB(140, 95, 55),
				material = Enum.Material.Wood,
			})
		end
	end
	for _, dx in ipairs({ -10, 10 }) do
		makePart({ parent = g,
			size = Vector3.new(2, 8, 2),
			position = Vector3.new(x + dx, 0, z),
			color = Color3.fromRGB(120, 90, 60),
			material = Enum.Material.Wood,
		})
	end
end

local function mountainPeak(parent, x, z, height)
	for i = 1, 5 do
		local s = (1 - (i - 1) / 5) * 1.0
		local size = (60 - i * 10) * s
		makePart({ parent = parent,
			size = Vector3.new(size, height * 0.25, size),
			position = Vector3.new(x, height * 0.125 + (i - 1) * height * 0.18, z),
			color = colorJitter(Color3.fromRGB(150, 150, 155), 0.05),
			material = Enum.Material.Slate,
		})
	end
	-- Snow cap
	makePart({ parent = parent,
		size = Vector3.new(14, 6, 14),
		position = Vector3.new(x, height + 2, z),
		color = Color3.fromRGB(245, 245, 250),
		material = Enum.Material.Snow,
	})
end

local function caveTunnel(parent, x, z, length)
	local g = group("Cave", parent)
	-- Outer mass
	makePart({ parent = g,
		size = Vector3.new(length + 20, 50, 80),
		position = Vector3.new(x, 25, z),
		color = Color3.fromRGB(95, 90, 90),
		material = Enum.Material.Slate,
	})
	-- Hollow tunnel — carve out using darker non-collidable parts? Simplest: stack walls/ceiling/floor open at both ends.
	-- We'll build the tunnel as floor + 2 walls + ceiling, leaving the +Z and -Z ends open.
	-- But the outer mass is solid, so we layer the tunnel inside on top of it. To keep it simple, we'll make the outer mass smaller and the tunnel separate.
	-- Replace outer mass: just do peaks around the tunnel.
	g:ClearAllChildren()
	-- Tunnel floor
	makePart({ parent = g,
		size = Vector3.new(length, 1, 16),
		position = Vector3.new(x, 0.5, z),
		color = Color3.fromRGB(80, 75, 75),
		material = Enum.Material.Slate,
	})
	-- Tunnel walls
	for _, dz in ipairs({ -8, 8 }) do
		makePart({ parent = g,
			size = Vector3.new(length, 16, 1),
			position = Vector3.new(x, 8, z + dz),
			color = Color3.fromRGB(100, 95, 90),
			material = Enum.Material.Slate,
		})
	end
	-- Ceiling
	makePart({ parent = g,
		size = Vector3.new(length, 1, 16),
		position = Vector3.new(x, 16, z),
		color = Color3.fromRGB(70, 65, 65),
		material = Enum.Material.Slate,
	})
	-- Glowing crystals along the tunnel
	for i = -length / 2 + 30, length / 2 - 30, 30 do
		local crystalColor = ({
			Color3.fromRGB(160, 200, 255),
			Color3.fromRGB(200, 160, 255),
			Color3.fromRGB(160, 255, 220),
			Color3.fromRGB(255, 200, 220),
		})[math.random(1, 4)]
		local crystal = makePart({ parent = g,
			size = Vector3.new(1.2, 3.5, 1.2),
			cframe = CFrame.new(x + i, 12, z + math.random(-6, 6)) * CFrame.Angles(math.rad(math.random(-15, 15)), 0, 0),
			color = crystalColor,
			material = Enum.Material.Neon,
			shape = Enum.PartType.Block,
		})
		local pl = Instance.new("PointLight")
		pl.Color = crystalColor
		pl.Range = 18
		pl.Brightness = 1.4
		pl.Parent = crystal
	end
	-- Stalactites
	for i = -length / 2, length / 2, 12 do
		makePart({ parent = g,
			size = Vector3.new(1, 2.5, 1),
			position = Vector3.new(x + i + math.random(-3, 3), 14, z + math.random(-5, 5)),
			color = Color3.fromRGB(60, 55, 55),
			material = Enum.Material.Slate,
		})
	end
end

local function pier(parent, x, z, length)
	local g = group("Pier", parent)
	makePart({ parent = g,
		size = Vector3.new(8, 1, length),
		position = Vector3.new(x, 2, z),
		color = Color3.fromRGB(170, 120, 70),
		material = Enum.Material.Wood,
	})
	for i = -length / 2, length / 2, 6 do
		for _, dx in ipairs({ -3.5, 3.5 }) do
			makePart({ parent = g,
				size = Vector3.new(0.6, 5, 0.6),
				position = Vector3.new(x + dx, 0, z + i),
				color = Color3.fromRGB(120, 80, 50),
				material = Enum.Material.Wood,
			})
		end
	end
end

local function lifeguardTower(parent, x, z)
	local g = group("Lifeguard", parent)
	-- Stilts
	for _, dx in ipairs({ -4, 4 }) do
		for _, dz in ipairs({ -4, 4 }) do
			makePart({ parent = g,
				size = Vector3.new(0.8, 14, 0.8),
				position = Vector3.new(x + dx, 7, z + dz),
				color = Color3.fromRGB(130, 90, 50),
				material = Enum.Material.Wood,
			})
		end
	end
	-- Platform
	makePart({ parent = g,
		size = Vector3.new(10, 0.6, 10),
		position = Vector3.new(x, 13.5, z),
		color = Color3.fromRGB(220, 180, 130),
		material = Enum.Material.Wood,
	})
	-- Booth walls
	makePart({ parent = g, size = Vector3.new(10, 6, 0.4), position = Vector3.new(x, 16.8, z - 5), color = Color3.fromRGB(220, 60, 60), material = Enum.Material.SmoothPlastic })
	makePart({ parent = g, size = Vector3.new(0.4, 6, 10), position = Vector3.new(x - 5, 16.8, z), color = Color3.fromRGB(220, 60, 60), material = Enum.Material.SmoothPlastic })
	makePart({ parent = g, size = Vector3.new(0.4, 6, 10), position = Vector3.new(x + 5, 16.8, z), color = Color3.fromRGB(220, 60, 60), material = Enum.Material.SmoothPlastic })
	-- Roof
	makePart({ parent = g, size = Vector3.new(11, 0.8, 11), position = Vector3.new(x, 20, z), color = Color3.fromRGB(200, 50, 50), material = Enum.Material.SmoothPlastic })
end

local function beachUmbrella(parent, x, z, color)
	makePart({ parent = parent, size = Vector3.new(0.4, 6, 0.4), position = Vector3.new(x, 3, z), color = Color3.fromRGB(120, 80, 50), material = Enum.Material.Wood })
	for i = 0, 5 do
		local angle = math.rad(i * 60)
		makePart({ parent = parent,
			size = Vector3.new(5, 0.3, 5),
			cframe = CFrame.new(x + math.cos(angle) * 0.3, 6, z + math.sin(angle) * 0.3) * CFrame.Angles(0, angle, math.rad(-12)),
			color = color,
			material = Enum.Material.Fabric,
		})
	end
end

-- Agility course primitives
local function agilityJump(parent, x, z)
	local g = group("AgilityJump", parent)
	for _, dx in ipairs({ -3, 3 }) do
		makePart({ parent = g,
			size = Vector3.new(0.5, 5, 0.5),
			position = Vector3.new(x + dx, 2.5, z),
			color = Color3.fromRGB(220, 220, 220),
			material = Enum.Material.SmoothPlastic,
		})
	end
	makePart({ parent = g,
		size = Vector3.new(7, 0.4, 0.4),
		position = Vector3.new(x, 4.5, z),
		color = Color3.fromRGB(220, 80, 80),
		material = Enum.Material.SmoothPlastic,
	})
end

local function weavePoles(parent, x, z, count)
	local g = group("WeavePoles", parent)
	for i = 0, count - 1 do
		makePart({ parent = g,
			size = Vector3.new(0.4, 5, 0.4),
			position = Vector3.new(x + (i - count / 2) * 2, 2.5, z),
			color = Color3.fromRGB(80, 130, 220),
			material = Enum.Material.SmoothPlastic,
		})
	end
end

local function agilityTunnel(parent, x, z)
	local g = group("AgilityTunnel", parent)
	for i = -4, 4 do
		makePart({ parent = g,
			size = Vector3.new(0.5, 6, 6),
			cframe = CFrame.new(x + i * 1.5, 3, z) * CFrame.Angles(0, math.rad(90), 0),
			color = Color3.fromRGB(220, 100, 60),
			material = Enum.Material.Fabric,
		})
	end
end

-- ============================================================ roads
local function asphaltStrip(parent, x1, z1, x2, z2, width)
	local dx, dz = x2 - x1, z2 - z1
	local len = math.sqrt(dx * dx + dz * dz)
	local angle = math.atan2(dx, dz)
	local cf = CFrame.new((x1 + x2) / 2, 0.6, (z1 + z2) / 2) * CFrame.Angles(0, angle, 0)
	makePart({ parent = parent,
		size = Vector3.new(width, 0.4, len),
		cframe = cf,
		color = Color3.fromRGB(70, 70, 75),
		material = Enum.Material.Asphalt,
		shadow = false,
	})
	-- Center stripes
	local stripes = math.floor(len / 8)
	for i = 1, stripes do
		local off = (i - (stripes + 1) / 2) * 8
		makePart({ parent = parent,
			cframe = cf * CFrame.new(0, 0.2, off),
			size = Vector3.new(0.4, 0.45, 4),
			color = Color3.fromRGB(255, 230, 100),
			material = Enum.Material.SmoothPlastic,
			shadow = false,
		})
	end
	-- Sidewalks
	makePart({ parent = parent,
		cframe = cf * CFrame.new(width / 2 + 2, -0.05, 0),
		size = Vector3.new(4, 0.6, len),
		color = Color3.fromRGB(190, 190, 195),
		material = Enum.Material.Concrete,
		shadow = false,
	})
	makePart({ parent = parent,
		cframe = cf * CFrame.new(-(width / 2 + 2), -0.05, 0),
		size = Vector3.new(4, 0.6, len),
		color = Color3.fromRGB(190, 190, 195),
		material = Enum.Material.Concrete,
		shadow = false,
	})
end

local function crosswalk(parent, x, z, vertical)
	for i = -2, 2 do
		local size = vertical and Vector3.new(1.2, 0.5, 8) or Vector3.new(8, 0.5, 1.2)
		makePart({ parent = parent,
			size = size,
			position = Vector3.new(x + (vertical and i * 1.6 or 0), 0.7, z + (vertical and 0 or i * 1.6)),
			color = Color3.fromRGB(245, 245, 245),
			material = Enum.Material.SmoothPlastic,
			shadow = false,
		})
	end
end

local function spawnPad(parent, x, z)
	local s = Instance.new("SpawnLocation")
	s.Anchored = true
	s.Size = Vector3.new(10, 1, 10)
	s.Position = Vector3.new(x, 1.5, z)
	s.Color = Color3.fromRGB(255, 220, 100)
	s.Material = Enum.Material.Neon
	s.Transparency = 0.25
	s.TopSurface = Enum.SurfaceType.Smooth
	s.BottomSurface = Enum.SurfaceType.Smooth
	s.Name = "PlazaSpawn"
	s.Neutral = true
	s.Parent = parent
end

-- ============================================================ district builders
WorldBuilder._npcAnchors = {}  -- name → Vector3 (interior NPC stand spots)

local function buildPlaza(c)
	fountain(c, 0, 0)
	for ang = 0, 270, 90 do
		local rad = math.rad(ang)
		bench(c, math.cos(rad) * 22, math.sin(rad) * 22, ang)
	end
	for ang = 30, 330, 60 do
		local rad = math.rad(ang)
		lamppost(c, math.cos(rad) * 38, math.sin(rad) * 38)
	end
	-- Welcome sign
	makePart({ parent = c, size = Vector3.new(10, 0.6, 0.4), position = Vector3.new(40, 6, 0), color = Color3.fromRGB(60, 40, 25), material = Enum.Material.Wood })
	makePart({ parent = c, size = Vector3.new(0.5, 6, 0.5), position = Vector3.new(35, 3, 0), color = Color3.fromRGB(80, 50, 30), material = Enum.Material.Wood })
	makePart({ parent = c, size = Vector3.new(0.5, 6, 0.5), position = Vector3.new(45, 3, 0), color = Color3.fromRGB(80, 50, 30), material = Enum.Material.Wood })
	spawnPad(c, 24, 24)
end

local function buildPark(c)
	for i = 1, 26 do
		tree(c,
			-90 + math.random(0, 180),
			-440 + math.random(0, 180),
			0.8 + math.random() * 0.6
		)
	end
	for _ = 1, 10 do
		flowerPatch(c, math.random(-90, 90), -400 + math.random(-40, 40))
	end
	bench(c, -25, -300, 0)
	bench(c, 25, -300, 180)
	lamppost(c, -50, -260)
	lamppost(c, 50, -260)
	-- Pond
	makePart({ parent = c,
		size = Vector3.new(50, 1.4, 36),
		position = Vector3.new(40, 0.6, -380),
		color = Color3.fromRGB(80, 160, 220),
		material = Enum.Material.Water,
		transparency = 0.2,
		shadow = false,
	})
	-- Dock at pond
	makePart({ parent = c, size = Vector3.new(8, 1, 6), position = Vector3.new(8, 1.6, -380), color = Color3.fromRGB(160, 110, 70), material = Enum.Material.Wood })
end

local function buildBakery(c)
	local _, mae = building(c, { x = 320, z = -270, w = 30, d = 22, h = 14, bodyColor = Color3.fromRGB(220, 170, 120), accentColor = Color3.fromRGB(180, 70, 60),  name = "Bakery", sign = "BAKERY" })
	WorldBuilder._npcAnchors.bakery_interior = mae
	local _, cafeNpc = building(c, { x = 380, z = -290, w = 26, d = 20, h = 12, bodyColor = Color3.fromRGB(230, 200, 150), accentColor = Color3.fromRGB(120, 80, 40),  name = "Cafe", sign = "CAFE" })
	WorldBuilder._npcAnchors.cafe_interior = cafeNpc
	local _, treats = building(c, { x = 350, z = -200, w = 24, d = 18, h = 12, bodyColor = Color3.fromRGB(240, 210, 170), accentColor = Color3.fromRGB(80, 130, 90),  name = "PetTreats", sign = "PET TREATS" })
	WorldBuilder._npcAnchors.treats_interior = treats
	for _ = 1, 6 do flowerPatch(c, 290 + math.random(0, 100), -190 + math.random(-30, 30)) end
	-- Outdoor table
	makePart({ parent = c, size = Vector3.new(4, 0.4, 4), position = Vector3.new(310, 3, -210), color = Color3.fromRGB(200, 150, 100), material = Enum.Material.Wood })
	makePart({ parent = c, size = Vector3.new(0.6, 3, 0.6), position = Vector3.new(310, 1.5, -210), color = Color3.fromRGB(80, 50, 30), material = Enum.Material.Wood })
end

local function buildVet(c)
	local _, vet = building(c, { x = 350, z = 220, w = 36, d = 28, h = 16, bodyColor = Color3.fromRGB(220, 240, 250), accentColor = Color3.fromRGB(80, 130, 200),  name = "VetHospital", sign = "VET HOSPITAL" })
	WorldBuilder._npcAnchors.vet_interior = vet
	local _, shelter = building(c, { x = 290, z = 170, w = 22, d = 18, h = 12, bodyColor = Color3.fromRGB(240, 240, 240), accentColor = Color3.fromRGB(160, 60, 60),   name = "Shelter", sign = "SHELTER" })
	WorldBuilder._npcAnchors.shelter_interior = shelter
	-- Ambulance
	local amb = makePart({ parent = c, size = Vector3.new(8, 4, 14), position = Vector3.new(395, 3, 250), color = Color3.fromRGB(245, 245, 245), material = Enum.Material.SmoothPlastic })
	makePart({ parent = c, size = Vector3.new(8, 0.3, 14), position = Vector3.new(395, 5.2, 250), color = Color3.fromRGB(220, 60, 60), material = Enum.Material.SmoothPlastic })
	for _, sx in ipairs({ -3, 3 }) do
		for _, sz in ipairs({ -5, 5 }) do
			makePart({ parent = c, size = Vector3.new(2, 2, 2), position = Vector3.new(395 + sx, 1, 250 + sz), color = Color3.fromRGB(40, 40, 40), shape = Enum.PartType.Cylinder, material = Enum.Material.SmoothPlastic })
		end
	end
end

local function buildDogPark(c)
	-- Fenced perimeter
	for x = 100, 300, 8 do
		for _, dz in ipairs({ 380, 530 }) do
			makePart({ parent = c, size = Vector3.new(0.4, 4, 0.4), position = Vector3.new(x, 2, dz), color = Color3.fromRGB(160, 110, 70), material = Enum.Material.Wood })
		end
	end
	for z = 380, 530, 8 do
		for _, dx in ipairs({ 100, 300 }) do
			makePart({ parent = c, size = Vector3.new(0.4, 4, 0.4), position = Vector3.new(dx, 2, z), color = Color3.fromRGB(160, 110, 70), material = Enum.Material.Wood })
		end
	end
	-- Agility course down the middle
	agilityJump(c, 200, 410)
	agilityJump(c, 200, 430)
	weavePoles(c, 200, 460, 6)
	agilityTunnel(c, 200, 500)
	-- Hydrant + drinking fountain
	fireHydrant(c, 130, 400)
	fireHydrant(c, 270, 510)
	-- Tree corners
	tree(c, 130, 530, 1.2)
	tree(c, 270, 380, 1.2)
end

local function buildBeach(c)
	-- Sand area
	beachSand(c, -100, 700, 500, 220)
	-- Ocean further south (huge)
	ocean(c, -100, 1000, 1500, 600)
	-- Pier extending into ocean
	pier(c, -150, 880, 200)
	lifeguardTower(c, -250, 700)
	-- Umbrellas
	for i = 1, 8 do
		beachUmbrella(c,
			-300 + i * 60 + math.random(-10, 10),
			700 + math.random(-30, 30),
			({ Color3.fromRGB(255, 100, 130), Color3.fromRGB(255, 200, 100), Color3.fromRGB(80, 180, 220), Color3.fromRGB(180, 120, 220) })[math.random(1, 4)]
		)
	end
	-- Palm-like trees (simplified)
	for _ = 1, 6 do
		local x = -300 + math.random(0, 600)
		local z = 600 + math.random(-30, 30)
		makePart({ parent = c, size = Vector3.new(1, 14, 1), position = Vector3.new(x, 8, z), color = Color3.fromRGB(120, 80, 50), material = Enum.Material.Wood })
		for i = 0, 4 do
			local angle = math.rad(i * 72)
			makePart({ parent = c,
				size = Vector3.new(7, 0.6, 1.5),
				cframe = CFrame.new(x + math.cos(angle) * 3, 15, z + math.sin(angle) * 3) * CFrame.Angles(math.rad(-15), angle, 0),
				color = Color3.fromRGB(60, 140, 70),
				material = Enum.Material.LeafyGrass,
			})
		end
	end
end

local function buildRiverside(c)
	-- River runs east-west (long X axis)
	river(c, -100, 350, 500, 30)
	-- Bridge crossing
	bridge(c, 0, 350)
	-- Rocks along bank
	for _ = 1, 10 do
		makePart({ parent = c,
			size = Vector3.new(2 + math.random() * 2, 1.5, 2 + math.random() * 2),
			position = Vector3.new(math.random(-300, 100), 1.4, 320 + math.random(0, 60)),
			color = Color3.fromRGB(140, 130, 120),
			material = Enum.Material.Slate,
			shape = Enum.PartType.Ball,
		})
	end
end

local function buildDowntown(c)
	skyscraper(c, 600, -50, 36, 36, 8, Color3.fromRGB(200, 210, 220), "Tower A")
	skyscraper(c, 700, 50, 30, 30, 6, Color3.fromRGB(180, 180, 200), "Tower B")
	skyscraper(c, 580, 100, 32, 32, 7, Color3.fromRGB(220, 200, 180), "Tower C")
	skyscraper(c, 720, -80, 28, 28, 5, Color3.fromRGB(170, 200, 220), "Tower D")
	-- Mid-rise office (interior)
	local _, off = building(c, { x = 640, z = 160, w = 32, d = 24, h = 18, bodyColor = Color3.fromRGB(150, 170, 200), accentColor = Color3.fromRGB(60, 80, 120), name = "Office", sign = "OFFICE" })
	WorldBuilder._npcAnchors.office_interior = off
	-- Streets at intersections
	for _, p in ipairs({ Vector3.new(620, 0, 0), Vector3.new(660, 0, 80) }) do
		crosswalk(c, p.X, p.Z, false)
	end
end

local function buildMeadow(c)
	for i = 1, 30 do
		flowerPatch(c, -400 + math.random(0, 200), 320 + math.random(0, 160))
	end
	for i = 1, 8 do
		bush(c, -380 + math.random(0, 160), 340 + math.random(0, 130), 1.2)
	end
	tree(c, -380, 320, 1.4)
	tree(c, -240, 480, 1.4)
end

local function buildMountainPass(c)
	-- A ring of mountain peaks framing a road that runs into the cave.
	mountainPeak(c, -500, -120, 80)
	mountainPeak(c, -560, -60, 100)
	mountainPeak(c, -620, 40, 90)
	mountainPeak(c, -560, 130, 75)
	mountainPeak(c, -500, 200, 85)
	mountainPeak(c, -460, 90, 70)
	-- Pine trees lining the pass
	for i = 1, 14 do
		pineTree(c, -480 + math.random(-30, 30), -100 + i * 25, 0.9 + math.random() * 0.4)
	end
end

local function buildCave(c)
	caveTunnel(c, -800, 0, 220)
	-- Cave entrance: a stone arch on the city side
	for ang = 0, 180, 18 do
		local rad = math.rad(ang)
		makePart({ parent = c,
			size = Vector3.new(3, 4, 3),
			position = Vector3.new(-700 + math.cos(rad) * 12, 4 + math.sin(rad) * 8, math.cos(rad - math.pi/2) * 0),
			color = Color3.fromRGB(110, 100, 90),
			material = Enum.Material.Slate,
		})
	end
	-- A small treasure chest at the midpoint (decorative)
	makePart({ parent = c, size = Vector3.new(2, 1.6, 1.2), position = Vector3.new(-790, 1.8, 5), color = Color3.fromRGB(120, 80, 40), material = Enum.Material.Wood })
	makePart({ parent = c, size = Vector3.new(2.1, 0.4, 1.3), position = Vector3.new(-790, 2.6, 5), color = Color3.fromRGB(255, 200, 100), material = Enum.Material.Metal, shadow = false })
end

local function buildHomeDistrict(c)
	-- Your house in the middle
	local _, anchor = house(c, -1100, 0, Color3.fromRGB(245, 220, 180), Color3.fromRGB(170, 90, 60), "Your House")
	WorldBuilder._npcAnchors.home = anchor
	-- Neighbours
	house(c, -1180, -60, Color3.fromRGB(220, 200, 240), Color3.fromRGB(120, 100, 160), "Neighbour A")
	house(c, -1020, 80, Color3.fromRGB(200, 230, 200), Color3.fromRGB(80, 140, 100), "Neighbour B")
	house(c, -1160, 90, Color3.fromRGB(240, 240, 200), Color3.fromRGB(180, 120, 60), "Neighbour C")
	house(c, -1040, -80, Color3.fromRGB(200, 220, 240), Color3.fromRGB(60, 100, 160), "Neighbour D")
	-- Garden
	for x = -1140, -1060, 12 do
		for z = -100, 100, 25 do
			tree(c, x, z, 0.7)
		end
	end
end

-- ============================================================ build!
function WorldBuilder.build()
	local existing = Workspace:FindFirstChild(CONTAINER_NAME)
	if existing then existing:Destroy() end
	for _, name in ipairs({ "Baseplate", "SpawnLocation" }) do
		local d = Workspace:FindFirstChild(name)
		if d then d:Destroy() end
	end
	local container = Instance.new("Folder")
	container.Name = CONTAINER_NAME
	container.Parent = Workspace

	-- Big ground plane
	makePart({ parent = container,
		size = Vector3.new(2800, 1, 2400),
		position = Vector3.new(-200, 0, 200),
		color = Color3.fromRGB(126, 180, 100),
		material = Enum.Material.Grass,
		shadow = false,
		name = "Ground",
	})

	-- District tiles
	for _, d in ipairs(WorldBuilder.DISTRICTS) do
		tile(container, d.x, d.z, d.w, d.d, d.color)
	end

	-- Roads radiating from plaza (with sidewalks)
	asphaltStrip(container, 0, -80, 0, -240, 14)        -- → Park
	asphaltStrip(container, 0, 80, -50, 270, 14)         -- → Riverside
	asphaltStrip(container, 80, 0, 220, -80, 14)         -- → Bakery
	asphaltStrip(container, 80, 80, 220, 200, 14)        -- → Vet
	asphaltStrip(container, 220, 200, 200, 350, 14)      -- → Dog Park
	asphaltStrip(container, 220, -80, 600, 0, 14)        -- → Downtown
	asphaltStrip(container, -50, 270, -100, 600, 14)     -- → Beach
	asphaltStrip(container, -80, 0, -460, 0, 14)         -- → Mountain Pass
	asphaltStrip(container, -460, 0, -700, 0, 14)        -- → Cave entrance
	asphaltStrip(container, -900, 0, -1080, 0, 14)        -- → Home district

	-- Crosswalks at plaza intersections
	crosswalk(container, 80, 0, false)
	crosswalk(container, -80, 0, false)
	crosswalk(container, 0, 80, true)
	crosswalk(container, 0, -80, true)

	buildPlaza(container)
	buildPark(container)
	buildBakery(container)
	buildVet(container)
	buildDogPark(container)
	buildBeach(container)
	buildRiverside(container)
	buildDowntown(container)
	buildMeadow(container)
	buildMountainPass(container)
	buildCave(container)
	buildHomeDistrict(container)

	-- Atmosphere / lighting -------------------------------------------------
	Lighting.ClockTime = 14
	Lighting.Brightness = 2
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 160, 170)
	Lighting.Ambient = Color3.fromRGB(70, 70, 90)
	Lighting.GlobalShadows = true
	Lighting.FogStart = 400
	Lighting.FogEnd = 2000
	Lighting.FogColor = Color3.fromRGB(180, 200, 220)

	local atm = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atm.Density = 0.35
	atm.Offset = 0.1
	atm.Color = Color3.fromRGB(199, 215, 230)
	atm.Decay = Color3.fromRGB(106, 112, 125)
	atm.Glare = 0.2
	atm.Haze = 1.6
	atm.Parent = Lighting

	local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky")
	sky.SkyboxBk = "rbxasset://textures/sky/sky512_bk.tex"
	sky.SkyboxDn = "rbxasset://textures/sky/sky512_dn.tex"
	sky.SkyboxFt = "rbxasset://textures/sky/sky512_ft.tex"
	sky.SkyboxLf = "rbxasset://textures/sky/sky512_lf.tex"
	sky.SkyboxRt = "rbxasset://textures/sky/sky512_rt.tex"
	sky.SkyboxUp = "rbxasset://textures/sky/sky512_up.tex"
	sky.Parent = Lighting

	return container
end

return WorldBuilder
