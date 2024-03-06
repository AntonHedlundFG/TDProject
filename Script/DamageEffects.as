class UDamageEffectComponent : UActorComponent
{
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Damage Effects")
    UTDDamageType DamageType;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Damage Effects")
    bool bAffectedByMultipleStacks = true;

    UPROPERTY(VisibleAnywhere, BlueprintReadWrite, Category = "Damage Effects")
    bool bEffectActive = true;

    protected UTDDamageTypeComponent ComponentRef;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        ComponentRef = UTDDamageTypeComponent::Get(Owner);
        if (!IsValid(ComponentRef) || !IsValid(DamageType))
        {
            SetActive(false);
            return;
        }
    }
}

event void FTickDamageDelegate(int Amount);
class UDamageTypeMultiplier : UDamageEffectComponent
{
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Damage Effects")
    float MultiplierPerStack = 0.8f;

    UPROPERTY(NotVisible, BlueprintReadOnly, Category = "Damage Effects")
    FTickDamageDelegate TickDamageDelegate;

    UFUNCTION()
    float GetValue()
    {
        if (!bEffectActive || !IsValid(ComponentRef) || !IsValid(DamageType)) return 1.0f;

        int Effects = ComponentRef.GetEffectsOfType(DamageType);
        if (Effects == 0) return 1.0f; // No stacks
        if (!bAffectedByMultipleStacks) return MultiplierPerStack; // Single stack
        return Math::Pow(MultiplierPerStack, Effects); // Multiple stacks
    }
}

class UDamageTypeOverTime : UDamageEffectComponent
{
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Damage Effects")
    float DPSPerStack = 50.0f;

    private UHealthSystemComponent HealthCompRef;

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        if (!bEffectActive) return;
        int Amount = ComponentRef.GetEffectsOfType(DamageType);
        if (Amount < 1) return;
        float TotalDPS = (bAffectedByMultipleStacks ? Amount * DPSPerStack : DPSPerStack);
        int DamageThisTick = TotalDPS * DeltaSeconds;
        HealthCompRef.TakeDamage(DamageThisTick);
    }
    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Super::BeginPlay();
        HealthCompRef = UHealthSystemComponent::Get(Owner);
    }
}