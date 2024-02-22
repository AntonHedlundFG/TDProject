class ATrackingProjectile : AActor
{
    default bReplicates = true;

    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent Mesh;

    UPROPERTY(Replicated)
    AActor Target;

    UPROPERTY(Replicated)
    float Speed = 1000.0f;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        if (System::IsServer())
        {
            float BestDist = MAX_flt;
            auto Objects = UObjectRegistry::Get().GetAllObjectsOfType(ERegisteredObjectTypes::ERO_Monster);
            Print(f"{Objects.Num() =}");
            for (UObject Obj : Objects)
            {
                AActor Actor = Cast<AActor>(Obj);
                if (!IsValid(Actor)) continue;

                const float Distance = Actor.ActorLocation.Distance(ActorLocation);
                if (Distance < BestDist)
                {
                    BestDist = Distance;
                    Target = Actor;
                }
            }
            Print(f"Projectile fired: {Target =}");
        }
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        if (!IsValid(Target))
        {
            DestroyActor();
            return;
        }

        const float RemainingDistance = Target.ActorLocation.Distance(ActorLocation);
        const FVector Direction = (Target.ActorLocation - ActorLocation).GetSafeNormal();
        const FVector Movement = Direction * Math::Min(RemainingDistance, DeltaSeconds * Speed);
        ActorLocation += Movement;

        if (ActorLocation.DistSquared(Target.ActorLocation) < 0.01f)
        {
            Print(f"DealDamageHere");
            DestroyActor();
        }
    }
};