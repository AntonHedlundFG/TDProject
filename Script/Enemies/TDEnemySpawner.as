class ATDEnemySpawner : AActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent)
    USplineComponent Path;
    UPROPERTY(DefaultComponent)
    URoadMeshComponent RoadMesh;
    UPROPERTY()
    ATDGameMode GameMode;

    // Is currently spawning wave or not
    UPROPERTY()
    bool IsWaveComplete = true;
    private bool IsWaveEmpty = false;

    // Current wave enemies and amount, gotten from wave info
    TArray<TSubclassOf<ATDEnemy>> WaveUnits;
    TArray<int> WaveAmounts;

    // Enemies of a certain type left to spawn in current wave
    int NumEnemiesOfType = 0;

    // The number of enemies left to spawn
    int NumEnemiesToSpawn = 0;

    // Holds the info of all the enemy waves
    UPROPERTY(EditAnywhere, Category = "EnemySpawn")
    UTDEnemyWaveInfo WaveInfo;

    // The time between each spawn
    UPROPERTY(EditAnywhere, Category = "EnemySpawn")
    float DefaultSpawnInterval = 4.0f;
    float SpawnInterval;
    float SpawnTimer = 0.0f;

    UObjectPoolSubsystem PoolSubsystem;


    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        GameMode = Cast<ATDGameMode>(Gameplay::GetGameMode());
        if(IsValid(GameMode))
            GameMode.RegisterSpawner(this);

        PoolSubsystem = UObjectPoolSubsystem::Get();

    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        SpawnWave(DeltaSeconds);
    }


    void SpawnWave(float DeltaSeconds)
    {
        if(IsWaveComplete) return;

        

        // if finished spawning current unit type, remove it and check if there is another type to start spawning
        if(NumEnemiesOfType <= 0 && !IsWaveEmpty)
        {
            WaveAmounts.RemoveAt(0);
            WaveUnits.RemoveAt(0);

            if(WaveAmounts.Num() > 0 && WaveUnits.Num() > 0)
            {
                NumEnemiesOfType = WaveAmounts[0];
            }
            else 
            {
                // if finished spawning all units in the wave, flag spawner as finished after end of next timer  
                IsWaveEmpty = true;
            }
        }

        SpawnTimer += DeltaSeconds;
        if(SpawnTimer >= SpawnInterval)
        {
            if(IsWaveEmpty)
            {
                // flag spawner as finished with current wave
                IsWaveComplete = true;
                return;
            }
            //spawn unit if valid, "pause" spawning if not
            if(WaveUnits[0] != nullptr)
                SpawnEnemy(WaveUnits[0]);
            

            SpawnTimer = 0;
            NumEnemiesOfType--;
        }
    }

    void SetCurrentWave(int index)
    {
        // Check if next wave is valid, then set new current wave
        if(index >= WaveInfo.Waves.Num())
        {
            Print("Empty Wave List");
             return;
        }

        FWave CurrentWave = WaveInfo.Waves[index];

        WaveUnits.Empty();
        WaveAmounts.Empty();

        // fill arrays with unit types and amount
        for(auto section : CurrentWave.WaveSections)
        {
            WaveUnits.Add(section.unit);
            WaveAmounts.Add(section.amount);
        }

        NumEnemiesOfType = WaveAmounts[0];

        SpawnInterval = CurrentWave.SpawnFrequency <= 0 ? DefaultSpawnInterval : CurrentWave.SpawnFrequency;
        SpawnTimer = SpawnInterval;

        IsWaveComplete = false;
        IsWaveEmpty = false;
    }

    void SpawnEnemy(TSubclassOf<ATDEnemy> enemy)
    {
        if(!System::IsServer()) return;

        //if(Enemies[index] == nullptr) return;
         
        FVector pos = GetActorLocation();
        FRotator rot = GetActorRotation();
        //ATDEnemy SpawnedEnemy = Cast<ATDEnemy>(SpawnActor(enemy, pos, rot));
        
        ATDEnemy SpawnedEnemy = Cast<ATDEnemy>(PoolSubsystem.GetObject(enemy, pos, rot));

        SpawnedEnemy.OnUnitSpawn(Path);
    }
};