--[[ SmartBone Version 0.1.0 by Celnak ]] --

-- // Types \\ --

type func = () -> ()
type dictionary = { [string]: any }
type array = { [number]: any }

type rootList = {
	[number]: Bone
}
type particle = {
	Bone: Bone,
	RestLength: number,
	Weight: number,
	ParentIndex: number,
	Transform: CFrame,
	LocalTransform: CFrame,
	RootTransform: CFrame,
	Radius: number,
	IsColliding: boolean,

	TransformOffset: CFrame,
	LastTransformOffset: CFrame,
	LocalTransformOffset: CFrame,
	RestPosition: Vector3,
	BoneTransform: CFrame,
	CalculatedWorldCFrame: CFrame,
	CalculatedWorldPosition: Vector3,

	Position: Vector3,
	LastPosition: Vector3,
	Anchored: boolean,
	RecyclingBin: any,
}
type particleArray = {
	[number]: particle
}
type particleTree = {
	WindOffset: number,
	Root: Bone | nil,
	RootPart: BasePart,
	RootWorldToLocal: Vector3,
	BoneTotalLength: number,
	Particles: particleArray,
	LocalCFrame: CFrame,
	LocalGravity: Vector3,
	Force: Vector3,
	RestGravity: Vector3,
	ObjectMove: Vector3,
	ObjectPreviousPosition: Vector3,
}

-- // Services \\ --

local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

if not RunService:IsClient() then 
	warn("Attempted to initialize SmartBone on Server.") 
	return nil
end

-- // Constructors \\ --

local ZERO = Vector3.zero

-- // Dependencies \\ --

local Config = require(script.Dependencies.Config)

local UnitConversion = require(script.Dependencies.UnitConversion)
local DefaultSettings = require(script.Dependencies.DefaultSettings)

local ParticleTree = require(script.Components.ParticleTree)
local Particle = require(script.Components.Particle)

local SettingsMath = require(script.Dependencies.SettingsMath)
local Utilities = require(script.Dependencies.Utilities)

local ID_SEED = 12098135901304
local ID_RANDOM = Random.new(ID_SEED)

local SmartBoneTags = CollectionService:GetTagged("SmartBone")

-- // Debug \\ --

local DEBUG = Config.Debug
local DEBUG_FOLDER, DEBUG_HIGHLIGHT

if DEBUG then
	DEBUG_FOLDER = Instance.new("Model")
	DEBUG_FOLDER.Name = "SMARTBONE_DEBUGFOLDER"
	DEBUG_FOLDER.Parent = workspace

	DEBUG_HIGHLIGHT = Instance.new("Highlight")
	DEBUG_HIGHLIGHT.FillColor = Color3.fromRGB(255, 0, 0)
	DEBUG_HIGHLIGHT.OutlineTransparency = 1
	DEBUG_HIGHLIGHT.FillTransparency = 0
	DEBUG_HIGHLIGHT.Parent = DEBUG_FOLDER
	DEBUG_HIGHLIGHT.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	DEBUG_HIGHLIGHT.Enabled = true
end

-- // Module \\ --

local CurrentControllers = {}
local module = {}
module.__index = module

function module.new(rootPart: BasePart, rootList: array)
	local self = setmetatable({
		ID = ID_RANDOM:NextInteger(1, 10000000),
		RootPart = rootPart,
		Time = 0,
		ParticleTrees = {},
		Connections = {},
		RootList = rootList,
		ObjectScale = UnitConversion.Convert(math.abs(rootPart.Size.X), "Millimeter"),
		WindPreviousPosition = Vector3.zero,
		Removed = false,
		RemovedEvent = Instance.new("BindableEvent"),
		InRange = false,

		Settings = {},
	}, module)

	for name, value in DefaultSettings do
		self.Settings[name] = rootPart:GetAttribute(name) or value
	end

	self.Settings.BlendWeight = 1
	self.Settings.UpdateRate = math.floor(self.Settings.UpdateRate + 0.1)

	self:Init()

	return self
end

