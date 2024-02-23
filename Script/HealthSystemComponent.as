

delegate void OnHealthChanged(float CurrentHealth, float MaxHealth);

class UHealthSystemComponent : UActorComponent
{

    OnHealthChanged HealthChangedDelegate;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Health")
    float MaxHealth;

    UPROPERTY(BlueprintReadOnly, Category = "Health")
    float CurrentHealth;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        CurrentHealth = MaxHealth;
        HealthChangedDelegate.ExecuteIfBound(CurrentHealth, MaxHealth);
    }

    UFUNCTION(BlueprintCallable, Category = "Health")
    void TakeDamage(float DamageAmount)
    {
        CurrentHealth -= DamageAmount;
        HealthChangedDelegate.ExecuteIfBound(CurrentHealth, MaxHealth);

        Print(f"{GetOwner().GetName()} has taken {DamageAmount} damage");

        if (CurrentHealth <= 0)
        {
            Print(f"{GetOwner().GetName()} has died");
        }
    }

    UFUNCTION(BlueprintCallable, Category = "Health")
    void Heal(float HealAmount)
    {
        CurrentHealth += HealAmount;
        if (CurrentHealth > MaxHealth)
        {
            CurrentHealth = MaxHealth;
        }
        HealthChangedDelegate.ExecuteIfBound(CurrentHealth, MaxHealth);
    }
    
};