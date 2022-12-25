local module = {}
module.__index = module

function module.new(Bone: Bone, RootBone: Bone, RootPart: BasePart, Settings: any)
	return setmetatable({
		Bone = Bone,
		RestLength = 0,
		Weight = 1 * 0.7,
		ParentIndex = 0,
		Transform = Bone.WorldCFrame:ToObjectSpace(RootBone.WorldCFrame):Inverse(),
		LocalTransform = Bone.CFrame:ToObjectSpace(RootBone.CFrame):Inverse(),
		RootTransform = RootBone.WorldCFrame:ToObjectSpace(RootPart.CFrame):Inverse(),
		Radius = Settings.Radius,
		IsColliding = false,

		TransformOffset = CFrame.identity,
		LastTransformOffset = CFrame.identity,
		LocalTransformOffset = CFrame.identity,
		RestPosition = Vector3.zero,
		BoneTransform = CFrame.identity,
		CalculatedWorldCFrame = Bone.WorldCFrame,
		CalculatedWorldPosition = Bone.WorldPosition,

		Position = Bone.WorldPosition,
		LastPosition = Bone.WorldPosition,
		Anchored = false,
		RecyclingBin = {},
	}, module)
end

return module