function module:Init()
	local RootPart = self.RootPart

	local tailBone, start

	CurrentControllers[self.ID] = self

	self.Connections["AttributeChanged"] = RootPart.AttributeChanged:ConnectParallel(function(Attribute: string)
		self:UpdateParameters(Attribute, RootPart:GetAttribute(Attribute))
	end)

	self.Connections["LightingAttributeChanged"] = Lighting.AttributeChanged:ConnectParallel(function(Attribute: string)
		self:UpdateParameters(Attribute, Lighting:GetAttribute(Attribute))
	end)

	for _, Bone in RootPart:GetDescendants() do
		if Bone:IsA("Bone") and Bone.Parent:IsA("Bone") and #Bone:GetChildren() == 0 then
			start = Bone.WorldCFrame
				+ (Bone.WorldCFrame.UpVector.Unit * (Bone.WorldPosition - Bone.Parent.WorldPosition).Magnitude)
			tailBone = Instance.new("Bone")
			tailBone.Parent = Bone
			tailBone.Name = Bone.Name .. "_Tail"
			tailBone.WorldCFrame = start
		end
	end

	for _, Root in self.RootList do
		self:AppendParticleTree(Root)
	end

	for _, particleTree in self.ParticleTrees do
		self:AppendParticles(particleTree, particleTree.Root, 0, 0)
	end
end

function module:AppendParticleTree(Root: Bone)
	table.insert(self.ParticleTrees, ParticleTree.new(Root, self.RootPart, self.Settings.Gravity))
end

function module:AppendParticles(particleTree: dictionary, Bone: Bone, ParentIndex: number, BoneLength: number)
	local Settings = self.Settings

	local particle: particle = Particle.new(Bone, particleTree.Root, self.RootPart, Settings)
	particle.Position, particle.LastPosition = Bone.WorldPosition, Bone.WorldPosition
	particle.ParentIndex = ParentIndex
	particle.BoneLength = BoneLength
	particle.HeirarchyLength = 0

	if ParentIndex >= 1 then
		BoneLength = (particleTree.Particles[ParentIndex].Bone.WorldPosition - particle.Position).Magnitude
		particle.BoneLength = BoneLength
		particle.Weight = (BoneLength * 0.7)
		particle.HeirarchyLength = Utilities.GetHierarchyLength(Bone, particleTree.Root)
	end

	if particle.HeirarchyLength <= Settings.AnchorDepth then
		particle.Anchored = true
	end

	table.insert(particleTree.Particles, particle)

	local index = #particleTree.Particles
	local boneChildren = Bone:GetChildren()

	local child

	for i = 1, #boneChildren do
		child = boneChildren[i]
		if child:IsA("Bone") then
			self:AppendParticles(particleTree, child, index, BoneLength)
		end
	end
end

function module:UpdateParameters(setting, value)
	self.Settings[setting] = if SettingsMath[setting] then SettingsMath[setting](value) else value
end

function module:PreUpdate(particleTree: particleTree)
	local rootPart = particleTree.RootPart
	local root = particleTree.Root

	particleTree.DistanceFromCamera = (rootPart.Position - workspace.CurrentCamera.CFrame.Position).Magnitude
	particleTree.ObjectMove = rootPart.Position - particleTree.ObjectPreviousPosition
	particleTree.ObjectPreviousPosition = rootPart.Position
	particleTree.RestGravity = root.CFrame:PointToWorldSpace(particleTree.LocalGravity)

	for _, particle in particleTree.Particles do
		particle.LastTransformOffset = particle.TransformOffset
		if particle.Bone == particle.Root then
			particle.TransformOffset = rootPart.CFrame * particle.RootTransform
		else
			particle.TransformOffset = root.WorldCFrame * particle.Transform
		end
		particle.LocalTransformOffset = root.CFrame * particle.LocalTransform
	end
end

