class ATower : AActor
{
    default bReplicates = true;

    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent FinishedMesh;
    default FinishedMesh.bVisible = true;

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent PreviewMesh;
    default PreviewMesh.bVisible = false;

    UPROPERTY(DefaultComponent)
    UPricedInteractableComponent InteractableComp;

    UPROPERTY(Category = "Tower")
    int32 Cost = 100;

    UPROPERTY(Category = "Tower")
    int32 Damage = 1;

    UPROPERTY(Category = "Tower")
    float Range = 1000.0f;

    UPROPERTY(Category = "Tower")
    float FireRate = 1.0f;

    UPROPERTY(Category = "Tower")
    bool bShouldTrackTarget = false;

    UPROPERTY(Category = "Tower")
    TSubclassOf<AProjectile> ProjectileClass;

    UPROPERTY(Category = "Debug")
    bool bDebugTracking = false;

    UPROPERTY(DefaultComponent, Attach = Root)
    USceneComponent FirePoint;

    UPROPERTY(BlueprintReadOnly, VisibleAnywhere, Replicated, ReplicatedUsing = OnRep_IsBuilt, Transient, Category = "Tower")
    bool bIsBuilt = false;

    // Target tracking variables
    UPROPERTY(Replicated)
    AActor Target;
    FVector TargetLocation;
    FVector TargetVelocity;
    float TargetTrackedTime;
    float ProjectileSpeedSquared;

    FRotator TargetRotation;

    UPROPERTY(Category = "Tower")
    bool bProjectileUsesGravity = false;
    const float Gravity = 9810.0f;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        if (System::IsServer())
        {
            //Bind InteractableComponent delegate functions.
            InteractableComp.OnPurchasedDelegate.BindUFunction(this, n"Interact");
        }

        //Makes sure Mesh visibilities are correct from the start.
        OnRep_IsBuilt();

        // Calculate the speed of the projectile TODO: Replace with a better solution, probably after using a pooling system?
        if (ProjectileClass != nullptr)
        {
            AProjectile Projectile = Cast<AProjectile>(SpawnActor(ProjectileClass, FVector::ZeroVector, FRotator::ZeroRotator));
            ProjectileSpeedSquared = Projectile.Speed * Projectile.Speed;
            bProjectileUsesGravity = Projectile.bIsAffectedByGravity;
            Projectile.DestroyActor();
        }
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        if ( bDebugTracking && System::IsServer() && bIsBuilt && bShouldTrackTarget )
        {
            System::DrawDebugArrow(
                FirePoint.GetWorldLocation(),
                FirePoint.GetWorldLocation() + TargetRotation.ForwardVector * Range,
                10.0f,
                FLinearColor::Red,
                0.0f,
                1.0f );
        }

    }

    UFUNCTION()
    private void Interact(APlayerController User)
    {
        bIsBuilt = true;
        OnRep_IsBuilt();
    }

    UFUNCTION()
    void Fire()
    {
        if (ProjectileClass != nullptr)
        {
            if(bShouldTrackTarget)
            {
                TrackTarget();
            }
            
            AProjectile Projectile = Cast<AProjectile>(SpawnActor(ProjectileClass, FirePoint.GetWorldLocation(), TargetRotation));

            AStaticAOEProjectile StaticAOEProjectile = Cast<AStaticAOEProjectile>(Projectile);
            if(IsValid(StaticAOEProjectile)) // TODO: Replace with a better solution
            {
                StaticAOEProjectile.Range = Range;
                StaticAOEProjectile.SetActorScale3D(FVector(Range * 0.02f));
            }
        }
    }

    UFUNCTION()
    void OnRep_IsBuilt()
    {
        FinishedMesh.SetVisibility(bIsBuilt);
        PreviewMesh.SetVisibility(!bIsBuilt);

        if (System::IsServer() && bIsBuilt)
        {
            System::SetTimer(this, n"Fire", FireRate, true);
            if(bShouldTrackTarget)
            {
                System::SetTimer(this, n"UpdateTarget", 0.1f, true);
            }
        }          
    }

    UFUNCTION()
    void UpdateTarget()
    {
        if(!System::IsServer() && (!bIsBuilt ||!bShouldTrackTarget))
        {
            return;
        }

        AActor ClosestEnemy = UObjectRegistry::Get().GetClosestActorOfType(ERegisteredObjectTypes::ERO_Monster, FirePoint.GetWorldLocation(), Range);
        if(IsValid(ClosestEnemy))
        {
            Target = ClosestEnemy;
            if(bShouldTrackTarget)
            {
                TrackTarget();
            }
        }

    }

    UFUNCTION()
    void TrackTarget()
    {
        // Prediction algorithm from https://www.gamedeveloper.com/programming/predictive-aim-mathematics-for-ai-targeting

        FVector TargetNewLocation = Target.GetActorLocation();
        float DistanceToTarget = (TargetNewLocation - ActorLocation).Size();
        if(DistanceToTarget > Range)
        {
            return;  
        }

        if(IsValid(Target))
        {
            // Calculate the distance and direction to the target
            FVector DistanceSinceLastUpdate = TargetNewLocation - TargetLocation;
            FVector Direction = DistanceSinceLastUpdate.GetSafeNormal();

            // If the target hasn't moved, there's no need to update the aim
            if(Direction.IsNearlyZero())
            {
                return;
            }

            // Calculate the time since the last update and save the current time
            float CurrentTime = GetWorld().GetTimeSeconds();
            float TimeSinceLastUpdate = CurrentTime - TargetTrackedTime;
            TargetTrackedTime = CurrentTime;

            // Calculate the target's velocity and the cosine of the angle between the direction to the target and the target's velocity
            if(TimeSinceLastUpdate > 0)
            {
                TargetVelocity = DistanceSinceLastUpdate / TimeSinceLastUpdate;
            }
            float CosTheta = Direction.DotProduct((GetActorLocation() - TargetNewLocation).GetSafeNormal());

            // Calculate the time to intercept assuming the target continues in a straight line at constant velocity
            float A = ProjectileSpeedSquared - TargetVelocity.SizeSquared();
            float B = 2 * DistanceToTarget * TargetVelocity.Size() * CosTheta;
            float C = -DistanceToTarget * DistanceToTarget;

            // Calculate the time to intercept
            float T1 = (-B + Math::Sqrt(B * B - 4 * A * C)) / (2 * A);
            float T2 = (-B - Math::Sqrt(B * B - 4 * A * C)) / (2 * A);

            // Choose the smallest positive time
            float T = T1 < T2 ? T1 : T2;
            if (T < 0)
            {
                T = T1 > T2 ? T1 : T2;
            }

            if (T > 0)
            {

                FVector Dir;

                if(bProjectileUsesGravity)
                {                    
                    // Vb = Vt - 0.5*Ab*t + [(Pti - Pbi) / t]     
                    FVector GravityVector = FVector(0.0f, 0.0f, -Gravity);
                    Dir = (TargetVelocity - GravityVector * T * 0.5f + (TargetLocation - FirePoint.GetWorldLocation()) / T).GetSafeNormal();
                }   
                else
                {                 
                    // Vb = Vt + [(Pti - Pbi) / t]
                    Dir = (TargetVelocity + (TargetLocation - FirePoint.GetWorldLocation()) / T).GetSafeNormal();
                }

                TargetRotation = Dir.Rotation();

            }
        }
        else
        {
            UpdateTarget();
        }

        // Save the target's location for the next update
        TargetLocation = TargetNewLocation;
    }

};