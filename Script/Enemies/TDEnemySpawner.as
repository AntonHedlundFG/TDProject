class ATDEnemySpawner : AActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent)
    USplineComponent Path;
    UPROPERTY(DefaultComponent)
    URoadMeshComponent RoadMesh;

    UPROPERTY()
    UTDGameLoopManager LoopManager;

    UPROPERTY(Category = "Spawner Settings")
    TArray<TSubclassOf<ATDEnemy>> Enemies;


    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        LoopManager = UTDGameLoopManager::Get();
        if(LoopManager != nullptr)
            LoopManager.Spawners.Add(this);
        SpawnEnemy(0);
    }

    void SpawnEnemy(int index)
    {
        if(!System::IsServer()) return;

        if(Enemies[index] == nullptr) return;
         
        FVector pos = GetActorLocation();
        FRotator rot = GetActorRotation();
        ATDEnemy SpawnedEnemy = Cast<ATDEnemy>(SpawnActor(Enemies[index], pos, rot));

        SpawnedEnemy.OnUnitSpawn(Path);

        if(LoopManager != nullptr)
            SpawnedEnemy.OnGoalReached.AddUFunction(LoopManager, n"LooseHealth");
    }
};