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
        FVector pos = GetActorLocation();
        FRotator rot = GetActorRotation();
        ATDEnemy SpawnedActor = Cast<ATDEnemy>(SpawnActor(Enemy, pos, rot));

        SpawnedActor.Path = Path;
        SpawnedActor.IsActive = true;
    }
};