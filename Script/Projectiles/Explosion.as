class AExplosion : ANiagaraActor
{
    default bReplicates = true;
    default bReplicateMovement = true;

    UPROPERTY(DefaultComponent)
    UPoolableComponent PoolableComponent;

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
    void Explode(UTDDamageType DamageType = nullptr, float Duration = 0.0f, int Amount = 1, float RadiusIn = 0.0f)
    {
        if (RadiusIn > 0)
            Radius = RadiusIn;
        if(bDebug)
        {
            // Debug for testing
            System::DrawDebugSphere(GetActorLocation(), Radius, 12, FLinearColor::Red, 1.0f, 2.0f );
        }

        NetMulti_VisualizeExplosion();
        
        DamageAllInRange(DamageType, Duration, Amount);
        
        System::SetTimer(PoolableComponent, n"ReturnToPool", Lifetime, false);

    }

    UFUNCTION(NetMulticast)
    void NetMulti_VisualizeExplosion()
    {
        // Play Niagara effect
        if (IsValid(NiagaraComponent))
        {
            NiagaraComponent.Activate(true);
        }

        if (IsValid(ExplosionSound))
        {
            // Play the explosion sound
        }
    }
    
    UFUNCTION()
    void DamageAllInRange(UTDDamageType DamageType, float Duration, int Amount)
    {
        DamagedActors.Empty();

        for (UObject Obj : UObjectRegistry::Get().GetAllInRangeActorsOfType(ERegisteredObjectTypes::ERO_Monster, GetActorLocation(), Radius))
        {
            ATDEnemy Monster = Cast<ATDEnemy>(Obj);
            if (IsValid(Monster) && !DamagedActors.Contains(Monster))
            {
                Monster.HealthSystemComponent.TakeDamage(Damage);
                if (IsValid(DamageType))
                    Monster.TryApplyDamageType(DamageType, Duration, Amount);
                DamagedActors.Add(Monster);
            }
        }
    }

}
