class ATower : AActor
{
    default bReplicates = true;

    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    USceneComponent FinishedMeshRoot;
    default FinishedMeshRoot.bVisible = false;
    UPROPERTY(DefaultComponent, Attach = FinishedMeshRoot)
    UStaticMeshComponent FinishedMesh;
    default FinishedMesh.bVisible = false;

    UPROPERTY(DefaultComponent, Attach = Root)
    USceneComponent PreviewMeshRoot;
    default PreviewMeshRoot.bVisible = true;
    UPROPERTY(DefaultComponent, Attach = PreviewMeshRoot)
    UStaticMeshComponent PreviewMesh;
    default PreviewMesh.bVisible = true;

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
    TSubclassOf<AProjectile> ProjectileClass;

    UPROPERTY(Category = "Debug")
    bool bDebugTracking = false;

    UPROPERTY(DefaultComponent, Attach = FinishedMesh)
    USceneComponent FirePoint;

    UPROPERTY(BlueprintReadOnly, VisibleAnywhere, Replicated, ReplicatedUsing = OnRep_IsBuilt, Transient, Category = "Tower")
    bool bIsBuilt = false;

    // Target tracking variables
    UPROPERTY(Category = "Tower")
    bool bShouldTrackTarget = false;
    // Percentage of the target's velocity to lead (1 = 100% of the target's velocity, 0 = no lead, -1 = 100% of the target's velocity in the opposite direction)
    UPROPERTY(EditAnywhere, Category = "Tower")
    float TrackingLeadPercentage = 0.0f;
    UPROPERTY(EditAnywhere, Category = "Tower")
    float TrackingUpdateRate = 0.1f;
    // Keep target until it's out of range
    UPROPERTY(EditAnywhere, Category = "Tower") 
    bool bKeepTarget = false; 
    UPROPERTY(Replicated)
    USceneComponent Target;
    FVector TargetLocation;
    FVector TargetVelocity;
    float TargetTrackedTime;
    float ProjectileSpeedSquared;
    UPROPERTY(Replicated)
    FRotator TargetRotation;


    // Degrees per second
    UPROPERTY(EditAnywhere, Category = "Tower")
    float RotationSpeedXAxis = 0.0f;    
    // Degrees per second
    UPROPERTY(EditAnywhere, Category = "Tower")
    float RotationSpeedYAxis = 0.0f;
    // Lock fire direction to firepoint forward vector
    UPROPERTY(EditAnywhere, Category = "Tower")
    bool bLockFireDirection = false;

    UPROPERTY(NotVisible)
    bool bProjectileUsesGravity = false;
    const float Gravity = 9810.0f;

    UPROPERTY(VisibleAnywhere, Category = "Tower")
    UObjectPool Pool;

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

