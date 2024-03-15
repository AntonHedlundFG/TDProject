class AExplosion : ANiagaraActor
{
    default bReplicates = true;
    default bReplicateMovement = true;

    UPROPERTY(DefaultComponent)
    UPoolableComponent PoolableComponent;

    UPROPERTY()
    FProjectileData ProjectileData;

    UPROPERTY(EditAnywhere, Category = "Explosion")
    float Lifetime = 2.0f;

    UPROPERTY(EditAnywhere, Category = "Explosion")
    float Damage = 100.0f;

    UPROPERTY(EditAnywhere, Category = "Explosion")
    float Radius = 500.0f;

    UPROPERTY(EditDefaultsOnly, Category = "Explosion")
    USoundBase ExplosionSound;

    UPROPERTY(EditAnywhere, Category = "Debug")
    bool bDebug = false;

    TArray<AActor> DamagedActors;

    UFUNCTION()
    void Explode(FProjectileData Data)
    {
        ProjectileData = Data;
        if(bDebug)
        {
            // Debug for testing
            System::DrawDebugSphere(GetActorLocation(), Radius, 12, FLinearColor::Red, 1.0f, 2.0f );
        }

        NetMulti_VisualizeExplosion();
        
        DamageAllInRange();
        
        System::SetTimer(PoolableComponent, n"ReturnToPool", Lifetime, false);

    }

    UFUNCTION(NetMulticast)
    void NetMulti_VisualizeExplosion()
    {
        // Play Niagara effect
        if (IsValid(NiagaraComponent))
        {
            NiagaraComponent.Activate(true);
            OnExplode();
        }

        if (IsValid(ExplosionSound))
        {
            // Play the explosion sound
        }
    }
    
    UFUNCTION()
    void DamageAllInRange()
    {
        DamagedActors.Empty();

        for (UObject Obj : UObjectRegistry::Get().GetAllInRangeActorsOfType(ERegisteredObjectTypes::ERO_Monster, GetActorLocation(), Radius))
        {
            ATDEnemy Monster = Cast<ATDEnemy>(Obj);
            if (IsValid(Monster) && !DamagedActors.Contains(Monster))
            {
                Monster.HealthSystemComponent.TakeDamage(Damage);
                if (IsValid(ProjectileData.DamageType))
                    Monster.TryApplyDamageType(ProjectileData.DamageType, ProjectileData.DamageTypeDuration, ProjectileData.DamageTypeAmount);
                DamagedActors.Add(Monster);
            }
        }
    }

    UFUNCTION(BlueprintEvent)
    void OnExplode()
    {
        // Blueprint event
    }

}
