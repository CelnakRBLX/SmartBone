local module = {}

function module.ShallowCopy(original)
	local copy = {}

	for key, value in pairs(original) do
		copy[key] = value
	end

	return copy
end

function module.Lerp(A: any, B: any, C: any)
	return A + (B - A) * C
end

function module.GetRotationBetween(U: Vector3, V: Vector3, Axis: Vector3)
	local Dot, UXV = U:Dot(V), U:Cross(V)

	if Dot < -0.99999 then
		return CFrame.fromAxisAngle(Axis, math.pi)
	end

	return CFrame.new(0, 0, 0, UXV.X, UXV.Y, UXV.Z, 1 + Dot)
end

function module.GetHierarchyLength(Child: Instance, Root: Instance)
	if Child == Root then
		warn("Child and Root are the same Instance!")
		return
	end

	if Child == nil then
		warn("Child is nil!")
		return
	end

	local Up = Child
	local Count = 0

	repeat
		Count += 1
		Up = Up.Parent
	until Up == Root

	return Count
end

function module.WaitForChildOfClass(parent: Instance, className: string, timeOut: number)
	local start = os.clock()
	timeOut = timeOut or 10
	repeat 
		task.wait()
	until parent:FindFirstChildOfClass(className) or os.clock() - start > timeOut
	return parent:FindFirstChildOfClass(className)
end

return module
