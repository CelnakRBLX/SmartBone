local WIND_SEED = 1029410295159813
local WIND_RNG = Random.new(WIND_SEED)

local module = {}
module.__index = module

function module.new(Root: Bone, RootPart: Instance, Gravity: Vector3)
	return setmetatable({
		WindOffset = WIND_RNG:NextNumber(0, 1000000),
		Root = Root:IsA("Bone") and Root or nil,
		RootPart = RootPart,
		RootWorldToLocal = Root.WorldCFrame:ToObjectSpace(Root.CFrame),
		BoneTotalLength = 0,
		DistanceFromCamera = 100,
		Particles = {},

		LocalCFrame = Root.WorldCFrame,
		LocalGravity = Root.CFrame:PointToWorldSpace(Gravity).Unit * Gravity.Magnitude,
		Force = Vector3.zero,
		RestGravity = Vector3.zero,
		ObjectMove = Vector3.zero,
		ObjectPreviousPosition = Vector3.zero,
	}, module)
end

return module
