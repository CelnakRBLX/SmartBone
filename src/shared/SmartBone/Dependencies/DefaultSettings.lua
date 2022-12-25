local FORCE_MULTIPLIER = 0.2

return {
	Damping = 0.1,
	Stiffness = 0.2,
	Inertia = 0,
	Elasticity = 0.5,
	BlendWeight = 1,
	Radius = 0.2,
	AnchorDepth = 0,
	Force = Vector3.yAxis * FORCE_MULTIPLIER,
	Gravity = -Vector3.yAxis,
	WindDirection = -Vector3.xAxis,
	WindSpeed = 8,
	WindStrength = 1,
	WindInfluence = 1,
	AnchorsRotate = false,
	UpdateRate = 60,
	ActivationDistance = 45,
	ThrottleDistance = 15,
}
