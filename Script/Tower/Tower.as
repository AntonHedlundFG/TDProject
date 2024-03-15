class ATower : ATowerBase
{
    default bReplicates = true;

    // -- Components -- //
    UPROPERTY(DefaultComponent)
    USceneComponent FiringBarrelRoot;
    UPROPERTY(DefaultComponent, Attach = FiringBarrelRoot)
    USceneComponent FirePoint;

    //--- Tower properties ---//
    UPROPERTY(Replicated, ReplicatedUsing = OnRep_OnTowerDataUpdated, Category = "Tower")
    protected UTowerData TowerData;
    
    // Should the tower track a target
    UPROPERTY(Category = "Tower|Tracking")
    bool bShouldTrackTarget = false;
    // Keep target until it's out of range
    UPROPERTY(EditAnywhere, Category = "Tower|Tracking") 
    bool bKeepTarget = false; 
    // Lock fire direction to firepoint forward vector
    UPROPERTY(EditAnywhere, Category = "Tower|Tracking", meta = (EditCondition = "bShouldTrackTarget"))
    bool bLockFireDirection = false;

    // Projectile class
    UPROPERTY(Category = "Tower|Projectile")
    TSubclassOf<AProjectile> ProjectileClass;

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
            if(TowerData.ProjectileData.BIsAffectedByGravity())
            {
                if(!TowerData.ProjectileData.bManualMaxRange) 
                {
                    // Lower it if it is less than the editor set value
                    float MaxRange = CalculateMaxDistanceForProjectile();
                    if(MaxRange < TowerData.ProjectileData.MaxRange)
                    {
                        TowerData.ProjectileData.MaxRange = MaxRange;
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
        FireTimerHandle = System::SetTimer(this, n"Fire", TowerData.FireRate, true);
        TargetUpdateTimerHandle = System::SetTimer(this, n"UpdateTarget", TowerData.TargetUpdateRate, true);
        if(bShouldTrackTarget)
        {
            TargetTrackingTimerHandle = System::SetTimer(this, n"TrackTarget", TowerData.TrackingUpdateRate, true);
        }
        // Get GameState and bind to GameEnded delegate
        ATDGameState GameState = Cast<ATDGameState>(GetWorld().GetGameState());
        if(IsValid(GameState))
        {
            GameState.OnGameLostEvent.AddUFunction(this, n"OnGameEnded");
        }
    }

    UFUNCTION()
    void SetTowerData(UTowerData NewData)
    {
        TowerData = NewData;

        //Reset firing cooldowns
        System::ClearAndInvalidateTimerHandle(FireTimerHandle);
        FireTimerHandle = System::SetTimer(this, n"Fire", TowerData.FireRate, true);
        OnRep_OnTowerDataUpdated();
    }

    UFUNCTION(BlueprintEvent)
    void OnRep_OnTowerDataUpdated()
    {
        if(System::IsServer())
        {
            StartFiringTimers();
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
                    FirePoint.GetWorldLocation() + TargetRotation.ForwardVector * TowerData.ProjectileData.MaxRange,
                    10.0f,
                    FLinearColor::Red,
                    0.0f,
                    1.0f );
            }
        }

    }

    UFUNCTION()
    void Fire()
    {
        if (ProjectileClass != nullptr && (IsValid(Target) || TowerData.bShouldShootWithoutTarget))
        {
            FRotator FireRotation = bLockFireDirection ? FirePoint.GetWorldRotation() : TargetRotation;
            AProjectile Projectile = Cast<AProjectile>(ObjectPoolSubsystem.GetObject(ProjectileClass , FirePoint.GetWorldLocation(), FireRotation));
            Projectile.Shoot(TowerData.ProjectileData);
            BlueprintFire();
        }
    }

    UFUNCTION(BlueprintEvent)
    void BlueprintFire()
    {
        // Implement in BP
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

        ATDEnemy ClosestEnemy = Cast<ATDEnemy>(UObjectRegistry::Get().GetClosestActorOfType(ERegisteredObjectTypes::ERO_Monster, FirePoint.GetWorldLocation(), TowerData.ProjectileData.MaxRange));
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
        return TargetDistance <= TowerData.ProjectileData.MaxRange;
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
            float A = TowerData.ProjectileData.GetSquaredProjectileSpeed() - TargetVelocity.SizeSquared();
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
                FVector LeadVelocity = TargetVelocity * (1 + TowerData.TrackingLeadPercentage);

                if(TowerData.ProjectileData.BIsAffectedByGravity())
                {                    
                    // Vb = Vt - 0.5*Ab*t + [(Pti - Pbi) / t]     
                    FVector GravityVector = FVector(0.0f, 0.0f, -TowerData.ProjectileData.Gravity);
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
        if(TowerData.RotationSpeedXAxis > 0)
        {
            FRotator YawRotation = TargetRotation;
            YawRotation.Pitch = 0.0f;
            YawRotation.Roll = 0.0f;

            FRotator NewRot = Math::RInterpTo(GetActorRotation(), YawRotation, DeltaSeconds, TowerData.RotationSpeedXAxis);
            SetActorRotation(NewRot);
        }

        if ( TowerData.RotationSpeedYAxis > 0 )
        {
            FRotator CurrentPitch = FiringBarrelRoot.GetRelativeRotation();
            FRotator NewPitch = CurrentPitch;
            NewPitch.Pitch = TargetRotation.Pitch;
            NewPitch = Math::RInterpTo(CurrentPitch, NewPitch, DeltaSeconds, TowerData.RotationSpeedYAxis);
            FiringBarrelRoot.SetRelativeRotation(NewPitch);
        }
    }

    float CalculateMaxDistanceForProjectile()
    {
        if(TowerData.ProjectileData.BIsAffectedByGravity())
        {
            // Max distance for a projectile affected by gravity until it hits the ground at the same height as the fire point
            return TowerData.ProjectileData.GetSquaredProjectileSpeed() * Math::Sin(2 * Math::DegreesToRadians(45)) / (TowerData.ProjectileData.Gravity * TowerData.ProjectileData.GravityMultiplier);
        }
        else
        {
            // Max distance for a projectile not affected by gravity
            return TowerData.ProjectileData.Speed * TowerData.ProjectileData.LifeTimeMax;
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
            Projectile.Shoot(TowerData.ProjectileData, HitResults);
            FVector ShotEndLocation;
            if(HitResults.Num() > 0)
            {   
                for(int i = 0; i < HitResults.Num(); i++)
                {
                    if(i >= TowerData.ProjectileData.MaxHits) break;
                    NetMulti_ShowImpactVisual(HitResults[i].Location);
                    ShotEndLocation = HitResults[i].Location;
                }
            }
            else
            {
                NetMulti_HideShotVisual();
                ShotEndLocation = FirePoint.GetWorldLocation() + FirePoint.GetWorldRotation().ForwardVector * TowerData.ProjectileData.MaxRange;
            }
            NetMulti_ShowShotVisual(FirePoint.GetWorldLocation(), ShotEndLocation);
            HitResults.Empty();
            BlueprintFire();
        }
        else
        {
            NetMulti_HideShotVisual();
        }
    }   

    void TrackTarget() override
    {
        if(!IsValid(Target)) return;

        FVector TargetNewLocation = Target.GetWorldLocation();
        if(!IsTargetInRange(TargetNewLocation))
        {
            return;  
        }
        TargetLocation = TargetNewLocation;
        TargetRotation = (TargetLocation - FirePoint.GetWorldLocation()).Rotation();       
    }

    UFUNCTION(NetMulticast, BlueprintEvent)
    void NetMulti_ShowShotVisual(FVector Start,FVector End)
    {
        // Implement in BP
    }

    UFUNCTION(NetMulticast, BlueprintEvent)
    void NetMulti_ShowImpactVisual(FVector Location)
    {
        // Implement in BP
    }

    UFUNCTION(NetMulticast, BlueprintEvent)
    void NetMulti_HideShotVisual()
    {
        // Implement in BP
    }

}