function module:UpdateParticles(particleTree: particleTree, Delta: number, LoopIndex: number)
	local Settings = self.Settings

	local Damping = Settings.Damping
	local Force = Settings.Gravity
	local ForceDirection = Settings.Gravity.Unit

	local ProjectedForce = ForceDirection * math.max(particleTree.RestGravity:Dot(ForceDirection), 0)

	Force -= ProjectedForce
	Force = (Force + Settings.Force) * (self.ObjectScale * Delta)

	local ObjectMove = LoopIndex == 0 and particleTree.ObjectMove or ZERO

	local windMove, velocity, move
	local timeModifier

	for _, particle in particleTree.Particles do
		if particle.ParentIndex >= 1 and particle.Anchored == false then
			windMove = ZERO

			if Settings.WindInfluence > 0 then
				timeModifier = particleTree.WindOffset
					+ (os.clock() - (particle.HeirarchyLength / 5))
					+ (
						((particle.TransformOffset.Position - particleTree.Root.WorldPosition).Magnitude / 5)
						* Settings.WindInfluence
					)
				windMove = Vector3.new(
					Settings.WindDirection.X
						+ (Settings.WindDirection.X * (math.sin(timeModifier * Settings.WindSpeed))),
					Settings.WindDirection.Y + (0.05 * (math.sin(timeModifier * Settings.WindSpeed))),
					Settings.WindDirection.Z
						+ (Settings.WindDirection.X * (math.sin(timeModifier * Settings.WindSpeed)))
				)

				windMove /= particle.BoneLength
				windMove *= Settings.WindInfluence
				windMove *= (Settings.WindStrength / 100) * (math.clamp(particle.HeirarchyLength, 1, 10) / 10)
				windMove *= particle.Weight
				self.WindPreviousPosition = windMove
			end

			velocity = (particle.Position - particle.LastPosition)
			move = (ObjectMove * Settings.Inertia)

			-- // WIP \\ --

			--[[if particle.IsColliding then
				Damping += particle.Friction
				if Damping > 1 then
					Damping = 1
				end
			end]]
			--

			particle.LastPosition = particle.Position + move
			particle.Position += velocity * (1 - Damping) + Force + move + windMove
		else
			particle.LastPosition = particle.Position
			particle.Position = particle.TransformOffset.Position
		end
	end
end

function module:CorrectParticles(particleTree: particleTree, Delta: number)
	local Settings = self.Settings
	local stiffness = Settings.Stiffness

	local parentPoint
	local restLength, difference, length
	local mat, restPosition, maxLength

	for _, point in particleTree.Particles do
		parentPoint = particleTree.Particles[point.ParentIndex]

		if parentPoint and point.ParentIndex >= 1 and point.Anchored == false then
			restLength = (parentPoint.TransformOffset.Position - point.TransformOffset.Position).Magnitude

			if stiffness > 0 or Settings.Elasticity > 0 then
				mat = CFrame.new(parentPoint.Position) * parentPoint.TransformOffset.Rotation
				restPosition = (mat * CFrame.new(point.LocalTransformOffset.Position)).Position

				difference = restPosition - point.Position
				point.Position += difference * (Settings.Elasticity * Delta)

				if stiffness > 0 then
					difference = restPosition - point.Position
					length = difference.Magnitude
					maxLength = restLength * (1 - stiffness) * 2
					if length > maxLength then
						point.Position += difference * ((length - maxLength) / length)
					end
				end
			end

			difference = parentPoint.Position - point.Position
			length = difference.Magnitude
			if length > 0 then
				point.Position += difference * ((length - restLength) / length)
			end
		end
	end
end

function module:SkipUpdateParticles(particleTree: particleTree)
	local parentPoint, restLength, stiffness
	local restPosition, difference, length, maxLength

	for _, point in particleTree.Particles do
		if point.ParentIndex >= 1 and not point.Anchored then
			point.LastPosition += particleTree.ObjectMove
			point.Position += particleTree.ObjectMove

			parentPoint = particleTree.Particles[point.ParentIndex]
			restLength = (parentPoint.TransformOffset.Position - point.TransformOffset.Position).Magnitude
			stiffness = self.Settings.Stiffness

			if stiffness > 0 then
				restPosition = parentPoint.Position
					+ CFrame.lookAt(parentPoint.Position, point.Position).LookVector.Unit
						* (parentPoint.Position - point.Position).Magnitude

				difference = restPosition - point.Position
				length = difference.Magnitude
				maxLength = restLength * (1 - stiffness) * 2
				if length > maxLength then
					point.Position += difference * ((length - maxLength) / length)
				end
			end

			difference = parentPoint.Position - point.Position
			length = difference.Magnitude
			if length > restLength then
				point.Position += difference * ((length - restLength) / length)
			end
		else
			point.LastPosition = point.TransformOffset.Position
			point.Position = point.TransformOffset.Position
		end
	end
