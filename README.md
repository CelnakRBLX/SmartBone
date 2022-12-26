# SmartBone

An optimized solution for dynamically simulated bone physics inside Roblox.

## Current Features
* Dynamic Bone Physics Simulation
* Wind Simulation

## Setting up the module:

```lua
-- LocalScript

local SmartBone = require(game.ReplicatedStorage:WaitForChild("SmartBone"))
SmartBone.Start()
```

## How to set up a SmartBone Object:

* Select any MeshPart with Bones under it

* Add the tag “SmartBone” to the MeshPart with CollectionService, or the built in Tag Editor that Roblox recently added to Studio.

* Add a string attribute called “Roots” to the MeshPart and fill it with the name(s) of the bone(s) you want to be root(s).

* Separate each bone name with “,” and the LocalScript will automatically sort your bone(s) into a list.

* An example of a SmartBone object with multiple roots would have a Roots attribute that looks like this: “Root1,Root2,Root3”

* Make sure you don’t add any spaces or characters unless they are part of the name of the bone(s) you want to be included

* Change any other values by adding the corresponding Attributes:

  * [Number] Damping – How slowed down the calculated motion of the SmartBone(s) will be.

  * [Number] Stiffness – How much of the bone(s) original CFrame is preserved.

  * [Number] Inertia – How much the of the movement of the object is ignored.

  * [Number] Elasticity – How much force is applied to return each bone to its original CFrame.

  * [Vector3] Gravity – Direction and Magnitude of Gravity in World Space.

  * [Vector3] Force – Additional Force applied to Bones in World Space. Supplementary to Gravity.

  * [Number] WindInfluence – How much influence wind has on the SmartBone object.

  * [Number] AnchorDepth – This will determine how far down in heirarchy from the Root that bones will be Anchored.

  * [Boolean] AnchorsRotate – If true, the root bone(s) will rotate along with the rest of the bone(s), but remain in static position. If false, the root bone(s) will remain completely static in both Position and Orientation.

  * [Number] UpdateRate – The rate, in frames-per-second, at which SmartBone will simulate.

  * [Number] ActivationDistance – The distance, in studs, at which the SmartBone stops simulation.

  * [Number] ThrottleDistance – The distance, in studs, at which the SmartBone begins to throttle simulation rates based on distance. Scales based on UpdateRate.

* For Wind settings, apply Attributes to the Lighting Service:

  * [Vector3] WindDirection – Self-explanatory, the Direction the wind should blow in World Space.

  * [Number] WindSpeed – The speed of the Bone(s) motion from the wind.

  * [Number] WindStrength – The strength of the wind.

## Things to note:

* None of the settings listed, with the exception of ‘Roots’ which is needed for setup, are required as attributes. You can easily just slap a CollectionService tag on a MeshPart with bones in it, and all of the default settings will still apply.

* Any changes to an objects settings at runtime, again with the exception of ‘Roots’, will be reflected in the simulations live.

* It really goes without saying, but just because this system is well optimized does not mean you can safely jam pack your game with tens of thousands of SmartBone objects. Though due to the Wind Simulation functionality, SmartBone does provide a good method of adding Windy Trees, provided it is used sparingly and with the proper distance settings.

* For best results, make sure the orientation of your bones closely matches the geometry of the given mesh.

* As with many things, the performance you see in studio does not necessarily reflect live performance. In testing, I’ve found that most of the time, it is 2-3x slower in studio testing vs live testing.
