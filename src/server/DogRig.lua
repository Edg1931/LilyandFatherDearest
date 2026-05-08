local DogBreeds = require(game.ReplicatedStorage.Shared.DogBreeds)

local DogRig = {}

local SIZE_SCALE = DogBreeds.SIZE_SCALE

local function makePart(props)
	local p = Instance.new("Part")
	p.Anchored = props.anchored == nil and true or props.anchored
	p.CanCollide = props.collide == true
	p.CastShadow = props.shadow ~= false
	p.Material = props.material or Enum.Material.SmoothPlastic
	p.Size = props.size
	p.Color = props.color or Color3.new(1, 1, 1)
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if props.cframe then p.CFrame = props.cframe
	elseif props.position then p.Position = props.position end
	if props.shape then p.Shape = props.shape end
	if props.parent then p.Parent = props.parent end
	if props.transparency then p.Transparency = props.transparency end
	return p
end

local function bodyDimensions(shape, scale)
	-- Returns body length, width, height as vectors before scale.
	if shape == "compact" then
		return Vector3.new(2.4, 1.6, 1.6) * scale
	elseif shape == "lean" then
		return Vector3.new(3.4, 1.4, 1.3) * scale
	elseif shape == "stocky" then
		return Vector3.new(3.0, 1.9, 1.9) * scale
	elseif shape == "long" then
		return Vector3.new(4.4, 1.2, 1.3) * scale
	elseif shape == "barrel" then
		return Vector3.new(3.0, 2.1, 2.2) * scale
	end
	return Vector3.new(3.0, 1.6, 1.6) * scale
end

local function ear(parent, headPosition, side, kind, scale, color)
	local s = side == "left" and 1 or -1
	if kind == "pointy" then
		local ear = makePart({ parent = parent, color = color,
			size = Vector3.new(0.3, 0.9, 0.6) * scale,
			cframe = CFrame.new(headPosition + Vector3.new(0, 0.7, s * 0.45) * scale) * CFrame.Angles(0, 0, math.rad(s * -10)),
		})
	elseif kind == "floppy" then
		makePart({ parent = parent, color = color,
			size = Vector3.new(0.4, 1.4, 0.7) * scale,
			cframe = CFrame.new(headPosition + Vector3.new(0, -0.1, s * 0.55) * scale) * CFrame.Angles(0, 0, math.rad(s * 35)),
		})
	else  -- small
		makePart({ parent = parent, color = color,
			size = Vector3.new(0.3, 0.5, 0.5) * scale,
			cframe = CFrame.new(headPosition + Vector3.new(0, 0.5, s * 0.4) * scale),
		})
	end
end

local function tail(parent, bodyEnd, kind, scale, color)
	if kind == "curly" then
		makePart({ parent = parent, color = color,
			size = Vector3.new(0.5, 1.1, 0.5) * scale,
			cframe = CFrame.new(bodyEnd + Vector3.new(-0.4, 0.6, 0) * scale) * CFrame.Angles(0, 0, math.rad(40)),
		})
	elseif kind == "fluffy" then
		makePart({ parent = parent, color = color,
			size = Vector3.new(1.0, 0.8, 0.8) * scale,
			cframe = CFrame.new(bodyEnd + Vector3.new(-0.5, 0.4, 0) * scale),
		})
	elseif kind == "stub" then
		makePart({ parent = parent, color = color,
			size = Vector3.new(0.4, 0.4, 0.4) * scale,
			cframe = CFrame.new(bodyEnd + Vector3.new(-0.3, 0.2, 0) * scale),
		})
	else  -- straight
		makePart({ parent = parent, color = color,
			size = Vector3.new(1.4, 0.4, 0.4) * scale,
			cframe = CFrame.new(bodyEnd + Vector3.new(-0.8, 0.4, 0) * scale) * CFrame.Angles(0, 0, math.rad(-15)),
		})
	end
end

local function applyPattern(parent, body, pattern, primary, secondary, scale)
	if pattern == "solid" then return end
	if pattern == "spotted" then
		for _ = 1, 6 do
			local rx = (math.random() - 0.5) * body.Size.X * 0.7
			local ry = (math.random() - 0.5) * body.Size.Y * 0.6
			local rz = (math.random() - 0.5) * body.Size.Z * 0.7
			makePart({ parent = parent, color = secondary,
				size = Vector3.new(0.5, 0.5, 0.5) * scale,
				position = body.Position + Vector3.new(rx, ry, rz),
				shadow = false,
			})
		end
	elseif pattern == "patched" then
		for _ = 1, 3 do
			local rx = (math.random() - 0.5) * body.Size.X * 0.6
			makePart({ parent = parent, color = secondary,
				size = Vector3.new(body.Size.X * 0.35, body.Size.Y * 0.7, body.Size.Z * 0.7),
				position = body.Position + Vector3.new(rx, body.Size.Y * 0.1 * (math.random(-1, 1)), 0),
				shadow = false,
			})
		end
	elseif pattern == "brindled" then
		for i = 1, 5 do
			local off = (i - 3) * body.Size.X / 6
			makePart({ parent = parent, color = secondary,
				size = Vector3.new(body.Size.X * 0.08, body.Size.Y * 0.95, body.Size.Z * 1.02),
				position = body.Position + Vector3.new(off, 0, 0),
				shadow = false,
			})
		end
	end
