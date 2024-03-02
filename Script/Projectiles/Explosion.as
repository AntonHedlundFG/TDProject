class AExplosion : APoolableActor
{

    UPROPERTY(EditAnywhere, Category = "Explosion")
    float Damage = 100.0f;

    UPROPERTY(EditAnywhere, Category = "Explosion")
    float Radius = 500.0f;

    UPROPERTY(EditDefaultsOnly, Category = "Explosion")
    UParticleSystem ExplosionFX;

    UPROPERTY(EditDefaultsOnly, Category = "Explosion")
    USoundBase ExplosionSound;

    TArray<AActor> DamagedActors;

    UFUNCTION()
    void Explode()
    {
        // Debug for testing
        System::DrawDebugSphere(GetActorLocation(), Radius, 12, FLinearColor::Red, 1.0f, 2.0f );

        if (IsValid(ExplosionFX))
        {
            // Spawn the explosion FX
        }
        if (IsValid(ExplosionSound))
        {
            // Play the explosion sound
        }
        DamageAllInRange();
        ReturnToPool(); // Maybe wanna do this after a delay
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
