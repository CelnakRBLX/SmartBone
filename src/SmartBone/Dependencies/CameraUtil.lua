local cameraUtil = {}

local function getCorners(CF: CFrame, Size: Vector3)
	local corners = {}

	local frontFaceCenter = (CF + CF.LookVector * Size.Z / 2)
	local backFaceCenter = (CF - CF.LookVector * Size.Z / 2)

	local topFrontEdgeCenter = frontFaceCenter + frontFaceCenter.UpVector * Size.Y / 2
	local bottomFrontEdgeCenter = frontFaceCenter - frontFaceCenter.UpVector * Size.Y / 2
	local topBackEdgeCenter = backFaceCenter + backFaceCenter.UpVector * Size.Y / 2
	local bottomBackEdgeCenter = backFaceCenter - backFaceCenter.UpVector * Size.Y / 2

	corners.topFrontRight = (topFrontEdgeCenter + topFrontEdgeCenter.RightVector * Size.X / 2).Position
	corners.topFrontLeft = (topFrontEdgeCenter - topFrontEdgeCenter.RightVector * Size.X / 2).Position

	corners.bottomFrontRight = (bottomFrontEdgeCenter + bottomFrontEdgeCenter.RightVector * Size.X / 2).Position
	corners.bottomFrontLeft = (bottomFrontEdgeCenter - bottomFrontEdgeCenter.RightVector * Size.X / 2).Position

	corners.topBackRight = (topBackEdgeCenter + topBackEdgeCenter.RightVector * Size.X / 2).Position
	corners.topBackLeft = (topBackEdgeCenter - topBackEdgeCenter.RightVector * Size.X / 2).Position

	corners.bottomBackRight = (bottomBackEdgeCenter + bottomBackEdgeCenter.RightVector * Size.X / 2).Position
	corners.bottomBackLeft = (bottomBackEdgeCenter - bottomBackEdgeCenter.RightVector * Size.X / 2).Position

	return corners
end

function cameraUtil.WithinViewport(Object: Model | BasePart)
	local CameraObject = workspace.CurrentCamera
	local CF, Size
	if CameraObject:IsA("Camera") then
		if Object:IsA("Model") then
			CF, Size = Object:GetBoundingBox()
		elseif Object:IsA("BasePart") then
			CF, Size = Object.CFrame, Object.Size
		else
			warn("Object is neither a Model nor a BasePart! Disregarding Camera check!")
			return false
		end
		local corners = getCorners(CF, Size)
		for _, corner in corners do
			local _, OnScreen = CameraObject:WorldToScreenPoint(corner)
			if OnScreen then
				return true
			end
		end
		return false
	end
end

return cameraUtil
