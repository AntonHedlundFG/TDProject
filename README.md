# Tower Defense Project, Unreal Engine 5 w/ AngelScript
This is a small prototype project, intended to be a way for us to learn how to use AngelScript with Unreal Engine 5, using the alternate engine build by [Hazelight](https://angelscript.hazelight.se/).
The collaborators for this project are:
- [Anton Hedlund](www.AntonHedlund.com)
- [Erik Lund](https://lunderik.wixsite.com/portfolio)
- [Johan Brandt](https://www.johanbrandt.com/)


## Goals
- Learning how to use AngelScript for UnrealEngine appropriately. AngelScript is intended to be used for rapid iteration, with minimal performance loss.
- However, there are things that cannot be done in AngelScript as it exists as a layer between C++ and Blueprints. We want to gain an understanding of what types of problem are better suited for C++ solutions.
- Finishing a rudimentary game prototype before the start of our graduation project at Futuregames.


## Learnings
- AngelScript is fast! Going in to this we knew it was, but it surpassed our expectations.
- Experimental features do not seem to be very well supported. For example, the [RoadMesh](Source/TDProject/Private/RoadMeshComponent.cpp) ProceduralMeshComponent works in C++, but the same exact code did nothing in AngelScript.
- The lack of interfaces in AngelScript can be frustrating, but mixin functions can serve as a more-than-decent alternative. For example, the AActor.TryApplyDamageType mixin function in [DamageTypes.as](Script/DamageTypes/DamageTypes.as)