        Pool = Cast<UObjectPool>(NewObject(this, UObjectPool::StaticClass()));
        if(IsValid(Pool))
        {
            Pool.Initialize(ProjectileClass, 10);

            AProjectile Projectile = Cast<AProjectile>(Pool.GetObject());
            if(IsValid(Projectile))
            {
                ProjectileSpeedSquared = Projectile.Speed * Projectile.Speed;
                bProjectileUsesGravity = Projectile.bIsAffectedByGravity;
                Pool.ReturnObject(Projectile);
            }
        }

    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {

        if(!bIsBuilt)
        {
            return;
        }

        if(bShouldTrackTarget && IsValid(Target))
        {
            RotateToTarget(DeltaSeconds);
            
            if ( bDebugTracking )
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
        if (ProjectileClass != nullptr && IsValid(Target) && bIsBuilt)
        {
            if(bShouldTrackTarget)
            {
                TrackTarget();
            }

            FRotator FireRotation = bLockFireDirection ? FirePoint.GetWorldRotation() : TargetRotation;
            
            AProjectile Projectile = Cast<AProjectile>(Pool.GetObject(FirePoint.GetWorldLocation(), FireRotation));
            Projectile.Shoot();

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
        // On server : Start firing and tracking timers if the tower is built
        if (System::IsServer() && bIsBuilt)
        {
            System::SetTimer(this, n"Fire", FireRate, true);
            if(bShouldTrackTarget)
            {
                System::SetTimer(this, n"UpdateTarget", TrackingUpdateRate, true);
                System::SetTimer(this, n"TrackTarget", TrackingUpdateRate, true);
            }
        }          
        // On every client : Toggle the visibility of the meshes
        ToggleVisibleMesh();
    }

    UFUNCTION()
    void UpdateTarget()
    {
        if(!System::IsServer() && (!bIsBuilt ||!bShouldTrackTarget))
        {
            return;
        }

        if(bKeepTarget && IsValid(Target) && (Target.GetWorldLocation() - FirePoint.GetWorldLocation()).Size() < Range)
        {
            return;
        }

        ATDEnemy ClosestEnemy = Cast<ATDEnemy>(UObjectRegistry::Get().GetClosestActorOfType(ERegisteredObjectTypes::ERO_Monster, FirePoint.GetWorldLocation(), Range));
        if(IsValid(ClosestEnemy))
        {
            Target = ClosestEnemy.GetTargetComponent();
        }

    }

    UFUNCTION()
    void TrackTarget()
    {
        // Prediction algorithm from https://www.gamedeveloper.com/programming/predictive-aim-mathematics-for-ai-targeting
        if(!IsValid(Target)) return;

        FVector TargetNewLocation = Target.GetWorldLocation();
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
                FVector LeadVelocity = TargetVelocity * (1 + TrackingLeadPercentage);

                if(bProjectileUsesGravity)
                {                    
                    // Vb = Vt - 0.5*Ab*t + [(Pti - Pbi) / t]     
                    FVector GravityVector = FVector(0.0f, 0.0f, -Gravity);
                    Dir = (TargetVelocity + LeadVelocity - GravityVector * T * 0.5f + (TargetLocation - FirePoint.GetWorldLocation()) / T).GetSafeNormal();
                    
                }   
                else
                {                 
                    // Vb = Vt + [(Pti - Pbi) / t]
                    Dir = (TargetVelocity + LeadVelocity + (TargetLocation - FirePoint.GetWorldLocation()) / T).GetSafeNormal();
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

    UFUNCTION()
    void ToggleVisibleMesh()
    {

            FinishedMeshRoot.SetVisibility(bIsBuilt);
            TArray<USceneComponent> Children;
            FinishedMeshRoot.GetChildrenComponents(true, Children);
            for (int i = 0; i < Children.Num(); i++)
            {
                Children[i].SetVisibility(FinishedMeshRoot.IsVisible());
            }

            PreviewMeshRoot.SetVisibility(!bIsBuilt);

            Children.Empty();
            PreviewMeshRoot.GetChildrenComponents(true, Children);
            for (int i = 0; i < Children.Num(); i++)
            {
                Children[i].SetVisibility(PreviewMeshRoot.IsVisible());
            }
        
    }

    UFUNCTION()
    void RotateToTarget(float DeltaSeconds)
    {            
        if(RotationSpeedXAxis > 0)
        {
            FRotator YawRotation = TargetRotation;
            YawRotation.Pitch = 0.0f;
            YawRotation.Roll = 0.0f;

            FRotator NewRot = Math::RInterpTo(GetActorRotation(), YawRotation, DeltaSeconds, RotationSpeedXAxis);
            SetActorRotation(NewRot);
        }

        if ( RotationSpeedYAxis > 0 )
        {
            FRotator MeshRotation = FinishedMesh.GetRelativeRotation();
            FRotator RollRotation = MeshRotation;
            RollRotation.Roll = -TargetRotation.Pitch;
            RollRotation = Math::RInterpTo(MeshRotation, RollRotation, DeltaSeconds, RotationSpeedYAxis);
            FinishedMesh.SetRelativeRotation(RollRotation);

        }
    }

};