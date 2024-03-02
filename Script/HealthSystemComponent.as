

event void FHealthChanged(int32 CurrentHealth, int32 MaxHealth);

class UHealthSystemComponent : UActorComponent
{
    default bReplicates = true;

    UPROPERTY(BlueprintReadWrite, Replicated)
    FHealthChanged OnHealthChanged;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Health")
    int32 MaxHealth;

    UPROPERTY(VisibleAnywhere, Replicated, BlueprintReadOnly, ReplicatedUsing = OnRep_HealthValueChanged, Category = "Health")
    int32 CurrentHealth;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        SetHealth(MaxHealth);
    }

    UFUNCTION(BlueprintCallable, Category = "Health")
    void TakeDamage(int32 DamageAmount)
    {
        if(!System::IsServer())
        {
            return;
        }

        int32 NewHealth = CurrentHealth - DamageAmount;
        SetHealth(NewHealth);
    }

    UFUNCTION(Server, BlueprintCallable, Category = "Health")
    void Heal(int32 HealAmount)
    {
        if(!System::IsServer())
        {
            return;
        }

        int32 NewHealth = CurrentHealth + HealAmount;
        SetHealth(NewHealth);
    }

    UFUNCTION()
    void OnRep_HealthValueChanged()
    {
        OnHealthChanged.Broadcast(CurrentHealth, MaxHealth);
    }

    // Should only be called by the server
    private void SetHealth(int32 NewHealth)
    {
        CurrentHealth =  Math::Clamp(NewHealth, 0.0f, MaxHealth);
        OnRep_HealthValueChanged();
    }

    UFUNCTION()
    bool IsAlive()
    {
        return CurrentHealth > 0;
    }

};