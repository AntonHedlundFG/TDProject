event void FOnDamageTypeChange(UTDDamageType DamageType, int NewAmount);

// Add this component to any actor which should be able to receive damage types. It stores damage type stacks, but does not have any built-in functionality.
// Use UDamageEffectComponents for that functionality.
class UTDDamageTypeComponent : UActorComponent
{
    private TMap<UTDDamageType, int> DamageTypeInstances;

    TArray<UDelayedRemoval> DelayedRemovals;

    UPROPERTY(NotVisible, BlueprintReadOnly, Category = "Damage Effects")
    FOnDamageTypeChange OnDamageTypeChange;

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
        OnDamageTypeChange.Broadcast(DamageType, DamageTypeInstances[DamageType]);

        if (Duration > 0.0f)
        {
            UDelayedRemoval Delayed = Cast<UDelayedRemoval>(NewObject(this, UDelayedRemoval::StaticClass()));
            Delayed.Setup(this, DamageType, Duration, Amount);
            DelayedRemovals.Add(Delayed);
        }

    }

    void RemoveDamageType(UTDDamageType DamageType, int Amount = 1)
    {
        if (!DamageTypeInstances.Contains(DamageType)) return;
        DamageTypeInstances[DamageType] -= Amount;
        OnDamageTypeChange.Broadcast(DamageType, DamageTypeInstances[DamageType]);
        if (DamageTypeInstances[DamageType] < 1)
            DamageTypeInstances.Remove(DamageType);
    }
}

//This is an internal class for UTDDamageTypeComponent, do not use it.
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

//Create Data Asset instances of this in the editor for each element.
class UTDDamageType : UDataAsset
{
    UPROPERTY()
    FString DamageTypeName;
}

//If duration is 0, effect is permanent. Returns true if the target has a valid UTDDamageTypeComponent
mixin bool TryApplyDamageType(AActor Self, UTDDamageType DamageType, float Duration = 0.0f, int Amount = 1)
{
    UTDDamageTypeComponent Comp = Cast<UTDDamageTypeComponent>(UTDDamageTypeComponent::Get(Self));
    if (!IsValid(Comp)) return false;

    Comp.ApplyDamageType(DamageType, Duration, Amount);
    return true;
}