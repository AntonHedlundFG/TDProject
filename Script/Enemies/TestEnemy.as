class ATestEnemy : APawn
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent)
    UStaticMeshComponent Mesh;

    UPROPERTY()
    USplineComponent Spline;

    UPROPERTY()
    float MoveSpeed = 500;

    UPROPERTY()
    float LerpAlpha = 0;

    UPROPERTY(Category = "Enemy Settings")
    FVector TargetPosition;

    UPROPERTY(Category = "Enemy Settings")
    int iHealth = 1;

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        if(Spline != nullptr)
            MoveAlongSpline(DeltaSeconds);
    }

    void MoveAlongSpline(float DeltaSeconds)
    {
        float Length = Spline.GetSplineLength();
        if(LerpAlpha >= Length)
            return;

        LerpAlpha += (MoveSpeed / Length) * DeltaSeconds;

        float distnace = Math::Lerp(0, Length, LerpAlpha);

        FTransform tf = Spline.GetTransformAtDistanceAlongSpline(distnace, ESplineCoordinateSpace::World);

        SetActorLocation(tf.Location);
        SetActorRotation(tf.Rotation);
    }
};