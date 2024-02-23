class ATestEnemyPath : AActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent)
    USplineComponent Spline;

    UPROPERTY(Category = "Path Settings")
    TArray<FVector> Points;

    UPROPERTY(Category = "Path Settings")
    TSubclassOf<ATestEnemy> Enemy;


    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        FVector pos = GetActorLocation();
        FRotator rot = GetActorRotation();
        ATestEnemy SpawnedActor = Cast<ATestEnemy>(SpawnActor(Enemy, pos, rot));

        SpawnedActor.Spline = Spline;
        FString length = "" + Spline.GetSplineLength();

        Print(length);
    }
};