class ATDEnemy : AActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;
    UPROPERTY(DefaultComponent)
    USkeletalMeshComponent Mesh;
    UPROPERTY(DefaultComponent)
    UHealthSystemComponent HealthComponent;
    UPROPERTY()
    USplineComponent Path;

    UPROPERTY(BlueprintReadWrite)
    float MoveSpeed = 500;
    UPROPERTY(NotEditable)
    float LerpAlpha = 0;

    UPROPERTY(BlueprintReadWrite, Category = "Enemy Settings")
    bool IsActive = false;


    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        MoveAlongSpline(DeltaSeconds);
    }

    void MoveAlongSpline(float DeltaSeconds)
    {
        if(Path == nullptr || !IsActive) return;

        float Length = Path.GetSplineLength();
        if(LerpAlpha >= 1.f)
        {
            Print("Goal Reached");
            IsActive = false;
            LerpAlpha = 0;
            return;
        }

        LerpAlpha += (MoveSpeed / Length) * DeltaSeconds;

        float distance = Math::Lerp(0, Length, LerpAlpha);

        FTransform tf = Path.GetTransformAtDistanceAlongSpline(distance, ESplineCoordinateSpace::World);

        SetActorLocation(tf.Location);
        SetActorRotation(tf.Rotation);
    }
};