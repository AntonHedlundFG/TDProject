class AExplosion : ANiagaraActor
{

    UPROPERTY(DefaultComponent)
    UPoolableComponent PoolableComponent;

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
    void Explode()
    {
        if(bDebug)
        {
            // Debug for testing
            System::DrawDebugSphere(GetActorLocation(), Radius, 12, FLinearColor::Red, 1.0f, 2.0f );
        }

        // Play Niagara effect
        if (IsValid(NiagaraComponent))
        {
            NiagaraComponent.Activate(true);
        }

        if (IsValid(ExplosionSound))
        {
            // Play the explosion sound
        }
        DamageAllInRange();
        
        System::SetTimer(PoolableComponent, n"ReturnToPool", 2.0f, false);

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
                DamagedActors.Add(Monster);
            }
        }
    }

}
