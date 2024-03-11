event void FOnGameLostEvent();
event void FOnHealthChangedEvent();

class ATDGameState : AGameStateBase
{
    default bReplicates = true;
    default bAlwaysRelevant = true;

    UPROPERTY()
    FOnGameLostEvent OnGameLostEvent;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Replicated)
    bool bGameIsLost = false;

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

    UPROPERTY(Replicated)
    float NextCountdownEndTime = 0.0f;

    UFUNCTION(BlueprintCallable)
    float GetRemainingCountdownTime()
    {
        float CurrentTime = Gameplay::GameState.ServerWorldTimeSeconds;
        return Math::Max(0.0f, NextCountdownEndTime - CurrentTime);
    }    

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Initialize();
    }
    
    UFUNCTION()
    void OnRep_CurrentHealth()
    {
        OnHealthChangedEvent.Broadcast();
        if(CurrentHealth <= 0)
        {
            HandleGameLost();
        }
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
    
        
    }

    UFUNCTION()
    void HandleGameLost()
    {
        OnGameLostEvent.Broadcast();
        bGameIsLost = true;
    }

}