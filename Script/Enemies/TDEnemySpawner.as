class ATDEnemySpawner : AActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent)
    USplineComponent Path;

    UPROPERTY(Category = "Spawner Settings")
    TArray<TSubclassOf<ATDEnemy>> Enemies;


    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        SpawnEnemy(Enemies[0]);
    }

    void SpawnEnemy(TSubclassOf<ATDEnemy> enemy)
    {
        if(!System::IsServer()) return;

        if(enemy == nullptr) return;
         
        FVector pos = GetActorLocation();
        FRotator rot = GetActorRotation();
        ATDEnemy SpawnedEnemy = Cast<ATDEnemy>(SpawnActor(enemy, pos, rot));

        SpawnedEnemy.OnUnitSpawn(Path);

        SpawnedEnemy.OnGoalReached.AddUFunction(UTDGameLoopManager::Get(), n"LooseHealth");
    }
};