end

-- Build a breed-specific dog model anchored at `position` (the dog's feet).
-- Returns the model and the body part (use this as the movement handle).
function DogRig.build(breedId, position, parent)
	local def = DogBreeds.BY_ID[breedId]
	if not def then return nil end

	local scale = SIZE_SCALE[def.size] or 1
	local bodyDims = bodyDimensions(def.shape, scale)
	local primary = def.primary
	local secondary = def.secondary or primary

	local model = Instance.new("Model")
	model.Name = "Dog_" .. breedId
	model.Parent = parent

	-- Body
	local bodyY = bodyDims.Y * 0.5 + 1.0 * scale  -- legs add height
	local body = makePart({ parent = model, color = primary,
		size = bodyDims,
		position = position + Vector3.new(0, bodyY, 0),
		material = Enum.Material.SmoothPlastic,
		collide = true,
	})
	model.PrimaryPart = body

	-- Underbelly accent (lighter)
	makePart({ parent = model,
		color = Color3.new(
			math.min(1, primary.R + 0.15),
			math.min(1, primary.G + 0.15),
			math.min(1, primary.B + 0.15)
		),
		size = Vector3.new(bodyDims.X * 0.85, bodyDims.Y * 0.4, bodyDims.Z * 1.01),
		position = body.Position + Vector3.new(0, -bodyDims.Y * 0.25, 0),
		shadow = false,
	})

	-- Pattern overlays
	applyPattern(model, body, def.pattern, primary, secondary, scale)

	-- Head
	local headOff = bodyDims.X * 0.5 + 0.5 * scale
	local headSize = Vector3.new(1.4, 1.3, 1.3) * scale
	if def.shape == "compact" then headSize = Vector3.new(1.5, 1.5, 1.4) * scale end
	if def.shape == "long" then headSize = Vector3.new(1.2, 1.0, 1.0) * scale end
	if def.size == "giant" then headSize = headSize * 1.1 end
	local head = makePart({ parent = model, color = primary,
		size = headSize,
		position = body.Position + Vector3.new(headOff, headSize.Y * 0.4, 0),
	})
	-- Snout (longer for hounds, shorter for compact)
	local snoutLen = (def.shape == "compact") and 0.5 or (def.shape == "long" and 0.9 or 0.8)
	local snout = makePart({ parent = model, color = primary,
		size = Vector3.new(snoutLen, headSize.Y * 0.55, headSize.Z * 0.7) * scale * 0.95 + Vector3.new(0, 0, 0),
		position = head.Position + Vector3.new(headSize.X * 0.5, -headSize.Y * 0.1, 0),
	})
	-- Nose
	makePart({ parent = model, color = Color3.fromRGB(28, 24, 22),
		size = Vector3.new(0.35, 0.35, 0.35) * scale,
		position = snout.Position + Vector3.new(snout.Size.X * 0.5, 0.1, 0),
		shape = Enum.PartType.Ball,
	})
	-- Eyes
	for _, sZ in ipairs({ -1, 1 }) do
		makePart({ parent = model, color = Color3.fromRGB(20, 20, 25),
			size = Vector3.new(0.2, 0.25, 0.25) * scale,
			position = head.Position + Vector3.new(headSize.X * 0.25, headSize.Y * 0.15, sZ * headSize.Z * 0.32),
			shape = Enum.PartType.Ball,
		})
	end
	-- Ears
	ear(model, head.Position, "left",  def.ears, scale, primary)
	ear(model, head.Position, "right", def.ears, scale, primary)

	-- Tail
	tail(model, body.Position + Vector3.new(-bodyDims.X * 0.5, 0, 0), def.tail, scale, primary)

	-- Legs (4)
	local legHeight = 1.0 * scale
	local legOffsetX = bodyDims.X * 0.32
	local legOffsetZ = bodyDims.Z * 0.42
	for _, dx in ipairs({ -1, 1 }) do
		for _, dz in ipairs({ -1, 1 }) do
			makePart({ parent = model, color = primary,
				size = Vector3.new(0.5, legHeight, 0.5) * scale,
				position = body.Position + Vector3.new(dx * legOffsetX, -bodyDims.Y * 0.5 - legHeight * 0.5, dz * legOffsetZ),
			})
		end
	end

	return model, body
end

return DogRig
