class AProjectile : AActor
{
    default bReplicates = true;

    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent)
    UPoolableComponent PoolableComponent;

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent Mesh;
    default Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

    UPROPERTY(NotVisible)
    FProjectileData ProjectileData;

    bool bIsHoming = false;

    UObjectPoolSubsystem ObjectPoolSubsystem;
    
    FTimerHandle DespawnTimer;

    TArray<AActor> HitActors;

    bool bIsActive = false;

    bool bExplodeRemaining = false;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Damage Effects")
    UTDDamageType DamageType;
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Damage Effects")
    float DamageTypeDuration = 2.0f;
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Damage Effects")
    int DamageTypeAmount = 1;


    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        ObjectPoolSubsystem = UObjectPoolSubsystem::Get();
    }

    void Shoot()
    {
        DespawnTimer = System::SetTimer(this, n"Despawn", ProjectileData.LifeTimeMax, false);

        HitActors.Empty();
        bIsActive = true;
        bExplodeRemaining = ProjectileData.bShouldExplodeOnDurationEnd;
    }

    void Shoot(FProjectileData Data)
    {
        ProjectileData = Data;
        Shoot();
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        // Basic movement or other generic projectile behavior
        Move(DeltaSeconds);
    }

    UFUNCTION()
    void Move(float DeltaSeconds) {};

    UFUNCTION()
    void Despawn() 
    {
        if (bExplodeRemaining)
        {
            Explode();
        }
        // DonClear despawn timer
        System::ClearAndInvalidateTimerHandle(DespawnTimer);
        // Set inactive
        bIsActive = false;
        // Return to pool
        PoolableComponent.ReturnToPool();
    };

    void Explode()
    {
        AExplosion Explosion = Cast<AExplosion>(ObjectPoolSubsystem.GetObject(ProjectileData.ExplosionClass, GetActorLocation(), FRotator::ZeroRotator));
        if(IsValid(Explosion))
        {
            Explosion.Explode(DamageType, DamageTypeDuration, DamageTypeAmount);
            bIsActive = false;
            bExplodeRemaining = false;
        }
    }

    UFUNCTION(BlueprintEvent)
    void DamageTarget(AActor Target) 
    {
        if(!bIsActive || !IsValid(Target))
        {
            return;
        }

        if(ProjectileData.ExplosionClass != nullptr && IsValid(ObjectPoolSubsystem))
        {
            Explode();   
        }
        else
        {        
            // Get health component from target
            UHealthSystemComponent HealthSystem = UHealthSystemComponent::Get(Target);
            
            if(IsValid(HealthSystem) && HealthSystem.IsAlive() && !HitActors.Contains(Target))
            {
                HitActors.Add(Target);
                HealthSystem.TakeDamage(ProjectileData.Damage);
                
                if (IsValid(DamageType))
                {
                    Target.TryApplyDamageType(DamageType, DamageTypeDuration, DamageTypeAmount);
                }
            }
        }

        
    };

};

class ATrackingProjectile : AProjectile
{
    UPROPERTY(Replicated)
    AActor Target;

    default bIsHoming = true;

    void Shoot() override
    {
        Super::Shoot();
        if (System::IsServer())
        {
            Target = UObjectRegistry::Get().GetClosestActorOfType(ERegisteredObjectTypes::ERO_Monster, ActorLocation);
        }
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        Super::Tick(DeltaSeconds);

        if (!IsValid(Target))
        {
            Despawn();
            return;
        }


        if (ActorLocation.DistSquared(Target.ActorLocation) < 0.01f)
        {
            DamageTarget(Target);
            Despawn();
        }
    }

    void Move(float DeltaSeconds) override
    {
        if(!IsValid(Target))
        {
            return;
        }
        // No movement for tracking projectiles
        const float RemainingDistance = Target.ActorLocation.Distance(ActorLocation);
        const FVector Direction = (Target.ActorLocation - ActorLocation).GetSafeNormal();
        const FVector Movement = Direction * Math::Min(RemainingDistance, DeltaSeconds * ProjectileData.Speed);
        ActorLocation += Movement;
    }
};

class ANonTrackingProjectile : AProjectile
{
    default Mesh.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
    default Mesh.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Overlap);
    default Mesh.SetGenerateOverlapEvents(true);

    UPROPERTY(NotVisible, Replicated)
    FVector ProjectileVelocity;

    default bIsHoming = false;

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
        if (System::IsServer())
        {
            Mesh.OnComponentBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
        }
    }

    void Shoot() override
    {
        Super::Shoot();

        ProjectileVelocity = ActorForwardVector * ProjectileData.Speed;
    }

    void Move(float DeltaSeconds) override
    {
        // Apply gravity if this projectile is affected by it
        if (ProjectileData.BIsAffectedByGravity())
        {
            ProjectileVelocity.Z -= ProjectileData.Gravity * DeltaSeconds;
        }
        // Basic movement for non-tracking projectiles
        ActorLocation += ProjectileVelocity * DeltaSeconds;
    }

    UFUNCTION()
    void OnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)    
    {
        if (!bIsActive) return;
        DamageTarget(OtherActor);
        Despawn();
    }

};

class AHitScanSingleProjectile : AProjectile
{
    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
        ProjectileData.Speed = MAX_flt;    
    }

    void Shoot() override
    {
        Super::Shoot();
        FHitResult HitResult;
        if (System::LineTraceSingle(ActorLocation, ActorLocation + ActorForwardVector * ProjectileData.MaxRange, 
            ETraceTypeQuery::TraceTypeQuery1, false, TArray<AActor>(), EDrawDebugTrace::None, 
            HitResult, true ) 
            && IsValid(HitResult.Actor))
        {
            SpawnLaserBeam(HitResult.Location);
            DamageTarget(HitResult.Actor);
        }

    }

    UFUNCTION(BlueprintEvent)
    void SpawnLaserBeam(FVector End)
    {
        Print(f"SpawnLaserBeam is not implemented in BP for this class: {GetName()}");
    }

    UFUNCTION(BlueprintEvent)
    void HideLaserBeam()
    {
        Print(f"HideLaserBeam is not implemented in BP for this class: {GetName()}");
    }

    void Despawn() override
    {
        Super::Despawn();
        HideLaserBeam();
    }
}

class AHitScanMultiProjectile : AProjectile
{
    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
        ProjectileData.Speed = MAX_flt;    
    }

    void Shoot() override
    {
        Super::Shoot();
        TArray<FHitResult> HitResults;
        System::LineTraceMulti(ActorLocation, ActorLocation + ActorForwardVector * ProjectileData.MaxRange,
            ETraceTypeQuery::TraceTypeQuery3,false, TArray<AActor>(), EDrawDebugTrace::ForDuration, 
            HitResults, true, FLinearColor::Red, FLinearColor::Green, ProjectileData.LifeTimeMax);
                
            for (FHitResult HitResult : HitResults)
            {
                if (IsValid(HitResult.Actor))
                {
                    DamageTarget(HitResult.Actor);
                }
            }
        
    }

}
