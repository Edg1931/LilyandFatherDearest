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

-- ============================================================ districts (compressed ~55% from previous wave)
WorldBuilder.DISTRICTS = {
	{ name = "Plaza",        x = 0,    z = 0,    w = 130, d = 130, color = Color3.fromRGB(204, 200, 178) },
	{ name = "Park",         x = 0,    z = -200, w = 180, d = 180, color = Color3.fromRGB(120, 180, 90) },
	{ name = "Bakery",       x = 200,  z = -140, w = 170, d = 170, color = Color3.fromRGB(216, 168, 110) },
	{ name = "Vet",          x = 200,  z = 120,  w = 170, d = 170, color = Color3.fromRGB(208, 224, 240) },
	{ name = "DogPark",      x = 120,  z = 250,  w = 180, d = 150, color = Color3.fromRGB(150, 200, 110) },
	{ name = "Beach",        x = -60,  z = 390,  w = 360, d = 180, color = Color3.fromRGB(245, 230, 180) },
	{ name = "Riverside",    x = -60,  z = 200,  w = 260, d = 80,  color = Color3.fromRGB(160, 200, 130) },
	{ name = "Downtown",     x = 360,  z = 0,    w = 200, d = 240, color = Color3.fromRGB(180, 180, 200) },
	{ name = "Meadow",       x = -180, z = 230,  w = 200, d = 200, color = Color3.fromRGB(150, 200, 110) },
	{ name = "MountainPass", x = -310, z = 0,    w = 160, d = 180, color = Color3.fromRGB(170, 170, 175) },
	{ name = "Home",         x = -610, z = 0,    w = 220, d = 220, color = Color3.fromRGB(174, 200, 140) },
}

local DISTRICT_BY_NAME = {}
for _, d in ipairs(WorldBuilder.DISTRICTS) do DISTRICT_BY_NAME[d.name] = d end

function WorldBuilder.districtCenter(name)
	local d = DISTRICT_BY_NAME[name]
	return d and Vector3.new(d.x, 0, d.z) or Vector3.new(0, 0, 0)
end

-- ============================================================ small props
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

local function butterflies(parent, x, z, count)
	-- Decorative particle emitter on an invisible host. Birds/butterflies feel.
	local host = makePart({ parent = parent,
		size = Vector3.new(0.4, 0.4, 0.4),
		position = Vector3.new(x, 8, z),
		transparency = 1,
		shadow = false,
		collide = false,
	})
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 100)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 100, 200)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 100, 255)),
	})
	emitter.LightEmission = 0.2
	emitter.Size = NumberSequence.new(0.5, 0.4)
	emitter.Lifetime = NumberRange.new(3, 5)
	emitter.Rate = count or 3
	emitter.Speed = NumberRange.new(2, 4)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.RotSpeed = NumberRange.new(-90, 90)
	emitter.Acceleration = Vector3.new(0, -1, 0)
	emitter.Parent = host
end

