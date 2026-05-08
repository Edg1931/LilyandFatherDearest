local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local WorldBuilder = {}

local CONTAINER_NAME = "PawprintWorld"

-- Convenience helpers ------------------------------------------------------
local function makePart(props)
	local p = Instance.new("Part")
	p.Anchored = true
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
	return p
end

local function group(name, parent)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

local function tile(parent, x, z, w, d, color)
	return makePart({
		parent = parent,
		size = Vector3.new(w, 1, d),
		position = Vector3.new(x, 0.5, z),
		color = color,
		material = Enum.Material.Grass,
		shadow = false,
	})
end

-- Districts -----------------------------------------------------------------
local DISTRICTS = {
	{ name = "Plaza",   x = 0,    z = 0,   w = 90,  d = 90,  color = Color3.fromRGB(204, 200, 178) },
	{ name = "Park",    x = 0,    z = -180, w = 130, d = 130, color = Color3.fromRGB(120, 180, 90) },
	{ name = "Bakery",  x = 180,  z = -100, w = 130, d = 130, color = Color3.fromRGB(216, 168, 110) },
	{ name = "Suburbs", x = -180, z = -100, w = 130, d = 130, color = Color3.fromRGB(174, 200, 140) },
	{ name = "Meadow",  x = -200, z = 110,  w = 130, d = 140, color = Color3.fromRGB(150, 200, 110) },
	{ name = "Vet",     x = 200,  z = 50,   w = 110, d = 110, color = Color3.fromRGB(208, 224, 240) },
	{ name = "Riverside", x = 0,  z = 200,  w = 200, d = 100, color = Color3.fromRGB(160, 180, 120) },
}

-- Decoration primitives -----------------------------------------------------
local function tree(parent, x, z, scale)
	scale = scale or 1
	local trunkH = 8 * scale
	makePart({ parent = parent,
		size = Vector3.new(2 * scale, trunkH, 2 * scale),
		position = Vector3.new(x, trunkH / 2, z),
		color = Color3.fromRGB(110, 75, 45),
		material = Enum.Material.Wood,
	})
	for i = 1, 3 do
		local r = (4 + i) * scale
		makePart({ parent = parent,
			size = Vector3.new(r * 1.6, r, r * 1.6),
			position = Vector3.new(x + math.random(-1, 1), trunkH + r / 2 + (i - 1) * 2, z + math.random(-1, 1)),
			color = Color3.fromRGB(60 + math.random(0, 40), 130 + math.random(0, 50), 60),
			material = Enum.Material.LeafyGrass,
			shape = Enum.PartType.Ball,
		})
	end
end

