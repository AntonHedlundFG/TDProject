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

    UPROPERTY(Category = "Spawner Settings")
    TArray<TSubclassOf<ATDEnemy>> Enemies;


    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        GameMode = Cast<ATDGameMode>(Gameplay::GetGameMode());
        if(IsValid(GameMode))
            GameMode.RegisterSpawner(this);
    }

    void SpawnEnemy(int index)
    {
        if(!System::IsServer()) return;

        if(Enemies[index] == nullptr) return;
         
        FVector pos = GetActorLocation();
        FRotator rot = GetActorRotation();
        ATDEnemy SpawnedEnemy = Cast<ATDEnemy>(SpawnActor(Enemies[index], pos, rot));

        SpawnedEnemy.OnUnitSpawn(Path);

    }
};