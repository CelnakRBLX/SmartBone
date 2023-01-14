local cameraUtil = {}

function cameraUtil.WithinViewport(Object: Model | BasePart)
	local CameraObject = workspace.CurrentCamera
	local CF, Size

	if Object:IsA("Model") then
		CF, Size = Object:GetBoundingBox()
	elseif Object:IsA("BasePart") then
		CF, Size = Object.CFrame, Object.Size
	else
		warn("Object is neither a Model nor a BasePart! Disregarding Camera check!")
		return false
	end

	for i = 1, 8 do
		local point = CF * CFrame.new(
			Size.X * (i % 2 == 0 and 0.5 or -0.5),
			Size.Y * (i % 4 > 1 and 0.5 or -0.5),
			Size.Z * (i % 8 > 3 and 0.5 or -0.5)
		)

		if CameraObject:WorldToViewportPoint(point.Position) then
			return true
		end
	end

	return false
end

return cameraUtil
