class ATDGameMode : ALobbyGameMode
{
    // Timer handle for the spawn timer
    FTimerHandle SpawnTimerHandle;
    float SpawnTimer = 0.0f;

    // The time between each spawn
    UPROPERTY(EditAnywhere, Category = "EnemySpawn")
    float SpawnInterval = 4.0f;

    // The time between waves
    UPROPERTY(EditAnywhere, Category = "EnemySpawn")
    float WaveTime = 10.0f;

    // The time until the next wave
    float TimeUntilNextWave = 10.0f;

    // Holds the info of all the enemy waves
    UPROPERTY(EditAnywhere, Category = "EnemySpawn")
    UTDEnemyWaveInfo WaveInfo;

    // Current wave enemies and amount, gotten from wave info
    TArray<TSubclassOf<ATDEnemy>> WaveUnits;
    TArray<int> WaveAmounts;

    // Enemies of a certain type left to spawn in current wave
    int NumEnemiesOfType = 0;

    // The number of enemies to spawn per wave
    UPROPERTY(EditAnywhere, Category = "EnemySpawn")
    int EnemiesPerWave = 10;

    // The number of enemies left to spawn
    int NumEnemiesToSpawn = 0;

    // Current wave number (will immediately increment to 0)
    int WaveNumber = -1;

    // Flag whether to run spawn method
    bool IsSpawning = false;

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
        

        // Start the first wave
        StartNextWave();

    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        if(EnemySpawners.Num() <= 0) return;

        //Spawns enemies, based on wave info, from each spawner at set intervals
        SpawnEnemies(DeltaSeconds);

        //Ticks when finished spawnig, starts next wave after set time
        DownTimeTimer(DeltaSeconds);

        // Update the game state
        UpdateGameState();
    }

    void SpawnEnemies(float DeltaSeconds)
    {
        if(!IsSpawning) return;

        if(NumEnemiesOfType <= 0)
        {
            WaveAmounts.RemoveAt(0);
            WaveUnits.RemoveAt(0);

            if(WaveAmounts.Num() > 0 && WaveUnits.Num() > 0)
            {
                NumEnemiesOfType = WaveAmounts[0];
            }
            else 
            {
                IsSpawning = false;
                IsDownTime = true;
            }
        }

        SpawnTimer += DeltaSeconds;
        if(SpawnTimer >= SpawnInterval)
        {

            for(int i = 0; i < EnemySpawners.Num(); i++)
            {
                EnemySpawners[i].SpawnEnemy(WaveUnits[0]);
            }

            SpawnTimer = 0;
            NumEnemiesOfType--;
        }
    }

    void DownTimeTimer(float DeltaSeconds)
    {
        if(!IsDownTime) return;

        WaveTime -= DeltaSeconds;
        if(WaveTime <= 0)
        {
            IsDownTime = false;
            StartNextWave();
            WaveTime = TimeUntilNextWave;
        }
    }

    void StartNextWave()
    {
        // Increment the wave number
        WaveNumber++;

        // Check if next wave is valid, then set new current wave
        if(WaveNumber >= WaveInfo.WaveArray.Num())
        {
            Print("Empty Wave List");
             return;
        }
        FWave CurrentWave = WaveInfo.WaveArray[WaveNumber];
        Print(CurrentWave.WaveName);

        WaveUnits.Empty();
        WaveAmounts.Empty();
        for(auto pair : CurrentWave.WaveMap)
        {
            WaveUnits.Add(pair.Key);
            WaveAmounts.Add(pair.Value);
        }

        // Set the number of the first enemy type to spawn, start spawning
        NumEnemiesOfType = WaveAmounts[0];
        IsSpawning = true;
    }

    bool IsWaveCompleted()
    {
        return NumEnemiesToSpawn <= 0 && TimeUntilNextWave <= 0;
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