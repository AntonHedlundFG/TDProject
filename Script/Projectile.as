class AProjectile : APoolableActor
{
    default bReplicates = true;

    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

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

    const float Gravity = 9810.0f;
    
    FTimerHandle DespawnTimer;


    UFUNCTION()
    void Shoot()
    {
        DespawnTimer = System::SetTimer(this, n"Despawn", LifeTimeMax, false);
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
        System::ClearAndInvalidateTimerHandle(DespawnTimer);
        ReturnToPool();
    };

    UFUNCTION(BlueprintEvent)
    void DamageTarget(AActor Target) 
    {
        if(!IsValid(Target))
        {
            return;
        }
        // Get health component from target
        UHealthSystemComponent HealthSystem = UHealthSystemComponent::Get(Target);
        
        if(IsValid(HealthSystem))
        {
            HealthSystem.TakeDamage(Damage);
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
