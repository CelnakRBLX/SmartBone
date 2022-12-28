if not script.Parent:IsA("Actor") then return end

-- // Types \\ --

type dictionary = { [string]: any }
type array = { [number]: any }

-- // Objects \\ --

local Event = script.Parent.Event

-- // Services \\ --

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // Dependencies \\ --

local Paths = {
	ReplicatedStorage,
	Players.LocalPlayer:WaitForChild("PlayerScripts"),
}
local Module
for _,service in pairs(Paths) do
	local found = service:FindFirstChild("SmartBone", true)
	if found and found:IsA("ModuleScript") then
		Module = found
		break
	end
end
if not Module then
	warn("SmartBone was not found!")
	return
end

local Dependencies = Module:WaitForChild("Dependencies")
local Config = require(Dependencies:WaitForChild("Config"))

local SmartBone = require(Module)
local CameraUtil = require(Dependencies:WaitForChild("CameraUtil"))


local DEBUG = Config.Debug

local timeFunc = os.clock
local oldTime = timeFunc()
local frameRate = 60
local frameRateTable = {}

--[[ Local Functions ]] --

local round = 1000

local function roundNumber(num)
	return  math.floor((num * round) + 0.5) / round
end

local function smoothDelta()
	local currentTime = timeFunc()

	for index = #frameRateTable,1,-1 do
		frameRateTable[index + 1] = (frameRateTable[index] >= currentTime - 1) and frameRateTable[index] or nil
	end

	frameRateTable[1] = currentTime
	frameRate =  math.floor((timeFunc() - oldTime >= 1 and #frameRateTable) or (#frameRateTable / (timeFunc() - oldTime)))

	return roundNumber(frameRate * ((1/frameRate)^2) + .001)
end

local function Initialize(Object: BasePart, RootList: array)
	local SBone = SmartBone.new(Object, RootList)

	local frameTime = 0

	SBone.SimulationConnection = RunService.Heartbeat:ConnectParallel(function(Delta: number)
		Delta = smoothDelta()
		frameTime += Delta

		local camPosition = workspace.CurrentCamera.CFrame.Position
		local rootPosition = SBone.RootPart.Position
		local throttleDistance = SBone.Settings.ThrottleDistance
		local distance = (camPosition - rootPosition).Magnitude
		local activationDistance = SBone.Settings.ActivationDistance

		local updateDistance = math.clamp(distance - throttleDistance, 0, activationDistance)
		local updateThrottle = 1 - math.clamp(updateDistance / activationDistance, 0, 1)

		local UpdateRate = math.floor(math.clamp(updateThrottle * SBone.Settings.UpdateRate, 1, SBone.Settings.UpdateRate))

		local WithinViewport = CameraUtil.WithinViewport(SBone.RootPart)
		if frameTime >= (1/UpdateRate) then
			if distance < activationDistance and WithinViewport then
				Delta = frameTime
				frameTime = 0

				debug.profilebegin("SoftBone")

				if SBone.InRange == false then
					SBone.InRange = true
				end
				
				SBone:UpdateBones(Delta, UpdateRate)

				debug.profileend()

				task.synchronize()

				debug.profilebegin("SoftBoneTransform")
				
				for _, _ParticleTree in SBone.ParticleTrees do
					SBone:TransformBones(_ParticleTree, Delta)
					if DEBUG then
						SBone:DEBUG(_ParticleTree, Delta)
					end
				end

				debug.profileend()

				task.desynchronize()
				
			else
				if SBone.InRange == true then
					SBone.InRange = false

					for _, _ParticleTree in SBone.ParticleTrees do
						SBone:ResetParticles(_ParticleTree)
					end

					task.synchronize()

					for _, _ParticleTree in SBone.ParticleTrees do
						SBone:ResetTransforms(_ParticleTree, Delta)
					end

					task.desynchronize()
				end
			end
		end
	end)

	return SBone
end

--[[ Event Handler ]]--

Event.OnInvoke = function(Object: BasePart, RootList: array)
	return Initialize(Object, RootList)
end