local function bird(parent, x, z, height)
	-- A simple flying part that bobs in place via tween-free spinning.
	local b = makePart({ parent = parent,
		size = Vector3.new(1, 0.4, 0.6),
		position = Vector3.new(x, height or 22, z),
		color = ({ Color3.fromRGB(80, 80, 80), Color3.fromRGB(220, 220, 230), Color3.fromRGB(60, 100, 160) })[math.random(1, 3)],
		material = Enum.Material.SmoothPlastic,
		shadow = false,
		collide = false,
	})
	-- Visual wings
	for _, sx in ipairs({ -1, 1 }) do
		local w = makePart({ parent = parent,
			size = Vector3.new(0.1, 0.1, 1.2),
			cframe = b.CFrame * CFrame.new(0.4 * sx, 0, 0) * CFrame.Angles(math.rad(-15 * sx), 0, 0),
			color = b.Color,
			material = Enum.Material.SmoothPlastic,
			shadow = false,
			collide = false,
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
	light.Enabled = false
	light.Parent = bulb
	return bulb
end

local function bench(parent, x, z, rotateY)
	rotateY = rotateY or 0
	local cf = CFrame.new(x, 2, z) * CFrame.Angles(0, math.rad(rotateY), 0)
	makePart({ parent = parent, size = Vector3.new(8, 0.6, 2), cframe = cf, color = Color3.fromRGB(150, 100, 60), material = Enum.Material.Wood })
	makePart({ parent = parent, size = Vector3.new(8, 3, 0.5), cframe = cf * CFrame.new(0, 1.5, -1), color = Color3.fromRGB(150, 100, 60), material = Enum.Material.Wood })
	for _, dx in ipairs({ -3.5, 3.5 }) do
		makePart({ parent = parent, size = Vector3.new(0.5, 1.5, 2), cframe = cf * CFrame.new(dx, -1, 0), color = Color3.fromRGB(80, 60, 40), material = Enum.Material.Wood })
	end
end

local function fireHydrant(parent, x, z)
	makePart({ parent = parent, size = Vector3.new(1.4, 2.4, 1.4), position = Vector3.new(x, 2.2, z), color = Color3.fromRGB(200, 50, 50), material = Enum.Material.SmoothPlastic })
	makePart({ parent = parent, size = Vector3.new(1.6, 0.4, 1.6), position = Vector3.new(x, 3.6, z), color = Color3.fromRGB(200, 50, 50), material = Enum.Material.SmoothPlastic })
end

local function fountain(parent, x, z)
	for i = 0, 3 do
		local angle = math.rad(i * 90 + 45)
		makePart({ parent = parent,
			size = Vector3.new(14, 2.5, 3),
			cframe = CFrame.new(x + math.cos(angle) * 7, 2.25, z + math.sin(angle) * 7) * CFrame.Angles(0, angle, 0),
			color = Color3.fromRGB(200, 195, 180), material = Enum.Material.Marble,
		})
	end
	makePart({ parent = parent, size = Vector3.new(13, 1, 13), position = Vector3.new(x, 2.5, z), color = Color3.fromRGB(80, 160, 220), material = Enum.Material.Water, transparency = 0.2, shadow = false })
	makePart({ parent = parent, size = Vector3.new(2.4, 5, 2.4), position = Vector3.new(x, 5, z), color = Color3.fromRGB(220, 215, 200), material = Enum.Material.Marble })
	local spout = makePart({ parent = parent, size = Vector3.new(1.2, 1.2, 1.2), position = Vector3.new(x, 8, z), color = Color3.fromRGB(200, 230, 255), material = Enum.Material.Neon, shape = Enum.PartType.Ball, shadow = false })
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

-- ============================================================ portals (fast travel)
WorldBuilder.PORTALS = {}  -- name → { position, target }

local function buildPortal(parent, name, x, z, color, label, targetName)
	local g = group("Portal_" .. name, parent)
	local ring = makePart({ parent = g,
		size = Vector3.new(8, 0.4, 8),
		position = Vector3.new(x, 1, z),
		color = color,
		material = Enum.Material.Neon,
		shape = Enum.PartType.Cylinder,
		transparency = 0.2,
		shadow = false,
		collide = false,
		name = "PortalRing",
	})
	ring.CFrame = CFrame.new(x, 1, z) * CFrame.Angles(0, 0, math.rad(90))
	-- Vertical column of light
	local col = makePart({ parent = g,
		size = Vector3.new(6, 14, 6),
		position = Vector3.new(x, 8, z),
		color = color,
		material = Enum.Material.Neon,
		shape = Enum.PartType.Cylinder,
		transparency = 0.85,
		shadow = false,
		collide = false,
	})
	col.CFrame = CFrame.new(x, 8, z) * CFrame.Angles(0, 0, math.rad(90))
	-- Floating sign
	local signGui = Instance.new("BillboardGui")
	signGui.Size = UDim2.fromOffset(220, 50)
	signGui.StudsOffset = Vector3.new(0, 8, 0)
	signGui.AlwaysOnTop = true
	signGui.Parent = ring
	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
	frame.BackgroundTransparency = 0.2
	frame.Size = UDim2.fromScale(1, 1)
	frame.Parent = signGui
	local fc = Instance.new("UICorner") fc.CornerRadius = UDim.new(0, 8) fc.Parent = frame
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 14
	lbl.TextColor3 = color
	lbl.Text = label
	lbl.Parent = frame

	-- ProximityPrompt for travel
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = label
	prompt.ObjectText = "Fast Travel"
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = ring

	WorldBuilder.PORTALS[name] = { position = Vector3.new(x, 1, z), target = targetName, prompt = prompt }
	return prompt
end

-- ============================================================ buildings (with optional interior)
local function building(parent, opts)
	local g = group(opts.name or "Building", parent)
	local x, z = opts.x, opts.z
	local w, d, h = opts.w, opts.d, opts.h or 14
	local body = opts.bodyColor
	local accent = opts.accentColor
	local doorWidth = math.min(w * 0.25, 6)

	makePart({ parent = g, size = Vector3.new(w + 2, 1, d + 2), position = Vector3.new(x, 0.5, z), color = Color3.fromRGB(140, 140, 145), material = Enum.Material.Concrete })
	makePart({ parent = g, size = Vector3.new(w - 0.4, 0.4, d - 0.4), position = Vector3.new(x, 1.2, z), color = Color3.fromRGB(180, 150, 110), material = Enum.Material.Wood })

	-- Walls (back, left, right) - solid
	makePart({ parent = g, size = Vector3.new(w, h, 0.4), position = Vector3.new(x, h / 2 + 1, z - d / 2), color = body, material = Enum.Material.Brick })
	makePart({ parent = g, size = Vector3.new(0.4, h, d), position = Vector3.new(x - w / 2, h / 2 + 1, z), color = body, material = Enum.Material.Brick })
	makePart({ parent = g, size = Vector3.new(0.4, h, d), position = Vector3.new(x + w / 2, h / 2 + 1, z), color = body, material = Enum.Material.Brick })

	-- Front wall: 3 segments around the door cutout
	local sideWidth = (w - doorWidth) / 2
	makePart({ parent = g, size = Vector3.new(sideWidth, h, 0.4), position = Vector3.new(x - (sideWidth + doorWidth) / 2, h / 2 + 1, z + d / 2), color = body, material = Enum.Material.Brick })
	makePart({ parent = g, size = Vector3.new(sideWidth, h, 0.4), position = Vector3.new(x + (sideWidth + doorWidth) / 2, h / 2 + 1, z + d / 2), color = body, material = Enum.Material.Brick })
	makePart({ parent = g, size = Vector3.new(doorWidth + 1, h - 7, 0.4), position = Vector3.new(x, h - (h - 7) / 2 + 1, z + d / 2), color = body, material = Enum.Material.Brick })

	-- Roof
	makePart({ parent = g, size = Vector3.new(w + 2, 1.5, d + 2), position = Vector3.new(x, h + 1.5, z), color = accent, material = Enum.Material.Slate })

	-- Door frame + open door
	makePart({ parent = g, size = Vector3.new(doorWidth + 0.8, 7, 0.6), position = Vector3.new(x, 4.5, z + d / 2 + 0.1), color = Color3.fromRGB(80, 50, 30), material = Enum.Material.Wood })
	-- Welcome mat (helps players see "this is a door")
	makePart({ parent = g, size = Vector3.new(doorWidth, 0.2, 3), position = Vector3.new(x, 1.2, z + d / 2 + 1.6), color = Color3.fromRGB(150, 80, 70), material = Enum.Material.Fabric, shadow = false })

	-- Awning
	makePart({ parent = g, size = Vector3.new(w * 0.45, 0.5, 5), position = Vector3.new(x, 8.5, z + d / 2 + 2.5), color = accent, material = Enum.Material.SmoothPlastic })

	-- Front windows
	for _, sx in ipairs({ -1, 1 }) do
		makePart({ parent = g, size = Vector3.new(2.5, 3, 0.2), position = Vector3.new(x + sx * (sideWidth / 2 + doorWidth / 2 - 0.1), 7, z + d / 2), color = Color3.fromRGB(180, 220, 255), material = Enum.Material.Glass, transparency = 0.2 })
	end
	-- Side windows
	for _, side in ipairs({ -1, 1 }) do
		for i = -1, 1 do
			makePart({ parent = g, size = Vector3.new(0.2, 3, 2.5), position = Vector3.new(x + side * w / 2, 7, z + i * (d / 4)), color = Color3.fromRGB(180, 220, 255), material = Enum.Material.Glass, transparency = 0.2 })
		end
	end

	-- Sign
	if opts.sign then
		local sign = makePart({ parent = g, size = Vector3.new(doorWidth * 1.8, 1.4, 0.3), position = Vector3.new(x, 9.6, z + d / 2 + 0.4), color = Color3.fromRGB(40, 30, 25), material = Enum.Material.Wood })
		local sgui = Instance.new("SurfaceGui") sgui.Face = Enum.NormalId.Front sgui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud sgui.PixelsPerStud = 80 sgui.Parent = sign
		local lbl = Instance.new("TextLabel") lbl.Size = UDim2.fromScale(1, 1) lbl.BackgroundTransparency = 1 lbl.Font = Enum.Font.GothamBold lbl.TextColor3 = Color3.fromRGB(255, 230, 130) lbl.TextScaled = true lbl.Text = opts.sign lbl.Parent = sgui
	end

	-- Interior NPC anchor + decor
	if opts.hasInterior ~= false then
		makePart({ parent = g, size = Vector3.new(w * 0.6, 2.5, 1.5), position = Vector3.new(x, 2.6, z - d / 4), color = Color3.fromRGB(180, 130, 80), material = Enum.Material.Wood })
		local interiorLight = makePart({ parent = g, size = Vector3.new(2, 0.4, 2), position = Vector3.new(x, h, z), color = Color3.fromRGB(255, 240, 200), material = Enum.Material.Neon, shadow = false, collide = false })
		local pl = Instance.new("PointLight") pl.Range = 20 pl.Brightness = 1.0 pl.Color = Color3.fromRGB(255, 240, 200) pl.Parent = interiorLight

		-- Enter prompt at the door (visible label)
		local doorPrompt = Instance.new("Part")
		doorPrompt.Anchored = true
		doorPrompt.CanCollide = false
		doorPrompt.Transparency = 1
		doorPrompt.Size = Vector3.new(2, 4, 2)
		doorPrompt.Position = Vector3.new(x, 4, z + d / 2 + 0.6)
		doorPrompt.Parent = g
		local enter = Instance.new("ProximityPrompt")
		enter.ActionText = "Enter"
		enter.ObjectText = opts.name or "Building"
		enter.HoldDuration = 0
		enter.MaxActivationDistance = 12
		enter.RequiresLineOfSight = false
		enter.Parent = doorPrompt
		-- Teleport player a few studs into the building
		enter.Triggered:Connect(function(player)
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if root then root.CFrame = CFrame.new(x, 4, z - d / 4 + 4) end
		end)
	end

	return g, Vector3.new(x, 1.5, z - d / 4 - 2)
end

local function skyscraper(parent, x, z, w, d, floors, color, name)
	local g = group(name or "Skyscraper", parent)
	local h = floors * 8
	makePart({ parent = g, size = Vector3.new(w + 2, 1, d + 2), position = Vector3.new(x, 0.5, z), color = Color3.fromRGB(110, 110, 120), material = Enum.Material.Concrete })
	makePart({ parent = g, size = Vector3.new(w, h, d), position = Vector3.new(x, h / 2 + 1, z), color = color, material = Enum.Material.Concrete, reflectance = 0.05 })
	for f = 1, floors do
		for i = -math.floor(w / 8), math.floor(w / 8) do
			if i ~= 0 then
				makePart({ parent = g, size = Vector3.new(2.5, 4, 0.2), position = Vector3.new(x + i * 5, 3 + (f - 1) * 8, z + d / 2 + 0.05), color = Color3.fromRGB(150, 200, 255), material = Enum.Material.Glass, transparency = 0.15 })
			end
		end
	end
	makePart({ parent = g, size = Vector3.new(2, 1.5, 2), position = Vector3.new(x, h + 1.8, z), color = Color3.fromRGB(255, 60, 60), material = Enum.Material.Neon, shape = Enum.PartType.Ball })
end

local function house(parent, x, z, color, accentColor, name)
	local g = group(name or "House", parent)
	local w, d, h = 22, 18, 10
	makePart({ parent = g, size = Vector3.new(w + 1, 1, d + 1), position = Vector3.new(x, 0.5, z), color = Color3.fromRGB(160, 150, 140), material = Enum.Material.Concrete })
	local doorW = 4
	makePart({ parent = g, size = Vector3.new(w, h, 0.4), position = Vector3.new(x, h / 2 + 1, z - d / 2), color = color, material = Enum.Material.WoodPlanks })
	makePart({ parent = g, size = Vector3.new(0.4, h, d), position = Vector3.new(x - w / 2, h / 2 + 1, z), color = color, material = Enum.Material.WoodPlanks })
	makePart({ parent = g, size = Vector3.new(0.4, h, d), position = Vector3.new(x + w / 2, h / 2 + 1, z), color = color, material = Enum.Material.WoodPlanks })
	local sideW = (w - doorW) / 2
	makePart({ parent = g, size = Vector3.new(sideW, h, 0.4), position = Vector3.new(x - (sideW + doorW) / 2, h / 2 + 1, z + d / 2), color = color, material = Enum.Material.WoodPlanks })
	makePart({ parent = g, size = Vector3.new(sideW, h, 0.4), position = Vector3.new(x + (sideW + doorW) / 2, h / 2 + 1, z + d / 2), color = color, material = Enum.Material.WoodPlanks })
	makePart({ parent = g, size = Vector3.new(doorW + 0.5, h - 6, 0.4), position = Vector3.new(x, h - (h - 6) / 2 + 1, z + d / 2), color = color, material = Enum.Material.WoodPlanks })
	makePart({ parent = g, size = Vector3.new(w - 0.4, 0.3, d - 0.4), position = Vector3.new(x, 1.15, z), color = Color3.fromRGB(150, 110, 70), material = Enum.Material.Wood })
	for i = 1, 4 do
		makePart({ parent = g, size = Vector3.new(w + 2, 1, d + 2 - (i - 1) * 4), position = Vector3.new(x, h + 1 + i * 1.2, z), color = accentColor, material = Enum.Material.Slate })
	end
	makePart({ parent = g, size = Vector3.new(2, 4, 2), position = Vector3.new(x + w / 4, h + 4, z - d / 4), color = Color3.fromRGB(180, 80, 60), material = Enum.Material.Brick })
	makePart({ parent = g, size = Vector3.new(0.4, 4, 0.4), position = Vector3.new(x + w / 2 + 4, 3, z + d / 2 + 2), color = Color3.fromRGB(120, 80, 40), material = Enum.Material.Wood })
	makePart({ parent = g, size = Vector3.new(2, 1.2, 1.2), position = Vector3.new(x + w / 2 + 4, 5.5, z + d / 2 + 2), color = Color3.fromRGB(220, 80, 80), material = Enum.Material.SmoothPlastic })
	return g, Vector3.new(x, 1.5, z)
end

-- ============================================================ special features
local function river(parent, x, z, length, width)
	makePart({ parent = parent, size = Vector3.new(length, 1.4, width), position = Vector3.new(x, 0, z), color = Color3.fromRGB(60, 130, 200), material = Enum.Material.Water, transparency = 0.25, shadow = false })
	for _, dz in ipairs({ -width / 2 - 2, width / 2 + 2 }) do
		makePart({ parent = parent, size = Vector3.new(length, 2, 4), position = Vector3.new(x, 0.8, z + dz), color = Color3.fromRGB(150, 130, 100), material = Enum.Material.Sand, shadow = false })
	end
end

local function ocean(parent, x, z, w, d)
	makePart({ parent = parent, size = Vector3.new(w, 2, d), position = Vector3.new(x, -0.2, z), color = Color3.fromRGB(45, 110, 180), material = Enum.Material.Water, transparency = 0.3, shadow = false })
end

local function beachSand(parent, x, z, w, d)
	makePart({ parent = parent, size = Vector3.new(w, 1, d), position = Vector3.new(x, 0.55, z), color = Color3.fromRGB(245, 230, 180), material = Enum.Material.Sand, shadow = false })
end

local function bridge(parent, x, z)
	local g = group("Bridge", parent)
	makePart({ parent = g, size = Vector3.new(24, 1, 8), position = Vector3.new(x, 4, z), color = Color3.fromRGB(170, 120, 70), material = Enum.Material.Wood })
	for _, dz in ipairs({ -3.5, 3.5 }) do
		makePart({ parent = g, size = Vector3.new(24, 1.5, 0.4), position = Vector3.new(x, 5.5, z + dz), color = Color3.fromRGB(140, 95, 55), material = Enum.Material.Wood })
		for i = -2, 2 do
			makePart({ parent = g, size = Vector3.new(0.4, 2, 0.4), position = Vector3.new(x + i * 5, 5, z + dz), color = Color3.fromRGB(140, 95, 55), material = Enum.Material.Wood })
		end
	end
	for _, dx in ipairs({ -10, 10 }) do
		makePart({ parent = g, size = Vector3.new(2, 8, 2), position = Vector3.new(x + dx, 0, z), color = Color3.fromRGB(120, 90, 60), material = Enum.Material.Wood })
	end
end

local function mountainPeak(parent, x, z, height)
	for i = 1, 5 do
		local s = (1 - (i - 1) / 5) * 1.0
		local size = (60 - i * 10) * s
		makePart({ parent = parent, size = Vector3.new(size, height * 0.25, size), position = Vector3.new(x, height * 0.125 + (i - 1) * height * 0.18, z), color = colorJitter(Color3.fromRGB(150, 150, 155), 0.05), material = Enum.Material.Slate })
	end
	makePart({ parent = parent, size = Vector3.new(14, 6, 14), position = Vector3.new(x, height + 2, z), color = Color3.fromRGB(245, 245, 250), material = Enum.Material.Snow })
end

local function caveTunnel(parent, x, z, length)
	local g = group("Cave", parent)
	makePart({ parent = g, size = Vector3.new(length, 1, 16), position = Vector3.new(x, 0.5, z), color = Color3.fromRGB(80, 75, 75), material = Enum.Material.Slate })
	for _, dz in ipairs({ -8, 8 }) do
		makePart({ parent = g, size = Vector3.new(length, 16, 1), position = Vector3.new(x, 8, z + dz), color = Color3.fromRGB(100, 95, 90), material = Enum.Material.Slate })
	end
	makePart({ parent = g, size = Vector3.new(length, 1, 16), position = Vector3.new(x, 16, z), color = Color3.fromRGB(70, 65, 65), material = Enum.Material.Slate })
	for i = -length / 2 + 30, length / 2 - 30, 28 do
		local crystalColor = ({ Color3.fromRGB(160, 200, 255), Color3.fromRGB(200, 160, 255), Color3.fromRGB(160, 255, 220), Color3.fromRGB(255, 200, 220) })[math.random(1, 4)]
		local crystal = makePart({ parent = g,
			size = Vector3.new(1.2, 3.5, 1.2),
			cframe = CFrame.new(x + i, 12, z + math.random(-6, 6)) * CFrame.Angles(math.rad(math.random(-15, 15)), 0, 0),
			color = crystalColor, material = Enum.Material.Neon,
		})
		local pl = Instance.new("PointLight") pl.Color = crystalColor pl.Range = 18 pl.Brightness = 1.4 pl.Parent = crystal
	end
	for i = -length / 2, length / 2, 12 do
		makePart({ parent = g, size = Vector3.new(1, 2.5, 1), position = Vector3.new(x + i + math.random(-3, 3), 14, z + math.random(-5, 5)), color = Color3.fromRGB(60, 55, 55), material = Enum.Material.Slate })
	end
end

local function pier(parent, x, z, length)
	local g = group("Pier", parent)
	makePart({ parent = g, size = Vector3.new(8, 1, length), position = Vector3.new(x, 2, z), color = Color3.fromRGB(170, 120, 70), material = Enum.Material.Wood })
	for i = -length / 2, length / 2, 6 do
		for _, dx in ipairs({ -3.5, 3.5 }) do
			makePart({ parent = g, size = Vector3.new(0.6, 5, 0.6), position = Vector3.new(x + dx, 0, z + i), color = Color3.fromRGB(120, 80, 50), material = Enum.Material.Wood })
		end
	end
end

local function lifeguardTower(parent, x, z)
	local g = group("Lifeguard", parent)
	for _, dx in ipairs({ -4, 4 }) do
		for _, dz in ipairs({ -4, 4 }) do
			makePart({ parent = g, size = Vector3.new(0.8, 14, 0.8), position = Vector3.new(x + dx, 7, z + dz), color = Color3.fromRGB(130, 90, 50), material = Enum.Material.Wood })
		end
	end
	makePart({ parent = g, size = Vector3.new(10, 0.6, 10), position = Vector3.new(x, 13.5, z), color = Color3.fromRGB(220, 180, 130), material = Enum.Material.Wood })
	makePart({ parent = g, size = Vector3.new(10, 6, 0.4), position = Vector3.new(x, 16.8, z - 5), color = Color3.fromRGB(220, 60, 60), material = Enum.Material.SmoothPlastic })
	makePart({ parent = g, size = Vector3.new(0.4, 6, 10), position = Vector3.new(x - 5, 16.8, z), color = Color3.fromRGB(220, 60, 60), material = Enum.Material.SmoothPlastic })
	makePart({ parent = g, size = Vector3.new(0.4, 6, 10), position = Vector3.new(x + 5, 16.8, z), color = Color3.fromRGB(220, 60, 60), material = Enum.Material.SmoothPlastic })
	makePart({ parent = g, size = Vector3.new(11, 0.8, 11), position = Vector3.new(x, 20, z), color = Color3.fromRGB(200, 50, 50), material = Enum.Material.SmoothPlastic })
end

local function beachUmbrella(parent, x, z, color)
	makePart({ parent = parent, size = Vector3.new(0.4, 6, 0.4), position = Vector3.new(x, 3, z), color = Color3.fromRGB(120, 80, 50), material = Enum.Material.Wood })
	for i = 0, 5 do
		local angle = math.rad(i * 60)
		makePart({ parent = parent, size = Vector3.new(5, 0.3, 5), cframe = CFrame.new(x + math.cos(angle) * 0.3, 6, z + math.sin(angle) * 0.3) * CFrame.Angles(0, angle, math.rad(-12)), color = color, material = Enum.Material.Fabric })
	end
end

local function agilityJump(parent, x, z)
	local g = group("AgilityJump", parent)
	for _, dx in ipairs({ -3, 3 }) do
		makePart({ parent = g, size = Vector3.new(0.5, 5, 0.5), position = Vector3.new(x + dx, 2.5, z), color = Color3.fromRGB(220, 220, 220), material = Enum.Material.SmoothPlastic })
	end
	makePart({ parent = g, size = Vector3.new(7, 0.4, 0.4), position = Vector3.new(x, 4.5, z), color = Color3.fromRGB(220, 80, 80), material = Enum.Material.SmoothPlastic })
end

local function weavePoles(parent, x, z, count)
	local g = group("WeavePoles", parent)
	for i = 0, count - 1 do
		makePart({ parent = g, size = Vector3.new(0.4, 5, 0.4), position = Vector3.new(x + (i - count / 2) * 2, 2.5, z), color = Color3.fromRGB(80, 130, 220), material = Enum.Material.SmoothPlastic })
	end
end

local function agilityTunnel(parent, x, z)
	local g = group("AgilityTunnel", parent)
	for i = -4, 4 do
		makePart({ parent = g, size = Vector3.new(0.5, 6, 6), cframe = CFrame.new(x + i * 1.5, 3, z) * CFrame.Angles(0, math.rad(90), 0), color = Color3.fromRGB(220, 100, 60), material = Enum.Material.Fabric })
	end
end

local function asphaltStrip(parent, x1, z1, x2, z2, width)
	local dx, dz = x2 - x1, z2 - z1
	local len = math.sqrt(dx * dx + dz * dz)
	if len < 1 then return end
	local angle = math.atan2(dx, dz)
	local cf = CFrame.new((x1 + x2) / 2, 0.6, (z1 + z2) / 2) * CFrame.Angles(0, angle, 0)
	makePart({ parent = parent, size = Vector3.new(width, 0.4, len), cframe = cf, color = Color3.fromRGB(70, 70, 75), material = Enum.Material.Asphalt, shadow = false })
	local stripes = math.floor(len / 8)
	for i = 1, stripes do
		local off = (i - (stripes + 1) / 2) * 8
		makePart({ parent = parent, cframe = cf * CFrame.new(0, 0.2, off), size = Vector3.new(0.4, 0.45, 4), color = Color3.fromRGB(255, 230, 100), material = Enum.Material.SmoothPlastic, shadow = false })
	end
	-- Sidewalks + lampposts every 28 studs
	makePart({ parent = parent, cframe = cf * CFrame.new(width / 2 + 2, -0.05, 0), size = Vector3.new(4, 0.6, len), color = Color3.fromRGB(190, 190, 195), material = Enum.Material.Concrete, shadow = false })
	makePart({ parent = parent, cframe = cf * CFrame.new(-(width / 2 + 2), -0.05, 0), size = Vector3.new(4, 0.6, len), color = Color3.fromRGB(190, 190, 195), material = Enum.Material.Concrete, shadow = false })
	for off = -len / 2 + 14, len / 2 - 14, 28 do
		local lampPos = (cf * CFrame.new(width / 2 + 5, 0, off)).Position
		lamppost(parent, lampPos.X, lampPos.Z)
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
WorldBuilder._npcAnchors = {}

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
	-- Welcome arch
	makePart({ parent = c, size = Vector3.new(14, 0.6, 0.4), position = Vector3.new(0, 10, -50), color = Color3.fromRGB(60, 40, 25), material = Enum.Material.Wood })
	makePart({ parent = c, size = Vector3.new(0.5, 10, 0.5), position = Vector3.new(-7, 5, -50), color = Color3.fromRGB(80, 50, 30), material = Enum.Material.Wood })
	makePart({ parent = c, size = Vector3.new(0.5, 10, 0.5), position = Vector3.new(7, 5, -50), color = Color3.fromRGB(80, 50, 30), material = Enum.Material.Wood })
	-- Direction signs to points of interest
	local function sign(parent, x, z, text, color)
		local post = makePart({ parent = parent, size = Vector3.new(0.5, 6, 0.5), position = Vector3.new(x, 3, z), color = Color3.fromRGB(100, 70, 40), material = Enum.Material.Wood })
		local plate = makePart({ parent = parent, size = Vector3.new(8, 1.6, 0.3), position = Vector3.new(x, 5.5, z), color = color, material = Enum.Material.Wood })
		local sgui = Instance.new("SurfaceGui") sgui.Face = Enum.NormalId.Front sgui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud sgui.PixelsPerStud = 60 sgui.Parent = plate
		local lbl = Instance.new("TextLabel") lbl.Size = UDim2.fromScale(1, 1) lbl.BackgroundTransparency = 1 lbl.Font = Enum.Font.GothamBold lbl.TextColor3 = Color3.new(1, 1, 1) lbl.TextScaled = true lbl.Text = text lbl.Parent = sgui
	end
	sign(c, -45, 30, "← MOUNTAINS / HOME", Color3.fromRGB(100, 70, 40))
	sign(c, 45, 30, "BAKERY / VET →", Color3.fromRGB(180, 80, 60))
	sign(c, -45, -30, "← MEADOW", Color3.fromRGB(80, 130, 60))
	sign(c, 45, -30, "PARK / DOWNTOWN →", Color3.fromRGB(60, 100, 160))

	-- Fast-travel home portal
	buildPortal(c, "PlazaHome", -50, 50, Color3.fromRGB(180, 120, 220), "🏡 Travel Home", "Home")

	spawnPad(c, 24, 24)

	-- Atmosphere: butterflies in plaza
	butterflies(c, -10, 20, 4)
	butterflies(c, 20, -10, 4)
end

local function buildPark(c)
	for i = 1, 36 do  -- denser foliage
		tree(c, -80 + math.random(0, 160), -260 + math.random(0, 160), 0.7 + math.random() * 0.7)
	end
	for _ = 1, 16 do
		flowerPatch(c, math.random(-80, 80), -250 + math.random(-50, 50))
	end
	for _ = 1, 6 do
		bush(c, math.random(-70, 70), -240 + math.random(-50, 50), 0.9)
	end
	bench(c, -25, -180, 0)
	bench(c, 25, -180, 180)
	-- Pond
	makePart({ parent = c, size = Vector3.new(50, 1.4, 36), position = Vector3.new(40, 0.6, -240), color = Color3.fromRGB(80, 160, 220), material = Enum.Material.Water, transparency = 0.2, shadow = false })
	makePart({ parent = c, size = Vector3.new(8, 1, 6), position = Vector3.new(8, 1.6, -240), color = Color3.fromRGB(160, 110, 70), material = Enum.Material.Wood })
	-- Birds + butterflies
	butterflies(c, 0, -240, 8)
	for _ = 1, 6 do
		bird(c, math.random(-60, 60), -240 + math.random(-30, 30), 18 + math.random(0, 6))
	end
end

local function buildBakery(c)
	local _, mae = building(c, { x = 180, z = -160, w = 30, d = 22, h = 14, bodyColor = Color3.fromRGB(220, 170, 120), accentColor = Color3.fromRGB(180, 70, 60),  name = "Bakery", sign = "BAKERY" })
	WorldBuilder._npcAnchors.bakery_interior = mae
	local _, cafeNpc = building(c, { x = 230, z = -180, w = 26, d = 20, h = 12, bodyColor = Color3.fromRGB(230, 200, 150), accentColor = Color3.fromRGB(120, 80, 40),  name = "Cafe", sign = "CAFE" })
	WorldBuilder._npcAnchors.cafe_interior = cafeNpc
	local _, treats = building(c, { x = 200, z = -100, w = 24, d = 18, h = 12, bodyColor = Color3.fromRGB(240, 210, 170), accentColor = Color3.fromRGB(80, 130, 90),  name = "PetTreats", sign = "PET TREATS" })
	WorldBuilder._npcAnchors.treats_interior = treats
	for _ = 1, 8 do flowerPatch(c, 160 + math.random(0, 80), -120 + math.random(-30, 30)) end
	makePart({ parent = c, size = Vector3.new(4, 0.4, 4), position = Vector3.new(180, 3, -130), color = Color3.fromRGB(200, 150, 100), material = Enum.Material.Wood })
	makePart({ parent = c, size = Vector3.new(0.6, 3, 0.6), position = Vector3.new(180, 1.5, -130), color = Color3.fromRGB(80, 50, 30), material = Enum.Material.Wood })
	for _ = 1, 4 do tree(c, 130 + math.random(0, 120), -180 + math.random(0, 60), 0.7) end
end

local function buildVet(c)
	local _, vet = building(c, { x = 200, z = 130, w = 36, d = 28, h = 16, bodyColor = Color3.fromRGB(220, 240, 250), accentColor = Color3.fromRGB(80, 130, 200),  name = "VetHospital", sign = "VET HOSPITAL" })
	WorldBuilder._npcAnchors.vet_interior = vet
	local _, shelter = building(c, { x = 160, z = 90, w = 22, d = 18, h = 12, bodyColor = Color3.fromRGB(240, 240, 240), accentColor = Color3.fromRGB(160, 60, 60),   name = "Shelter", sign = "SHELTER" })
	WorldBuilder._npcAnchors.shelter_interior = shelter
	-- Ambulance
	makePart({ parent = c, size = Vector3.new(8, 4, 14), position = Vector3.new(240, 3, 160), color = Color3.fromRGB(245, 245, 245), material = Enum.Material.SmoothPlastic })
	makePart({ parent = c, size = Vector3.new(8, 0.3, 14), position = Vector3.new(240, 5.2, 160), color = Color3.fromRGB(220, 60, 60), material = Enum.Material.SmoothPlastic })
end

local function buildDogPark(c)
	for x = 30, 220, 8 do
		for _, dz in ipairs({ 200, 320 }) do
			makePart({ parent = c, size = Vector3.new(0.4, 4, 0.4), position = Vector3.new(x, 2, dz), color = Color3.fromRGB(160, 110, 70), material = Enum.Material.Wood })
		end
	end
	for z = 200, 320, 8 do
		for _, dx in ipairs({ 30, 220 }) do
			makePart({ parent = c, size = Vector3.new(0.4, 4, 0.4), position = Vector3.new(dx, 2, z), color = Color3.fromRGB(160, 110, 70), material = Enum.Material.Wood })
		end
	end
	agilityJump(c, 120, 230)
	agilityJump(c, 120, 250)
	weavePoles(c, 120, 280, 6)
	agilityTunnel(c, 120, 310)
	fireHydrant(c, 50, 220)
	fireHydrant(c, 200, 310)
	tree(c, 50, 320, 1.2)
	tree(c, 200, 200, 1.2)
end

local function buildBeach(c)
	beachSand(c, -60, 390, 360, 180)
	ocean(c, -60, 600, 1100, 500)
	pier(c, -100, 500, 160)
	lifeguardTower(c, -180, 390)
	for i = 1, 8 do
		beachUmbrella(c, -220 + i * 50 + math.random(-10, 10), 390 + math.random(-30, 30),
			({ Color3.fromRGB(255, 100, 130), Color3.fromRGB(255, 200, 100), Color3.fromRGB(80, 180, 220), Color3.fromRGB(180, 120, 220) })[math.random(1, 4)])
	end
	for _ = 1, 6 do
		local x = -220 + math.random(0, 440)
		local z = 340 + math.random(-30, 30)
		makePart({ parent = c, size = Vector3.new(1, 14, 1), position = Vector3.new(x, 8, z), color = Color3.fromRGB(120, 80, 50), material = Enum.Material.Wood })
		for i = 0, 4 do
			local angle = math.rad(i * 72)
			makePart({ parent = c, size = Vector3.new(7, 0.6, 1.5), cframe = CFrame.new(x + math.cos(angle) * 3, 15, z + math.sin(angle) * 3) * CFrame.Angles(math.rad(-15), angle, 0), color = Color3.fromRGB(60, 140, 70), material = Enum.Material.LeafyGrass })
		end
	end
end

local function buildRiverside(c)
	river(c, -60, 200, 420, 28)
	bridge(c, 0, 200)
	for _ = 1, 12 do
		makePart({ parent = c, size = Vector3.new(2 + math.random() * 2, 1.5, 2 + math.random() * 2), position = Vector3.new(math.random(-200, 80), 1.4, 180 + math.random(0, 40)), color = Color3.fromRGB(140, 130, 120), material = Enum.Material.Slate, shape = Enum.PartType.Ball })
	end
end

local function buildDowntown(c)
	skyscraper(c, 320, -50, 36, 36, 8, Color3.fromRGB(200, 210, 220), "Tower A")
	skyscraper(c, 400, 40, 30, 30, 6, Color3.fromRGB(180, 180, 200), "Tower B")
	skyscraper(c, 290, 80, 32, 32, 7, Color3.fromRGB(220, 200, 180), "Tower C")
	skyscraper(c, 410, -90, 28, 28, 5, Color3.fromRGB(170, 200, 220), "Tower D")
	local _, off = building(c, { x = 360, z = 110, w = 32, d = 24, h = 18, bodyColor = Color3.fromRGB(150, 170, 200), accentColor = Color3.fromRGB(60, 80, 120), name = "Office", sign = "OFFICE" })
	WorldBuilder._npcAnchors.office_interior = off
end

local function buildMeadow(c)
	for i = 1, 36 do
		flowerPatch(c, -250 + math.random(0, 160), 160 + math.random(0, 140))
	end
	for i = 1, 12 do
		bush(c, -240 + math.random(0, 140), 180 + math.random(0, 120), 1.2)
	end
	for i = 1, 6 do tree(c, -240 + math.random(0, 140), 200 + math.random(0, 100), 1.0) end
	butterflies(c, -180, 230, 12)
end

local function buildMountainPass(c)
	mountainPeak(c, -280, -90, 80)
	mountainPeak(c, -340, -30, 100)
	mountainPeak(c, -380, 50, 90)
	mountainPeak(c, -340, 110, 75)
	mountainPeak(c, -280, 160, 85)
	mountainPeak(c, -240, 60, 70)
	for i = 1, 16 do
		pineTree(c, -270 + math.random(-30, 30), -90 + i * 20, 0.8 + math.random() * 0.4)
	end
	-- Mountain pass road sign
	local sign = makePart({ parent = c, size = Vector3.new(10, 1.6, 0.3), position = Vector3.new(-180, 6, 0), color = Color3.fromRGB(120, 80, 40), material = Enum.Material.Wood })
	local sgui = Instance.new("SurfaceGui") sgui.Face = Enum.NormalId.Front sgui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud sgui.PixelsPerStud = 60 sgui.Parent = sign
	local lbl = Instance.new("TextLabel") lbl.Size = UDim2.fromScale(1, 1) lbl.BackgroundTransparency = 1 lbl.Font = Enum.Font.GothamBold lbl.TextColor3 = Color3.fromRGB(255, 230, 130) lbl.TextScaled = true lbl.Text = "→ HOME (through cave)" lbl.Parent = sgui
end

local function buildCave(c)
	caveTunnel(c, -440, 0, 200)
	-- Stone arch entrance
	for ang = 0, 180, 18 do
		local rad = math.rad(ang)
		makePart({ parent = c, size = Vector3.new(3, 4, 3), position = Vector3.new(-350 + math.cos(rad) * 12, 4 + math.sin(rad) * 8, math.cos(rad - math.pi/2) * 0), color = Color3.fromRGB(110, 100, 90), material = Enum.Material.Slate })
	end
	makePart({ parent = c, size = Vector3.new(2, 1.6, 1.2), position = Vector3.new(-440, 1.8, 5), color = Color3.fromRGB(120, 80, 40), material = Enum.Material.Wood })
	makePart({ parent = c, size = Vector3.new(2.1, 0.4, 1.3), position = Vector3.new(-440, 2.6, 5), color = Color3.fromRGB(255, 200, 100), material = Enum.Material.Metal, shadow = false })
end

local function buildHomeDistrict(c)
	local _, anchor = house(c, -610, 0, Color3.fromRGB(245, 220, 180), Color3.fromRGB(170, 90, 60), "Your House")
	WorldBuilder._npcAnchors.home = anchor
	house(c, -680, -50, Color3.fromRGB(220, 200, 240), Color3.fromRGB(120, 100, 160), "Neighbour A")
	house(c, -540, 60, Color3.fromRGB(200, 230, 200), Color3.fromRGB(80, 140, 100), "Neighbour B")
	house(c, -660, 70, Color3.fromRGB(240, 240, 200), Color3.fromRGB(180, 120, 60), "Neighbour C")
	house(c, -560, -60, Color3.fromRGB(200, 220, 240), Color3.fromRGB(60, 100, 160), "Neighbour D")
	for x = -640, -580, 12 do
		for z = -80, 80, 22 do
			tree(c, x, z, 0.7)
		end
	end
	butterflies(c, -610, 30, 6)
	-- Return-to-plaza portal
	buildPortal(c, "HomePlaza", -610, -90, Color3.fromRGB(255, 220, 100), "🌆 Travel to Plaza", "Plaza")
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

	makePart({ parent = container, size = Vector3.new(2200, 1, 1800), position = Vector3.new(-200, 0, 100), color = Color3.fromRGB(126, 180, 100), material = Enum.Material.Grass, shadow = false, name = "Ground" })

	for _, d in ipairs(WorldBuilder.DISTRICTS) do
		tile(container, d.x, d.z, d.w, d.d, d.color)
	end

	-- Roads (compressed)
	asphaltStrip(container, 0, -65, 0, -135, 14)        -- → Park
	asphaltStrip(container, 0, 65, -30, 130, 14)         -- → Riverside
	asphaltStrip(container, 65, 0, 140, -50, 14)         -- → Bakery
	asphaltStrip(container, 65, 65, 140, 100, 14)        -- → Vet
	asphaltStrip(container, 140, 100, 130, 220, 14)      -- → Dog Park
	asphaltStrip(container, 140, -50, 280, 0, 14)        -- → Downtown
	asphaltStrip(container, -30, 130, -60, 320, 14)      -- → Beach
	asphaltStrip(container, -65, 0, -240, 0, 14)         -- → Mountain Pass
	asphaltStrip(container, -240, 0, -340, 0, 14)        -- → Cave entrance
	asphaltStrip(container, -540, 0, -595, 0, 14)        -- → Home district

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

	Lighting.ClockTime = 14
	Lighting.Brightness = 2
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 160, 170)
	Lighting.Ambient = Color3.fromRGB(70, 70, 90)
	Lighting.GlobalShadows = true
	Lighting.FogStart = 350
	Lighting.FogEnd = 1400
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
