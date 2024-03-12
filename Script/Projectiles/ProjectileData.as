struct FProjectileData
{
    UPROPERTY()
    float Speed = 1000.0f;
    UPROPERTY()
    float LifeTimeMax = 5.0f;
    UPROPERTY()
    int32 Damage = 1.0f;

    bool bIsHoming = false;
    UPROPERTY()
    TSubclassOf<AExplosion> ExplosionClass;
    UPROPERTY()
    bool bShouldExplodeOnDurationEnd = false;

    UPROPERTY()
    UTDDamageType DamageType;
    UPROPERTY()
    float DamageTypeDuration = 2.0f;
    UPROPERTY()
    int DamageTypeAmount = 1;
    UPROPERTY()
    float GravityMultiplier = 0.0f;
    const float Gravity = 9810.0f;

    UPROPERTY()
    bool bManualMaxRange = false;
    UPROPERTY()
    float MaxRange = 1000.0f;

    float GetSquaredProjectileSpeed() const
    {
        return Speed * Speed;
    }

    bool BIsAffectedByGravity() const
    {
        return GravityMultiplier != 0.0f;
    }
};