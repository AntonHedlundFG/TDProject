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
    UInteractableComponent InteractableComp;

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

    UPROPERTY(DefaultComponent, Attach = Root)
    USceneComponent FirePoint;

    UPROPERTY(BlueprintReadOnly, VisibleAnywhere, Replicated, ReplicatedUsing = OnRep_IsBuilt, Transient, Category = "Tower")
    bool bIsBuilt = false;

    AActor Target;
    FVector TargetLocation;
    FVector TargetPredictedLocation;
    float TargetTrackedTime;
    float ProjectileSpeedSquared;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        if (System::IsServer())
        {
            //Bind InteractableComponent delegate functions.
            InteractableComp.OnInteractDelegate.BindUFunction(this, n"Interact");
            InteractableComp.CanInteractDelegate.BindUFunction(this, n"CanInteract");
        }

        //Makes sure Mesh visibilities are correct from the start.
        OnRep_IsBuilt();

        // Calculate the speed of the projectile TODO: Replace with a better solution, probably after using a pooling system?
        if (ProjectileClass != nullptr)
        {
            AProjectile Projectile = Cast<AProjectile>(SpawnActor(ProjectileClass, FVector::ZeroVector, FRotator::ZeroRotator));
            ProjectileSpeedSquared = Projectile.Speed * Projectile.Speed;
            Projectile.DestroyActor();
        }
    }

    UFUNCTION()
    private bool CanInteract(APlayerController User)
    {
        return !bIsBuilt;
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
            FRotator Rotation = (TargetPredictedLocation - FirePoint.GetWorldLocation()).Rotation();
            AProjectile Projectile = Cast<AProjectile>(SpawnActor(ProjectileClass, FirePoint.GetWorldLocation(), Rotation));

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
        if(!bIsBuilt ||!bShouldTrackTarget)
        {
            return;
        }
        AActor ClosestEnemy = UObjectRegistry::Get().GetClosestActorOfType(ERegisteredObjectTypes::ERO_Monster, FirePoint.GetWorldLocation());
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
            FVector TargetVelocity = DistanceSinceLastUpdate / TimeSinceLastUpdate;
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
                TargetPredictedLocation = TargetNewLocation + TargetVelocity * T; // Aim at the predicted location
            }
            else
            {
                TargetPredictedLocation = TargetNewLocation; // No solution, just aim at the current location
            }

        }
        else
        {
            UpdateTarget();
        }

        TargetLocation = TargetNewLocation;
    }


};