
delegate void HealthChanged(float CurrentHealth, float MaxHealth);

class UHealthSystemComponent : UActorComponent
{
    default bReplicates = true;

    UPROPERTY()
    HealthChanged OnHealthChanged;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Health")
    float MaxHealth;

    UPROPERTY(VisibleAnywhere, Replicated, BlueprintReadOnly, ReplicatedUsing = OnRep_HealthCalueChanged, Category = "Health")
    float CurrentHealth;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        SetHealth(MaxHealth);
    }

    UFUNCTION(BlueprintCallable, Category = "Health")
    void TakeDamage(float DamageAmount)
    {
        if(!System::IsServer())
        {
            return;
        }

        float NewHealth = CurrentHealth - DamageAmount;
        SetHealth(NewHealth);
    }

    UFUNCTION(Server, BlueprintCallable, Category = "Health")
    void Heal(float HealAmount)
    {
        if(!System::IsServer())
        {
            return;
        }

        float NewHealth = CurrentHealth + HealAmount;
        SetHealth(NewHealth);
    }

    UFUNCTION()
    void OnRep_HealthCalueChanged()
    {
        OnHealthChanged.ExecuteIfBound(CurrentHealth, MaxHealth);
    }

    // Should only be called by the server
    private void SetHealth(float NewHealth)
    {
        CurrentHealth =  Math::Clamp(NewHealth, 0.0f, MaxHealth);
        OnRep_HealthCalueChanged();
    }


};