end

function module:CalculateTransforms(particleTree: particleTree, Delta: number)
	if self.InRange then
		local parentPoint, boneParent, bone
		local localPosition, referenceCFrame, v0, v1, rotation, factor, alpha

		for _, point in particleTree.Particles do
			if point.ParentIndex >= 1 and point.Anchored == false then
				parentPoint = particleTree.Particles[point.ParentIndex]
				boneParent = parentPoint.Bone
				bone = point.Bone

				if parentPoint and boneParent and boneParent:IsA("Bone") and boneParent ~= particleTree.Root then
					localPosition = parentPoint.LocalTransformOffset.Position
					referenceCFrame = parentPoint.TransformOffset
					v0 = referenceCFrame:PointToObjectSpace(localPosition)
					v1 = point.Position - parentPoint.Position
					rotation = Utilities.GetRotationBetween(referenceCFrame.UpVector, v1, v0).Rotation
						* referenceCFrame.Rotation

					factor = 0.0000001
					alpha = (1 - factor ^ Delta)

					parentPoint.CalculatedWorldCFrame =
						boneParent.WorldCFrame:Lerp(CFrame.new(parentPoint.Position) * rotation, alpha)
					point.CalculatedWorldPosition = Utilities.Lerp(bone.WorldPosition, point.Position, alpha)
				end
			end
		end
	end
end

function module:TransformBones(particleTree: particleTree)
	local parentPoint, boneParent

	if self.InRange then
		for _, point in particleTree.Particles do
			if point.ParentIndex >= 1 and point.Anchored == false then
				parentPoint = particleTree.Particles[point.ParentIndex]
				boneParent = parentPoint.Bone

				if parentPoint and boneParent and boneParent:IsA("Bone") and boneParent ~= particleTree.Root then
					if parentPoint.Anchored and self.Settings.AnchorsRotate == false then
						boneParent.WorldCFrame = parentPoint.TransformOffset
					else
						boneParent.WorldCFrame = parentPoint.CalculatedWorldCFrame
					end
				end
			end
		end
	end
end

function module:DEBUG(particleTree: particleTree)
	for _, point in particleTree.Particles do
		if point then
			point.DebugPart.CFrame = CFrame.new(point.Position) * point.TransformOffset.Rotation
		end
	end
end

function module:RunLoop(particleTree: particleTree, Delta: number)
	local UpdateRate = self.Settings.UpdateRate
	local loop = 1
	local timeVar = (1 / UpdateRate)

	if UpdateRate > 0 then
		local frameTime = 1 / UpdateRate
		self.Time += Delta
		loop = 0

		while self.Time >= frameTime do
			loop += 1
			if loop >= 3 then
				self.Time = 0
				break
			end
		end
	end

	if loop > 0 then
		for i = 0, loop do
			self:UpdateParticles(particleTree, timeVar, i)
			self:CorrectParticles(particleTree, timeVar)
		end
	else
		self:SkipUpdateParticles(particleTree)
	end
end

function module:ResetParticles(particleTree: particleTree)
	for _, point in particleTree.Particles do
		point.LastPosition = point.TransformOffset.Position
		point.Position = point.TransformOffset.Position
	end
end

function module:ResetTransforms(particleTree: particleTree)
	local transformOffset

	for _, point in particleTree.Particles do
		if point.Bone == point.Root then
			transformOffset = particleTree.RootPart.CFrame * point.RootTransform
		else
			transformOffset = particleTree.Root.WorldCFrame * point.Transform
		end

		point.Bone.WorldCFrame = transformOffset
	end
end

