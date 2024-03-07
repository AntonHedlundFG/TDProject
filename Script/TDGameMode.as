event void FOnWaveStart(int waveIndex);
event void FOnWaveDownTimeStart();


class ATDGameMode : ALobbyGameMode
{
    // The time between waves
    UPROPERTY(EditAnywhere, Category = "EnemySpawn")
    float WaveIntermissionTime = 10.0f;

    // Current wave number / index
    int WaveIndex = -1;

    // Flag whether to run downtime method
    bool IsDownTime = true;

    UPROPERTY(BlueprintReadOnly, VisibleAnywhere, Category = "EnemySpawn")
    bool bHasManuallyStarted = false;

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
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        if(EnemySpawners.Num() <= 0) return;

        // Checks if all spawners finished spawning current wave
        CheckWaveCompleted();

        // Checks when intermission time is over, then starts next wave after
        CheckIntermission();

        // Update the game state
        UpdateGameState();
    }


    void CheckIntermission()
    {
        if(!IsDownTime || !bHasManuallyStarted) return;

        if(GameState.GetRemainingCountdownTime() <= 0)
        {
            IsDownTime = false;
            WaveIndex++;
            StartNextWave();
        }
    }

    void StartNextWave()
    { 
        for(int i = 0; i < EnemySpawners.Num(); i++)
        {
            EnemySpawners[i].SetCurrentWave(WaveIndex);
        }
        OnWaveStart.Broadcast(WaveIndex);
        GameState.bRoundIsOngoing = true;
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
        GameState.NextCountdownEndTime = GameState.ServerWorldTimeSeconds + WaveIntermissionTime;
        GameState.bRoundIsOngoing = false;
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

    UFUNCTION(BlueprintCallable, Category = "EnemySpawn")
    void ManuallyProgressGame()
    {
        if (!bHasManuallyStarted)
        {
            bHasManuallyStarted = true;
            GameState.bGameHasStarted = true;
        }
        GameState.NextCountdownEndTime = 0.0f;
    }

}