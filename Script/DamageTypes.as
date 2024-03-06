class UTDDamageTypeComponent : UActorComponent
{
    private TMap<UTDDamageType, int> DamageTypeInstances;

    TArray<UDelayedRemoval> DelayedRemovals;

    int GetEffectsOfType(UTDDamageType DamageType)
    {
        return (DamageTypeInstances.Contains(DamageType) ? DamageTypeInstances[DamageType] : 0);
    }

    //If duration is 0, effect is permanent
    void ApplyDamageType(UTDDamageType DamageType, float Duration = 0.0f, int Amount = 1)
    {
        if (!DamageTypeInstances.Contains(DamageType))
            DamageTypeInstances.Add(DamageType, 0);
        DamageTypeInstances[DamageType] += Amount;

        if (Duration > 0.0f)
        {
            UDelayedRemoval Delayed = Cast<UDelayedRemoval>(NewObject(this, UDelayedRemoval::StaticClass()));
            Delayed.Setup(this, DamageType, Duration, Amount);
            DelayedRemovals.Add(Delayed);
        }

        Print(f"{DamageTypeInstances[DamageType] =}");
    }

    void RemoveDamageType(UTDDamageType DamageType, int Amount = 1)
    {
        if (!DamageTypeInstances.Contains(DamageType)) return;
        DamageTypeInstances[DamageType] -= Amount;

        Print(f"{DamageTypeInstances[DamageType] =}");

        if (DamageTypeInstances[DamageType] < 1)
            DamageTypeInstances.Remove(DamageType);
    }
}

class UDelayedRemoval : UObject
{
    UTDDamageTypeComponent TargetStored;
    UTDDamageType DamageTypeStored;
    float DurationStored;
    int AmountStored;
    void Setup(UTDDamageTypeComponent Target, UTDDamageType DamageType, float Duration, int Amount)
    {
        TargetStored = Target;
        DamageTypeStored = DamageType;
        DurationStored = Duration;
        AmountStored = Amount;
        System::SetTimer(this, n"Perform", Duration, false);
    }

    UFUNCTION()
    private void Perform()
    {
        if (!IsValid(TargetStored)) return;
        TargetStored.RemoveDamageType(DamageTypeStored, AmountStored);
        TargetStored.DelayedRemovals.RemoveSingleSwap(this);
    }
}

class UTDDamageType : UDataAsset
{
    UPROPERTY()
    FString DamageTypeName;
}

//If duration is 0, effect is permanent. Returns true if the target has a valid UTDDamageTypeComponent
mixin bool TryApplyDamageType(AActor Self, UTDDamageType DamageType, float& Duration = 0.0f, int& Amount = 1)
{
    UTDDamageTypeComponent Comp = Cast<UTDDamageTypeComponent>(Self.GetComponent(UTDDamageTypeComponent::StaticClass()));
    if (!IsValid(Comp)) return false;

    Comp.ApplyDamageType(DamageType, Duration, Amount);
    return true;
}