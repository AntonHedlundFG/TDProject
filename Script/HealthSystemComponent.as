
delegate void HealthChanged(float CurrentHealth, float MaxHealth);

class UHealthSystemComponent : UActorComponent
{
    default bReplicates = true;

    UPROPERTY(Replicated)
    HealthChanged OnHealthChanged;

    UPROPERTY(Replicated, EditAnywhere, BlueprintReadWrite, Category = "Health")
    float MaxHealth;

    UPROPERTY(Replicated, BlueprintReadOnly, ReplicatedUsing = OnRep_HealthCalueChanged, Category = "Health")
    float CurrentHealth;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        CurrentHealth = MaxHealth;
        OnHealthChanged.ExecuteIfBound(CurrentHealth, MaxHealth);
        Print(f"Health System Component has been initialized for {GetOwner().GetName()}");
    }

    UFUNCTION(Server, BlueprintCallable, Category = "Health")
    void ServerTakeDamage(float DamageAmount)
    {
        CurrentHealth -= DamageAmount;
        OnHealthChanged.ExecuteIfBound(CurrentHealth, MaxHealth);

        Print(f"{GetOwner().GetName()} has taken {DamageAmount} damage");
        if (CurrentHealth <= 0)
        {
            // Destroy actor 
            GetOwner().DestroyActor();
        }

    }

    UFUNCTION(Server, BlueprintCallable, Category = "Health")
    void ServerHeal(float HealAmount)
    {
        CurrentHealth += HealAmount;
        if (CurrentHealth > MaxHealth)
        {
            CurrentHealth = MaxHealth;
        }
        OnHealthChanged.ExecuteIfBound(CurrentHealth, MaxHealth);
    }

    UFUNCTION()
    void OnRep_HealthCalueChanged()
    {
        Print(f"Health value has been changed to {CurrentHealth} for {GetOwner().GetName()}");
    }


};