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

    UPROPERTY(EditDefaultsOnly, Category = "Projectile")
    float Speed = 1000.0f;

    UPROPERTY(EditDefaultsOnly, Category = "Projectile")
    float LifeTimeMax = 5.0f;

    UPROPERTY(EditDefaultsOnly, Category = "Projectile")
    int32 Damage = 1.0f;

    UPROPERTY(VisibleAnywhere, Category = "Projectile")
    bool bIsHoming = false;

    UPROPERTY(EditDefaultsOnly, Category = "Projectile")
    bool bIsAffectedByGravity = false;

    UPROPERTY(EditDefaultsOnly, Category = "Projectile")
    TSubclassOf<AExplosion> ExplosionClass;

    //UActorComponentObjectPool ExplosionPool;
    UObjectPoolSubsystem ObjectPoolSubsystem;

    const float Gravity = 9810.0f;
    
    FTimerHandle DespawnTimer;

    TArray<AActor> HitActors;

    bool bIsActive = false;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Damage Effects")
    UTDDamageType DamageType;
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Damage Effects")
    float DamageTypeDuration = 2.0f;
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Damage Effects")
    int DamageTypeAmount = 1;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        if(ExplosionClass != nullptr)
        {
            ObjectPoolSubsystem = UObjectPoolSubsystem::Get();
        }
    }

    UFUNCTION()
    void Shoot()
    {
        DespawnTimer = System::SetTimer(this, n"Despawn", LifeTimeMax, false);

        HitActors.Empty();
        bIsActive = true;
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        // Basic movement or other generic projectile behavior
        Move(DeltaSeconds);
    }

    UFUNCTION(BlueprintEvent)
    void Move(float DeltaSeconds) {};

    UFUNCTION(BlueprintEvent)
    void Despawn() 
    {
        // DonClear despawn timer
        System::ClearAndInvalidateTimerHandle(DespawnTimer);
        // Move way out of the way as to not trigger trigger overlap events again
        SetActorLocation(FVector(-10000.0f, -10000.0f, -10000.0f));
        // Set inactive
        bIsActive = false;
        // Return to pool
        PoolableComponent.ReturnToPool();
    };

    UFUNCTION(BlueprintEvent)
    void DamageTarget(AActor Target) 
    {
        if(!bIsActive || !IsValid(Target))
        {
            return;
        }

        if(IsValid(ObjectPoolSubsystem))
        {
            AExplosion Explosion = Cast<AExplosion>(ObjectPoolSubsystem.GetObject( ExplosionClass, GetActorLocation(), FRotator::ZeroRotator));
            if(IsValid(Explosion))
            {
                Explosion.Explode();
                bIsActive = false;
            }
        }
        else
        {        
            // Get health component from target
            UHealthSystemComponent HealthSystem = UHealthSystemComponent::Get(Target);
            
            if(IsValid(HealthSystem) && HealthSystem.IsAlive() && !HitActors.Contains(Target))
            {
                HitActors.Add(Target);
                HealthSystem.TakeDamage(Damage);
                
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

    UFUNCTION(BlueprintOverride)
    void Move(float DeltaSeconds) override
    {
        if(!IsValid(Target))
        {
            return;
        }
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

        ProjectileVelocity = ActorForwardVector * Speed;
    }

    UFUNCTION(BlueprintOverride)
    void Move(float DeltaSeconds) override
    {
        // Apply gravity if this projectile is affected by it
        if (bIsAffectedByGravity)
        {
            ProjectileVelocity.Z -= Gravity * DeltaSeconds;
        }
        // Basic movement for non-tracking projectiles
        ActorLocation += ProjectileVelocity * DeltaSeconds;
    }

    UFUNCTION()
    void OnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)    
    {
        DamageTarget(OtherActor);
        Despawn();
    }

};

class AStaticAOEProjectile : AProjectile
{

    UPROPERTY()
    float Range = 1000.0f;

    void Shoot() override
    {
        Super::Shoot();
        if (System::IsServer())
        {
            float BestDist = MAX_flt;
            for (UObject Obj : UObjectRegistry::Get().GetAllObjectsOfType(ERegisteredObjectTypes::ERO_Monster))
            {
                AActor Actor = Cast<AActor>(Obj);
                if (!IsValid(Actor)) continue;

                const float Distance = Actor.ActorLocation.Distance(ActorLocation);
                // Deal Damage to all monsters in range
                if (Distance < Range)
                {
                    DamageTarget(Actor);
                }
            }
        }
    }

};