function module:UpdateBones(Delta: number)
	for _, particleTree: particleTree in self.ParticleTrees do
		self:PreUpdate(particleTree)
		self:RunLoop(particleTree, Delta)

		if DEBUG then
			self:DEBUG(particleTree, Delta)
		end

		self:CalculateTransforms(particleTree, Delta)
	end
end

function module.Start()
	local Player = game.Players.LocalPlayer

	local ActorsFolder = Instance.new("Folder")
	ActorsFolder.Name = "Actors"
	ActorsFolder.Parent = Player:WaitForChild("PlayerScripts")

	local function DebugPrint(String: string)
		if DEBUG then
			warn(String)
		end
	end

	local SmartBones = {}
	local IgnoreList = {}

	local function registerSmartBoneObject(Object: BasePart)
		if
			Object:IsA("BasePart")
			and Utilities.WaitForChildOfClass(Object, "Bone", 3)
			and game.Workspace:IsAncestorOf(Object)
		then
			local RootList = {}

			if
				Object:GetAttribute("Roots")
				and Object:GetAttribute("Roots") ~= nil
				and typeof(Object:GetAttribute("Roots")) == "string"
			then
				local list = string.split(Object:GetAttribute("Roots"), ",")
				for _, value in ipairs(list) do
					local Bone = Object:FindFirstChild(value, true)
					if Bone and Bone:IsA("Bone") then
						table.insert(RootList, Bone)
					end
				end
			end

			if #RootList > 0 then
				local SmartBoneActor = Instance.new("Actor")

				local Event = Instance.new("BindableFunction")
				Event.Name = "Event"
				Event.Parent = SmartBoneActor

				local RuntimeScript = script.Dependencies.ActorScript:Clone()
				RuntimeScript.Name = "Runtime"
				RuntimeScript.Parent = SmartBoneActor

				SmartBoneActor.Parent = ActorsFolder

				RuntimeScript.Enabled = true

				SmartBones[Object] = SmartBoneActor.Event:Invoke(Object, RootList)

				SmartBoneActor.Name = Object.Name .. SmartBones[Object].ID

				SmartBones[Object].RemovedEvent.Event:Once(function()
					SmartBoneActor.Runtime.Enabled = false
					SmartBoneActor:Destroy()
				end)

				table.insert(IgnoreList, Object)
				DebugPrint("Created new SmartBone Object with ID: " .. SmartBones[Object].ID)
			else
				table.insert(IgnoreList, Object)
				DebugPrint(
					"Failed to create SmartBone Object for "
						.. Object:GetFullName()
						.. "! Make sure you have defined the Root Bone(s) for this object!"
				)
			end
		end
	end

	local function removeSmartBoneObject(Object: BasePart)
		if SmartBones[Object] then
			DebugPrint("Removing SmartBone Object with ID: " .. SmartBones[Object].ID)
			task.spawn(function()
				for _, Connection in pairs(SmartBones[Object].Connections) do
					Connection:Disconnect()
				end

				SmartBones[Object].SimulationConnection:Disconnect()

				task.wait()

				SmartBones[Object].RemovedEvent:Destroy()

				for _, particleTree: particleTree in ipairs(SmartBones[Object].ParticleTrees) do
					for _, _Particle in particleTree.Particles do
						for _, Recycling in _Particle.RecyclingBin do
							Recycling:Destroy()
						end
					end
				end

				task.wait()

				if CurrentControllers[SmartBones[Object].ID] then
					CurrentControllers[SmartBones[Object].ID] = nil
				end

				SmartBones[Object].Removed = true
				SmartBones[Object].RemovedEvent:Fire()

				SmartBones[Object] = nil
			end)
		end
	end

	CollectionService:GetInstanceAddedSignal("SmartBone"):Connect(registerSmartBoneObject)
	CollectionService:GetInstanceRemovedSignal("SmartBone"):Connect(removeSmartBoneObject)

	for _, Object in pairs(SmartBoneTags) do
		if not SmartBones[Object] and not table.find(IgnoreList, Object) then
			task.spawn(function()
				registerSmartBoneObject(Object)
			end)
		end
	end
end

return module