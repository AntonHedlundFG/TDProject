
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
    UPROPERTY()
    int DifficultyLevel = 0;
    UPROPERTY()
    float SpawnTimer = 0;
    UPROPERTY()
    float SpawnInterval = 5;

    UPROPERTY()
    TArray<ATDEnemySpawner> Spawners;

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaTime)
    {
        SpawnAtInterval(DeltaTime);
    }

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

    UFUNCTION()
    void SpawnAtInterval(float DeltaTime)
    {
        if(Spawners.Num() <= 0) return;

        SpawnTimer += DeltaTime;
        if(SpawnTimer >= SpawnInterval)
        {
            SpawnTimer = 0;
            for(int i = 0; i < Spawners.Num(); i++)
            {
                Spawners[i].SpawnEnemy(DifficultyLevel);
            }
        }
    }
}