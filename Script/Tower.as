class ATower : AActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent Mesh;

    UPROPERTY(Category = "Tower")
    int32 Cost = 100;

    UPROPERTY(Category = "Tower")
    int32 Damage = 1;

    UPROPERTY(Category = "Tower")
    float Range = 1000.0f;

    UPROPERTY(Category = "Tower")
    float FireRate = 1.0f;

    UPROPERTY(Category = "Tower")
    TSubclassOf<AProjectile> ProjectileClass;

    UPROPERTY(DefaultComponent, Attach = Root)
    USceneComponent FirePoint;

    float Timer = 0.0f;


    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        Timer += DeltaSeconds;
        if (Timer >= FireRate)
        {
            Timer = 0.0f;
            Fire();
        }
    }

    UFUNCTION()
    void Fire()
    {
        if (ProjectileClass != nullptr)
        {
            FRotator Direction = FirePoint.GetWorldRotation();
            AProjectile Projectile = Cast<AProjectile>(SpawnActor(ProjectileClass, FirePoint.GetWorldLocation(), Direction));
        }
    }
};