class ATower : ATowerBase
{
    default bReplicates = true;

    // -- Components --
    //UPROPERTY(DefaultComponent, RootComponent)
    //USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    USceneComponent FinishedMeshRoot;
    default FinishedMeshRoot.bVisible = false;

    UPROPERTY(DefaultComponent, Attach = FinishedMeshRoot)
    UStaticMeshComponent FinishedMesh;

    UPROPERTY(DefaultComponent, Attach = FinishedMesh)
    USceneComponent FirePoint;
    // ---------------
    
    UPROPERTY(Category = "Tower")
    FName TowerName = FName("Tower");
    UPROPERTY(Category = "Tower")
    int TowerPrice = 100;
    // Fire rate in seconds
    UPROPERTY(Category = "Tower")
    float FireRate = 1.0f;
    // How often the tower should update its target
    UPROPERTY(Category = "Tower")
    float TargetUpdateRate = 0.5f;
    // Should the tower track a target
    UPROPERTY(Category = "Tower|Tracking")
    bool bShouldTrackTarget = false;
    // Keep target until it's out of range
    UPROPERTY(EditAnywhere, Category = "Tower|Tracking") 
    bool bKeepTarget = false; 
    // Percentage of the target's velocity to lead (1 = 100% of the target's velocity, 0 = no lead, -1 = 100% of the target's velocity in the opposite direction)
    UPROPERTY(EditAnywhere, Category = "Tower|Tracking", meta = (EditCondition = "bShouldTrackTarget"))
    float TrackingLeadPercentage = 0.0f;
    // How often the tower should update its target's position
    UPROPERTY(EditAnywhere, Category = "Tower|Tracking", meta = (EditCondition = "bShouldTrackTarget"))
    float TrackingUpdateRate = 0.1f;
    // Degrees per second
    UPROPERTY(EditAnywhere, Category = "Tower|Tracking", meta = (EditCondition = "bShouldTrackTarget"))
    float RotationSpeedXAxis = 0.0f;    
    // Degrees per second
    UPROPERTY(EditAnywhere, Category = "Tower|Tracking", meta = (EditCondition = "bShouldTrackTarget"))
    float RotationSpeedYAxis = 0.0f;
    // Lock fire direction to firepoint forward vector
    UPROPERTY(EditAnywhere, Category = "Tower|Tracking", meta = (EditCondition = "bShouldTrackTarget"))
    bool bLockFireDirection = false;

    // Owning player index
    // UPROPERTY(EditAnywhere, BlueprintReadWrite, Replicated, Category = "Tower|Ownership")
    // uint8 OwningPlayerIndex = 0;
    // Player colors data asset
    // UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Tower|Ownership")
    // UPlayerColorsDataAsset PlayerColors;
    
    // Projectile class
    UPROPERTY(Category = "Tower|Projectile")
    TSubclassOf<AProjectile> ProjectileClass;
    //--- Projectile properties ---//
    UPROPERTY(Category = "Tower|Projectile")
    FProjectileData ProjectileData;

    // Debug
    UPROPERTY(Category = "Debug")
    bool bDebugTracking = false;

    //--- Tracking ---//
    UPROPERTY(NotVisible, Replicated)
    USceneComponent Target;
    FVector TargetLocation;
    FVector TargetVelocity;
    float TargetDistance;
    float TargetTrackedTime;
    UPROPERTY(NotVisible, Replicated)
    FRotator TargetRotation;


    //--- Object Pooling ---//
    UObjectPoolSubsystem ObjectPoolSubsystem;

    //--- TimerHandles ---//
    FTimerHandle FireTimerHandle;
    FTimerHandle TargetUpdateTimerHandle;
    FTimerHandle TargetTrackingTimerHandle;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {  
        Super::BeginPlay();
        SetPlayerColor();
        ObjectPoolSubsystem = UObjectPoolSubsystem::Get();

        if (System::IsServer())
        {
            if (TryFetchingProjectileData())
                StartFiringTimers();
            else
                DestroyActor();
        }
    }

    bool TryFetchingProjectileData()
    {
        if(ProjectileClass != nullptr)
        {
            // Calculate the max range for the projectile if it is affected by gravity
            if(ProjectileData.BIsAffectedByGravity())
            {
                if(!ProjectileData.bManualMaxRange) 
                {
                    // Lower it if it is less than the editor set value
                    float MaxRange = CalculateMaxDistanceForProjectile();
                    if(MaxRange < ProjectileData.MaxRange)
                    {
                        ProjectileData.MaxRange = MaxRange;
                    }
                }
            }
        }
        else
        {
            Print(f"No projectile class set for tower: {GetName()} -> Destroying actor");
            DestroyActor();
            return false;
        }
        return true;
    }

    void StartFiringTimers()
    {
        FireTimerHandle = System::SetTimer(this, n"Fire", FireRate, true);
        TargetUpdateTimerHandle = System::SetTimer(this, n"UpdateTarget", TargetUpdateRate, true);
        if(bShouldTrackTarget)
        {
            TargetTrackingTimerHandle = System::SetTimer(this, n"TrackTarget", TrackingUpdateRate, true);
        }
        // Get GameState and bind to GameEnded delegate
        ATDGameState GameState = Cast<ATDGameState>(GetWorld().GetGameState());
        if(IsValid(GameState))
        {
            GameState.OnGameLostEvent.AddUFunction(this, n"OnGameEnded");
        }
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        if(bShouldTrackTarget && IsValid(Target))
        {
            RotateToTarget(DeltaSeconds);
            
            if ( bDebugTracking )
            {
                System::DrawDebugArrow(
                    FirePoint.GetWorldLocation(),
                    FirePoint.GetWorldLocation() + TargetRotation.ForwardVector * ProjectileData.MaxRange,
                    10.0f,
                    FLinearColor::Red,
                    0.0f,
                    1.0f );
            }
        }

    }

