class ATDEnemySpawner : AActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent)
    USplineComponent Path;

    UPROPERTY(Category = "Spawner Settings")
    TSubclassOf<ATDEnemy> Enemy;


    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        SpawnEnemy(Enemy);
    }

    void SpawnEnemy(TSubclassOf<ATDEnemy> enemy)
    {
        FVector pos = GetActorLocation();
        FRotator rot = GetActorRotation();
        ATDEnemy SpawnedEnemy = Cast<ATDEnemy>(SpawnActor(enemy, pos, rot));

        SpawnedEnemy.Path = Path;
        SpawnedEnemy.IsActive = true;
    }
};