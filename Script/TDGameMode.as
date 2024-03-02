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

    // The number of enemies to spawn per wave
    UPROPERTY(EditAnywhere, Category = "EnemySpawn")
    int EnemiesPerWave = 10;

    // The number of enemies left to spawn
    int NumEnemiesToSpawn = 0;

    // Current wave number
    int WaveNumber = 0;

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

        SpawnTimer += DeltaSeconds;
        if(SpawnTimer >= SpawnInterval)
        {
            SpawnTimer = 0;
            for(int i = 0; i < EnemySpawners.Num(); i++)
            {
                EnemySpawners[i].SpawnEnemy(GameState.DifficultyLevel);
            }
        }


        // Check if the wave is completed
        if (IsWaveCompleted())
        {
            // Start the next wave
            StartNextWave();
        }

        // Update the game state
        UpdateGameState();
    }

    void SpawnEnemy()
    {
        // Spawn Enemies as long as there are still enemies to spawn
        if(NumEnemiesToSpawn > 0)
        {
            // Spawn an enemy
            SpawnEnemy();

            // Decrement the number of enemies to spawn
            NumEnemiesToSpawn--;
        }

        // If there are no more enemies to spawn, clear the spawn timer
        if(NumEnemiesToSpawn <= 0)
        {
            //System::ClearTimer(SpawnTimerHandle);
        }
    }

    void StartNextWave()
    {
        // Increment the wave number
        WaveNumber++;

        // Set the number of enemies to spawn
        NumEnemiesToSpawn += EnemiesPerWave;

        // Set the spawn time
        TimeUntilNextWave = WaveTime;

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