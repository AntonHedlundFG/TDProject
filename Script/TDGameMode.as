class ATDGameMode : ALobbyGameMode
{
    // The time between waves
    UPROPERTY(EditAnywhere, Category = "EnemySpawn")
    float WaveTime = 10.0f;

    // The time until the next wave
    float TimeUntilNextWave = 10.0f;

    // Current wave number / index
    int WaveNumber = 0;

    // Flag whether to run downtime method
    bool IsDownTime = false;
    
    // Array of active spawners
    TArray<ATDEnemySpawner> EnemySpawners;

    ATDGameState GameState;


    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        // Set up the game state
        if (IsValid(GetWorld().GetGameState()))
        {
            GameState = Cast<ATDGameState>(GetWorld().GetGameState());
        }
        UpdateGameState();
        

        TimeUntilNextWave = WaveTime;  
        // Start the first wave
        StartNextWave();

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

        WaveTime -= DeltaSeconds;
        if(WaveTime <= 0)
        {
            IsDownTime = false;
            WaveNumber++;
            StartNextWave();
            WaveTime = TimeUntilNextWave;
        }
    }

    void StartNextWave()
    { 
        for(int i = 0; i < EnemySpawners.Num(); i++)
        {
            EnemySpawners[i].SetCurrentWave(WaveNumber);
        }
        Print(f"Wave: {WaveNumber+1}");
    }


    void CheckWaveCompleted()
    {
        if(IsDownTime) return;

        for(int i = 0; i < EnemySpawners.Num(); i++)
        {
            if(EnemySpawners[i].IsSpawning)
            {
                return;
            }
        }

        Print("Wave Finished");
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