local function bush(parent, x, z)
	makePart({ parent = parent,
		size = Vector3.new(4, 3, 4),
		position = Vector3.new(x, 1.5, z),
		color = Color3.fromRGB(70, 140, 70),
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
			position = Vector3.new(fx, 0.8, fz),
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
	local pole = makePart({ parent = parent,
		size = Vector3.new(0.6, 14, 0.6),
		position = Vector3.new(x, 7, z),
		color = Color3.fromRGB(60, 60, 70),
		material = Enum.Material.Metal,
	})
	local bulb = makePart({ parent = parent,
		size = Vector3.new(2, 2, 2),
		position = Vector3.new(x, 14, z),
		color = Color3.fromRGB(255, 240, 180),
		material = Enum.Material.Neon,
		shape = Enum.PartType.Ball,
	})
	local light = Instance.new("PointLight")
	light.Brightness = 1.4
	light.Range = 22
	light.Color = Color3.fromRGB(255, 230, 170)
	light.Parent = bulb
end

local function bench(parent, x, z, rotateY)
	rotateY = rotateY or 0
	local cf = CFrame.new(x, 1.5, z) * CFrame.Angles(0, math.rad(rotateY), 0)
	local seat = makePart({ parent = parent,
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

local function building(parent, x, z, w, d, h, bodyColor, accentColor, name)
	local g = group(name or "Building", parent)
	-- Foundation
	makePart({ parent = g,
		size = Vector3.new(w + 2, 1, d + 2),
		position = Vector3.new(x, 0.5, z),
		color = Color3.fromRGB(140, 140, 145),
		material = Enum.Material.Concrete,
	})
	-- Body
	makePart({ parent = g,
		size = Vector3.new(w, h, d),
		position = Vector3.new(x, h / 2 + 1, z),
		color = bodyColor,
		material = Enum.Material.Brick,
	})
	-- Roof
	makePart({ parent = g,
		size = Vector3.new(w + 2, 1.5, d + 2),
		position = Vector3.new(x, h + 1.5, z),
		color = accentColor,
		material = Enum.Material.Slate,
	})
	-- Windows on each face
	local function windowsOn(faceCFrame, count, faceW)
		for i = 1, count do
			local off = (i - (count + 1) / 2) * (faceW / (count + 1))
			local frame = faceCFrame * CFrame.new(off, 0, 0.05)
			makePart({ parent = g,
				size = Vector3.new(faceW / (count + 2), h * 0.45, 0.2),
				cframe = frame,
				color = Color3.fromRGB(180, 220, 255),
				material = Enum.Material.Glass,
				transparency = 0.2,
			})
		end
	end
	local cy = h / 2 + 1
	windowsOn(CFrame.new(x, cy, z + d / 2),                                        math.max(2, math.floor(w / 6)), w)
	windowsOn(CFrame.new(x, cy, z - d / 2) * CFrame.Angles(0, math.rad(180), 0),  math.max(2, math.floor(w / 6)), w)
	windowsOn(CFrame.new(x + w / 2, cy, z) * CFrame.Angles(0, math.rad(90), 0),   math.max(2, math.floor(d / 6)), d)
	windowsOn(CFrame.new(x - w / 2, cy, z) * CFrame.Angles(0, math.rad(-90), 0),  math.max(2, math.floor(d / 6)), d)

	-- Awning over the front door
	makePart({ parent = g,
		size = Vector3.new(w * 0.35, 0.4, 4),
		position = Vector3.new(x, 5.5, z + d / 2 + 2),
		color = accentColor,
		material = Enum.Material.SmoothPlastic,
	})
	-- Door
	makePart({ parent = g,
		size = Vector3.new(3, 5, 0.4),
		position = Vector3.new(x, 3.5, z + d / 2 + 0.2),
		color = Color3.fromRGB(80, 50, 30),
		material = Enum.Material.Wood,
	})
	return g
end

local function fountain(parent, x, z)
	local g = group("Fountain", parent)
	-- Outer ring (4 quarter walls so we don't need CSG)
	for i = 0, 3 do
		local angle = math.rad(i * 90 + 45)
		makePart({ parent = g,
			size = Vector3.new(12, 2, 3),
			cframe = CFrame.new(x + math.cos(angle) * 6, 1, z + math.sin(angle) * 6) * CFrame.Angles(0, angle, 0),
			color = Color3.fromRGB(180, 175, 160),
			material = Enum.Material.Marble,
		})
	end
	-- Water surface
	makePart({ parent = g,
		size = Vector3.new(11, 1, 11),
		position = Vector3.new(x, 1.5, z),
		color = Color3.fromRGB(80, 160, 220),
		material = Enum.Material.Water,
		transparency = 0.2,
		shadow = false,
	})
	-- Center column with spout
	makePart({ parent = g,
		size = Vector3.new(2, 5, 2),
		position = Vector3.new(x, 3.5, z),
		color = Color3.fromRGB(220, 215, 200),
		material = Enum.Material.Marble,
	})
	local spout = makePart({ parent = g,
		size = Vector3.new(1, 1, 1),
		position = Vector3.new(x, 6.5, z),
		color = Color3.fromRGB(200, 230, 255),
		material = Enum.Material.Neon,
		shape = Enum.PartType.Ball,
		shadow = false,
	})
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(Color3.fromRGB(180, 220, 255))
	emitter.Size = NumberSequence.new(0.5, 0.05)
	emitter.Lifetime = NumberRange.new(0.8, 1.4)
	emitter.Rate = 50
	emitter.Speed = NumberRange.new(8, 14)
	emitter.SpreadAngle = Vector2.new(15, 15)
	emitter.Acceleration = Vector3.new(0, -25, 0)
	emitter.Parent = spout
	return g
end

local function bridge(parent, x, z)
	local g = group("Bridge", parent)
	-- Decking
	makePart({ parent = g,
		size = Vector3.new(20, 1, 8),
		position = Vector3.new(x, 4, z),
		color = Color3.fromRGB(170, 120, 70),
		material = Enum.Material.Wood,
	})
	-- Railings
	for _, dz in ipairs({ -3.5, 3.5 }) do
		makePart({ parent = g,
			size = Vector3.new(20, 1.5, 0.4),
			position = Vector3.new(x, 5.5, z + dz),
			color = Color3.fromRGB(140, 95, 55),
			material = Enum.Material.Wood,
		})
		for i = -2, 2 do
			makePart({ parent = g,
				size = Vector3.new(0.4, 2, 0.4),
				position = Vector3.new(x + i * 4, 5, z + dz),
				color = Color3.fromRGB(140, 95, 55),
				material = Enum.Material.Wood,
			})
		end
	end
	-- Pillars
	for _, dx in ipairs({ -8, 8 }) do
		makePart({ parent = g,
			size = Vector3.new(2, 8, 2),
			position = Vector3.new(x + dx, 0, z),
			color = Color3.fromRGB(120, 90, 60),
			material = Enum.Material.Wood,
		})
	end
end

local function river(parent, x, z, length, width)
	makePart({ parent = parent,
		size = Vector3.new(length, 1, width),
		position = Vector3.new(x, 0, z),
		color = Color3.fromRGB(60, 130, 200),
		material = Enum.Material.Water,
		transparency = 0.25,
		shadow = false,
	})
	-- Banks
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

local function road(parent, x, z, length, width, vertical)
	local sx, sz = vertical and width or length, vertical and length or width
	makePart({ parent = parent,
		size = Vector3.new(sx, 0.4, sz),
		position = Vector3.new(x, 0.5, z),
		color = Color3.fromRGB(70, 70, 75),
		material = Enum.Material.Asphalt,
		shadow = false,
	})
	-- Road stripes
	local stripes = math.floor((vertical and length or length) / 6)
	for i = 1, stripes do
		local off = (i - (stripes + 1) / 2) * 6
		makePart({ parent = parent,
			size = Vector3.new(vertical and 0.4 or 3, 0.45, vertical and 3 or 0.4),
			position = Vector3.new(x + (vertical and 0 or off), 0.55, z + (vertical and off or 0)),
			color = Color3.fromRGB(255, 230, 100),
			material = Enum.Material.SmoothPlastic,
			shadow = false,
		})
	end
end

local function spawnPad(parent, x, z)
	local s = Instance.new("SpawnLocation")
	s.Anchored = true
	s.Size = Vector3.new(8, 1, 8)
	s.Position = Vector3.new(x, 1, z)
	s.Color = Color3.fromRGB(255, 220, 100)
	s.Material = Enum.Material.Neon
	s.Transparency = 0.3
	s.TopSurface = Enum.SurfaceType.Smooth
	s.BottomSurface = Enum.SurfaceType.Smooth
	s.Name = "PlazaSpawn"
	s.Neutral = true
	s.Parent = parent
end

-- Build! --------------------------------------------------------------------
function WorldBuilder.build()
	local existing = Workspace:FindFirstChild(CONTAINER_NAME)
	if existing then existing:Destroy() end
	-- Clear the default Studio baseplate / spawn so they don't z-fight our ground
	for _, name in ipairs({ "Baseplate", "SpawnLocation" }) do
		local existingDefault = Workspace:FindFirstChild(name)
		if existingDefault then existingDefault:Destroy() end
	end
	local container = Instance.new("Folder")
	container.Name = CONTAINER_NAME
	container.Parent = Workspace

	-- Ground (one big green tile + districts on top)
	makePart({ parent = container,
		size = Vector3.new(900, 1, 900),
		position = Vector3.new(0, 0, 0),
		color = Color3.fromRGB(126, 180, 100),
		material = Enum.Material.Grass,
		shadow = false,
		name = "Ground",
	})

	for _, d in ipairs(DISTRICTS) do tile(container, d.x, d.z, d.w, d.d, d.color) end

	-- Roads radiating from the plaza
	road(container, 0, -90,  90, 12, true)   -- north to park
	road(container, 0, 90,   90, 12, true)   -- south toward riverside
	road(container, 90, 0,   90, 12, false)  -- east to vet
	road(container, -90, 0,  90, 12, false)  -- west to suburbs
	road(container, 95, -55, 90, 12, false)  -- to bakery
	road(container, -95, 55, 90, 12, false)  -- to meadow

	-- Plaza
	fountain(container, 0, 0)
	for ang = 0, 270, 90 do
		local rad = math.rad(ang)
		bench(container, math.cos(rad) * 18, math.sin(rad) * 18, ang)
	end
	for ang = 30, 330, 60 do
		local rad = math.rad(ang)
		lamppost(container, math.cos(rad) * 32, math.sin(rad) * 32)
	end
	spawnPad(container, 14, 14)

	-- Park (north)
	for i = 1, 18 do
		tree(container,
			-50 + math.random(0, 100) - math.random(0, 5),
			-220 + math.random(0, 100),
			0.8 + math.random() * 0.6
		)
	end
	for _ = 1, 8 do
		flowerPatch(container, math.random(-50, 50), -250 + math.random(-30, 30))
	end
	bench(container, -25, -150, 0)
	bench(container, 25, -150, 180)
	lamppost(container, -40, -130)
	lamppost(container, 40, -130)
	-- A pond
	makePart({ parent = container,
		size = Vector3.new(40, 1, 28),
		position = Vector3.new(40, 0.6, -200),
		color = Color3.fromRGB(80, 160, 220),
		material = Enum.Material.Water,
		transparency = 0.25,
		shadow = false,
	})

	-- Bakery district (NE) — three storefronts
	building(container, 150, -110, 24, 18, 14, Color3.fromRGB(220, 170, 120), Color3.fromRGB(180, 70, 60),  "Bakery 1")
	building(container, 200, -120, 22, 16, 12, Color3.fromRGB(230, 200, 150), Color3.fromRGB(120, 80, 40),  "Bakery 2")
	building(container, 175, -65,  20, 14, 10, Color3.fromRGB(240, 210, 170), Color3.fromRGB(80, 130, 90),  "Cafe")
	for _ = 1, 5 do
		flowerPatch(container, 130 + math.random(0, 80), -90 + math.random(-30, 30))
	end

	-- Suburbs / Home (NW)
	building(container, -180, -110, 24, 22, 12, Color3.fromRGB(245, 220, 180), Color3.fromRGB(170, 90, 60),  "Your House")
	building(container, -135, -85,  16, 14, 10, Color3.fromRGB(220, 200, 240), Color3.fromRGB(120, 100, 160),"Neighbour A")
	building(container, -225, -130, 18, 16, 11, Color3.fromRGB(200, 230, 200), Color3.fromRGB(80, 140, 100), "Neighbour B")
	for x = -240, -130, 30 do
		tree(container, x, -50, 1)
	end

	-- Meadow / dig area (SW)
	for i = 1, 20 do
		flowerPatch(container, -250 + math.random(0, 110), 60 + math.random(0, 110))
	end
	for i = 1, 6 do
		bush(container, -240 + math.random(0, 100), 70 + math.random(0, 100))
	end
	-- Wooden fence
	for x = -260, -130, 8 do
		makePart({ parent = container,
			size = Vector3.new(0.4, 4, 0.4),
			position = Vector3.new(x, 2, 50),
			color = Color3.fromRGB(160, 110, 70),
			material = Enum.Material.Wood,
		})
	end

	-- Vet / Shelter district (E)
	building(container, 210, 50, 30, 24, 14, Color3.fromRGB(220, 240, 250), Color3.fromRGB(80, 130, 200),  "Vet Hospital")
	building(container, 165, 85, 18, 14, 10, Color3.fromRGB(240, 240, 240), Color3.fromRGB(160, 60, 60),   "Shelter")
	for _ = 1, 6 do
		flowerPatch(container, 170 + math.random(0, 60), 30 + math.random(0, 50))
	end

	-- Riverside (south) — river, bridge, fishermen path
	river(container, 0, 200, 360, 24)
	bridge(container, 0, 200)
	for _ = 1, 8 do
		bush(container, math.random(-160, 160), 230 + math.random(-10, 10))
	end
	-- Lamps along the bridge
	lamppost(container, -10, 190)
	lamppost(container, 10, 210)

	-- Atmosphere / lighting -------------------------------------------------
	Lighting.ClockTime = 14
	Lighting.Brightness = 2
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 160, 170)
	Lighting.Ambient = Color3.fromRGB(70, 70, 90)
	Lighting.GlobalShadows = true
	Lighting.FogStart = 200
	Lighting.FogEnd = 1000
	Lighting.FogColor = Color3.fromRGB(180, 200, 220)

	-- Atmosphere instance for soft sky haze
	local atm = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atm.Density = 0.35
	atm.Offset = 0.1
	atm.Color = Color3.fromRGB(199, 215, 230)
	atm.Decay = Color3.fromRGB(106, 112, 125)
	atm.Glare = 0.2
	atm.Haze = 1.6
	atm.Parent = Lighting

	-- Sky
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

function WorldBuilder.districtCenter(name)
	for _, d in ipairs(DISTRICTS) do
		if d.name == name then return Vector3.new(d.x, 0, d.z) end
	end
	return Vector3.new(0, 0, 0)
end

return WorldBuilder
