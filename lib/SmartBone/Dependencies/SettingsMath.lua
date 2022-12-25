local function Clamp(min, max)
	return function(value)
		return math.clamp(value, min, max)
	end
end

local function Floor(value)
	return math.floor(value)
end

local function Offset(offset)
	return function(value)
		return value + offset
	end
end

return {
	Damping = Clamp(0, 1),
	AnchorDepth = Floor,
	Stiffness = Clamp(0, 1),
	Inertia = Clamp(0, 1),
	Elasticity = Clamp(0, 1),
	BlendWeight = Clamp(0, 1),
	UpdateRate = Clamp(0, 165),
	WindStrength = Clamp(0, 10),

	Gravity = Offset(Vector3.new(0, -0.01, 0)),
}
