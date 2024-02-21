class AProjectile : AActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent Mesh;

    FVector ProjectileVelocity;


    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        SetLifeSpan(3.0f);
        ProjectileVelocity = GetActorForwardVector() * 1000.0f;
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        SetActorLocation(GetActorLocation() + ProjectileVelocity * DeltaSeconds);
    }
};