event void FOnGameLostEvent();
event void FOnHealthChangedEvent();

class ATDGameState : AGameStateBase
{
    default bReplicates = true;
    default bAlwaysRelevant = true;

    UPROPERTY()
    FOnGameLostEvent OnGameLostEvent;

    UPROPERTY()
    FOnHealthChangedEvent OnHealthChangedEvent;

    UPROPERTY(Replicated, ReplicatedUsing = OnRep_CurrentHealth)
    int CurrentHealth;

    UPROPERTY()
    int MaxHealth = 10;

    UPROPERTY()
    int DifficultyLevel = 0;

    UPROPERTY(BlueprintReadOnly, VisibleAnywhere, Replicated)
    bool bGameHasStarted = false;

    UPROPERTY(BlueprintReadOnly, VisibleAnywhere, Replicated)
    bool bRoundIsOngoing = false;    

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Initialize();
    }
    
    UFUNCTION()
    void OnRep_CurrentHealth()
    {
        OnHealthChangedEvent.Broadcast();
    }

    void Initialize()
    {
        if(System::IsServer())
        {
            SetHealth(MaxHealth);
        }
    }

    void DamageHealth(int Damage)
    {
        if(!System::IsServer()) return;

        SetHealth(CurrentHealth - Damage);
    }

    void SetHealth(int NewHealth)
    {
        if(!System::IsServer()) return;

        CurrentHealth = Math::Clamp(NewHealth, 0, MaxHealth);

        OnRep_CurrentHealth();
        
        if(CurrentHealth <= 0)
        {
            OnGameLostEvent.Broadcast();
        }
        
    }

    UFUNCTION()
    void HandleGameLost()
    {
        OnGameLostEvent.Broadcast();
    }

}