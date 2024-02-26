event void FOnGameLostEvent();
event void FOnHealthChangedEvent();

class UTDGameLoopManager : UScriptWorldSubsystem
{
    FOnGameLostEvent OnGameLost;
    FOnHealthChangedEvent OnHealthChanged;


    UPROPERTY()
    int MaxHealth = 10;
    UPROPERTY()
    int CurrentHealth = 10;

    UFUNCTION(BlueprintOverride)
    void OnWorldBeginPlay()
    {
        SetHealth(MaxHealth);
    }

    UFUNCTION()
    void LooseHealth(ATDEnemy enemy)
    {
        if(!System::IsServer()) return;

        if(enemy == nullptr) return;

        CurrentHealth -= enemy.PointValue;
        Print("Remaining Health: " + CurrentHealth);
        if(CurrentHealth <= 0)
        {
            OnGameLost.Broadcast();
        }
        else
        {
            OnHealthChanged.Broadcast();
        }
    }

    UFUNCTION()
    void SetHealth(int value)
    {
        if(!System::IsServer()) return;

        if(value <= 0) return;

        CurrentHealth = value>MaxHealth ? MaxHealth : value;

        OnHealthChanged.Broadcast();
    }
}