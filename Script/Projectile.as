class AProjectile : AActor
{
    default bReplicates = true;
    default LifeSpan = 3.0f;

    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent Mesh;

    UPROPERTY(Replicated)
    FVector ProjectileVelocity;


    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        ProjectileVelocity = GetActorForwardVector() * 1000.0f;
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        SetActorLocation(GetActorLocation() + ProjectileVelocity * DeltaSeconds);
    }
};