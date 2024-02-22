class AProjectile : AActor
{
    default bReplicates = true;

    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent Mesh;
    default Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

    UPROPERTY(Replicated)
    float Speed = 1000.0f;

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        // Basic movement or other generic projectile behavior
        Move(DeltaSeconds);
    }

    UFUNCTION(BlueprintEvent)
    void Move(float DeltaSeconds) {};

};

class ATrackingProjectile : AProjectile
{
    UPROPERTY(Replicated)
    AActor Target;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        if (System::IsServer())
        {
            float BestDist = MAX_flt;
            for (UObject Obj : UObjectRegistry::Get().GetAllObjectsOfType(ERegisteredObjectTypes::ERO_Monster))
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
        }
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        Super::Tick(DeltaSeconds);

        if (!IsValid(Target))
        {
            DestroyActor();
            return;
        }


        if (ActorLocation.DistSquared(Target.ActorLocation) < 0.01f)
        {
            Print(f"DealDamageHere");
            DestroyActor();
        }
    }

    UFUNCTION(BlueprintOverride)
    void Move(float DeltaSeconds) override
    {
        // No movement for tracking projectiles
        
        const float RemainingDistance = Target.ActorLocation.Distance(ActorLocation);
        const FVector Direction = (Target.ActorLocation - ActorLocation).GetSafeNormal();
        const FVector Movement = Direction * Math::Min(RemainingDistance, DeltaSeconds * Speed);
        ActorLocation += Movement;
    }
};

class ANonTrackingProjectile : AProjectile
{
    default Mesh.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
    default Mesh.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Overlap);
    default Mesh.SetGenerateOverlapEvents(true);

    FVector TargetLocation;
    AActor Target;
    float Time;

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
        Mesh.OnComponentBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
    }

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        if (System::IsServer())
        {
            float BestDist = MAX_flt;
            for (UObject Obj : UObjectRegistry::Get().GetAllObjectsOfType(ERegisteredObjectTypes::ERO_Monster))
            {
                AActor Actor = Cast<AActor>(Obj);
                if (!IsValid(Actor)) continue;

                const float Distance = Actor.ActorLocation.Distance(ActorLocation);
                if (Distance < BestDist)
                {
                    BestDist = Distance;
                    Target = Actor;
                    TargetLocation = Actor.ActorLocation;
                    FVector Direction = (TargetLocation - ActorLocation).GetSafeNormal();
                    SetActorRotation(Direction.Rotation());
                    Time = GetWorld().GetTimeSeconds();

                    // Schedule for next frame to allow for target to move
                    System::SetTimer(this, n"PredictTargetLocation", 0.01f, false);
                }
            }
        }
    }

    UFUNCTION()
    void PredictTargetLocation()
    {
        // Prediction algorithm from https://www.gamedeveloper.com/programming/predictive-aim-mathematics-for-ai-targeting

        FVector PredictedLocation;
        FVector NewTargetLocation = Target.ActorLocation;
        FVector DistanceSinceLastUpdate = NewTargetLocation - TargetLocation;
        FVector Direction = DistanceSinceLastUpdate.GetSafeNormal();
        float TimeSinceLastUpdate = GetWorld().GetTimeSeconds() - Time;
        FVector TargetVelocity = DistanceSinceLastUpdate / TimeSinceLastUpdate;

        float CosTheta = Direction.DotProduct((GetActorLocation() - NewTargetLocation).GetSafeNormal());
        float DistanceToTarget = (NewTargetLocation - ActorLocation).Size();

        // Calculate the time to intercept assuming the target continues in a straight line at constant velocity
        float A = Speed * Speed - TargetVelocity.SizeSquared();
        float B = 2 * DistanceToTarget * TargetVelocity.Size() * CosTheta;
        float C = -DistanceToTarget * DistanceToTarget;

        float T1 = (-B + Math::Sqrt(B * B - 4 * A * C)) / (2 * A);
        float T2 = (-B - Math::Sqrt(B * B - 4 * A * C)) / (2 * A);

        T1 = T1 < 0 ? T1 = MAX_flt : T1;
        T2 = T2 < 0 ? T2 = MAX_flt : T2;
        float T = Math::Min(T1, T2);

        if (T > 0)
        {
            PredictedLocation = NewTargetLocation + TargetVelocity * T;
        }
        else
        {
            PredictedLocation = NewTargetLocation;
        }

        FVector NewDirection = (PredictedLocation - ActorLocation).GetSafeNormal();
        SetActorRotation(NewDirection.Rotation());

        //System::DrawDebugArrow(ActorLocation, PredictedLocation, 10.0f, FLinearColor::Red, 1.0f);

    }

    UFUNCTION(BlueprintOverride)
    void Move(float DeltaSeconds) override
    {
        // Basic movement for non-tracking projectiles
        ActorLocation += ActorForwardVector * Speed * DeltaSeconds;
    }

    UFUNCTION()
    void OnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)    
    {
        
        if (OtherActor.IsA(AActor::StaticClass())) // TODO: Check for specific actor type
        {
            Print(f"DealDamageHere");
        }
        Print(f"Hit Something Destroying projectile");
        DestroyActor();
    }

};
