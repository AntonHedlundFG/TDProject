event void FOnWaveStart(int waveIndex);
event void FOnWaveDownTimeStart();


class ATDGameMode : ALobbyGameMode
{
    // The time between waves
    UPROPERTY(EditAnywhere, Category = "EnemySpawn")
    float WaveDownTime = 10.0f;

    // The time until the next wave
    UPROPERTY(BlueprintReadOnly)
    float IntermissionTimer = 10.0f;

    // Current wave number / index
    int WaveIndex = -1;

    // Flag whether to run downtime method
    bool IsDownTime = false;
    
    // Array of active spawners
    TArray<ATDEnemySpawner> EnemySpawners;

    ATDGameState GameState;

    UPROPERTY()
    FOnWaveDownTimeStart OnDownTimeStart;
    UPROPERTY()
    FOnWaveStart OnWaveStart;


    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        // Set up the game state
        if (IsValid(GetWorld().GetGameState()))
        {
            GameState = Cast<ATDGameState>(GetWorld().GetGameState());
        }
        UpdateGameState();
        

        IntermissionTimer = WaveDownTime;  
        // Start the count down to the first wave
        IsDownTime = true;
        OnDownTimeStart.Broadcast();
        //StartNextWave();

    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        if(EnemySpawners.Num() <= 0) return;

        // Checks if all spawners finished spawning current wave
        CheckWaveCompleted();

        //Ticks when finished spawnig, starts next wave after set time
        DownTimeTimer(DeltaSeconds);

        // Update the game state
        UpdateGameState();
    }


    void DownTimeTimer(float DeltaSeconds)
    {
        if(!IsDownTime) return;

        IntermissionTimer -= DeltaSeconds;
        if(IntermissionTimer <= 0)
        {
            IsDownTime = false;
            WaveIndex++;
            StartNextWave();
            IntermissionTimer = WaveDownTime;
        }
    }

    void StartNextWave()
    { 
        for(int i = 0; i < EnemySpawners.Num(); i++)
        {
            EnemySpawners[i].SetCurrentWave(WaveIndex);
        }
        OnWaveStart.Broadcast(WaveIndex);
        Print(f"Wave: {WaveIndex+1}");
    }


    void CheckWaveCompleted()
    {
        if(IsDownTime) return;

        for(int i = 0; i < EnemySpawners.Num(); i++)
        {
            if(!EnemySpawners[i].IsWaveComplete)
            {
                return;
            }
        }

        OnDownTimeStart.Broadcast();
        IsDownTime = true;
    }

    void UpdateGameState()
    {

    }

    void OnEnemyReachedGoal(ATDEnemy Enemy)
    {
        // Remove health from gamestate
        GameState.DamageHealth(Enemy.Damage);
    }

    void RegisterSpawner(ATDEnemySpawner Spawner)
    {
        // Add the spawner to the array
        EnemySpawners.Add(Spawner);
    }

    void UnregisterSpawner(ATDEnemySpawner Spawner)
    {
        // Remove the spawner from the array
        EnemySpawners.RemoveSingle(Spawner);
    }

}