    UFUNCTION()
    private void SetPlayerColor()
    {
        if (PlayerColors != nullptr)
        {
            FVector PlayerColor = PlayerColors.GetColorOf(OwningPlayerIndex);
            TArray<UActorComponent> OutComponents;
            GetAllComponents(UStaticMeshComponent::StaticClass(), OutComponents);
            for (UActorComponent Comp : OutComponents)
            {
                Cast<UStaticMeshComponent>(Comp).SetVectorParameterValueOnMaterials(FName("Tint"), PlayerColor);
            }
        }
    }

    UFUNCTION()
    void Fire()
    {
        if (ProjectileClass != nullptr && IsValid(Target))
        {
            FRotator FireRotation = bLockFireDirection ? FirePoint.GetWorldRotation() : TargetRotation;
            AProjectile Projectile = Cast<AProjectile>(ObjectPoolSubsystem.GetObject(ProjectileClass , FirePoint.GetWorldLocation(), FireRotation));
            Projectile.Shoot(ProjectileData);
        }
    }    
    
    UFUNCTION()
    void UpdateTarget()
    {
        if(!System::IsServer() && !bShouldTrackTarget)
        {
            return;
        }

        if(bKeepTarget && IsValid(Target) && IsTargetInRange(Target.GetWorldLocation()))
        {
            return;
        }

        ATDEnemy ClosestEnemy = Cast<ATDEnemy>(UObjectRegistry::Get().GetClosestActorOfType(ERegisteredObjectTypes::ERO_Monster, FirePoint.GetWorldLocation(), ProjectileData.MaxRange));
        if(IsValid(ClosestEnemy))
        {
            Target = ClosestEnemy.GetTargetComponent();
        }
        else
        {
            Target = nullptr;
        }

    }

    UFUNCTION()
    bool IsTargetInRange(FVector InTargetLocation)
    {
        TargetDistance = (InTargetLocation - ActorLocation).Size();
        return TargetDistance <= ProjectileData.MaxRange;
    }

    UFUNCTION()
    void TrackTarget()
    {
        // Prediction algorithm from https://www.gamedeveloper.com/programming/predictive-aim-mathematics-for-ai-targeting
        if(!IsValid(Target)) return;

        FVector TargetNewLocation = Target.GetWorldLocation();
        if(!IsTargetInRange(TargetNewLocation))
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
            float A = ProjectileData.GetSquaredProjectileSpeed() - TargetVelocity.SizeSquared();
            float B = 2 * TargetDistance * TargetVelocity.Size() * CosTheta;
            float C = -TargetDistance * TargetDistance;

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

                if(ProjectileData.BIsAffectedByGravity())
                {                    
                    // Vb = Vt - 0.5*Ab*t + [(Pti - Pbi) / t]     
                    FVector GravityVector = FVector(0.0f, 0.0f, -ProjectileData.Gravity);
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

    float CalculateMaxDistanceForProjectile()
    {
        if(ProjectileData.BIsAffectedByGravity())
        {
            // Max distance for a projectile affected by gravity until it hits the ground at the same height as the fire point
            return ProjectileData.GetSquaredProjectileSpeed() * Math::Sin(2 * Math::DegreesToRadians(45)) / (ProjectileData.Gravity * ProjectileData.GravityMultiplier);
        }
        else
        {
            // Max distance for a projectile not affected by gravity
            return ProjectileData.Speed * ProjectileData.LifeTimeMax;
        } 
    }

    UFUNCTION()
    void OnGameEnded()
    {
        if(System::IsServer())
        {
            System::ClearAndInvalidateTimerHandle(FireTimerHandle);
            System::ClearAndInvalidateTimerHandle(TargetUpdateTimerHandle);
            System::ClearAndInvalidateTimerHandle(TargetTrackingTimerHandle);
            SetActorTickEnabled(false);
        }
    }

};

class AStaticFireTower : ATower
{
    UPROPERTY()
    AProjectile ActiveProjectile;
    
    TArray<FHitResult> HitResults;

    void Fire() override
    {
        if (ProjectileClass != nullptr && IsValid(Target))
        {
            FRotator FireRotation = bLockFireDirection ? FirePoint.GetWorldRotation() : TargetRotation;
            AHitScanMultiProjectile Projectile = Cast<AHitScanMultiProjectile>(ObjectPoolSubsystem.GetObject(ProjectileClass , FirePoint.GetWorldLocation(), FireRotation));
            Projectile.Shoot(ProjectileData, HitResults);
            FVector ShotEndLocation = HitResults.Num() > 0 ? HitResults.Last().Location : FirePoint.GetWorldLocation() + FireRotation.Vector() * ProjectileData.MaxRange;
            ShowShotVisual(FirePoint.GetWorldLocation(), ShotEndLocation);
            if(HitResults.Num() > 0)
            {   
                for(FHitResult HitResult : HitResults)
                {
                    ShowImpactVisual(HitResult.Location);
                }
            }
            else
            {
                HideShotVisual();
            }
            HitResults.Empty();
        }
    }   

    UFUNCTION(BlueprintEvent)
    void ShowShotVisual(FVector Start,FVector End)
    {
        Print(f"ShowShotVisual is not implemented in BP for this class: {GetName()}");
    }

    UFUNCTION(BlueprintEvent)
    void ShowImpactVisual(FVector Location)
    {
        Print(f"ShowImpactVisual is not implemented in BP for this class: {GetName()}");
    }

    UFUNCTION(BlueprintEvent)
    void HideShotVisual()
    {
        Print(f"HideShotVisual is not implemented in BP for this class: {GetName()}");
    }

}