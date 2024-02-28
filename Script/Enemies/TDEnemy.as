event void FOnEnemySpawnEvent(ATDEnemy Enemy);
event void FOnEnemyDeathEvent(ATDEnemy Enemy);
event void FOnEnemyGoalReachedEvent(ATDEnemy Enemy);


class ATDEnemy : AActor
{
    default bReplicates = true;
    default bReplicateMovement = true;

    FOnEnemySpawnEvent OnEnemySpawn;
    FOnEnemyDeathEvent OnEnemyDeath;
    

    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;
    UPROPERTY(DefaultComponent)
    USkeletalMeshComponent Mesh;
    UPROPERTY(DefaultComponent)
    UHealthSystemComponent HealthComponent;
    UPROPERTY()
    USplineComponent Path;


    UPROPERTY(BlueprintReadWrite, Category = "Enemy Settings")
    int PointValue = 1;
    UPROPERTY(BlueprintReadWrite, Category = "Enemy Settings")
    int KillBounty = 1;
    UPROPERTY(BlueprintReadWrite, Category = "Enemy Settings")
    int Damage = 1;
    UPROPERTY(BlueprintReadWrite, Category = "Enemy Settings")
    float MoveSpeed = 500;
    UPROPERTY(BlueprintReadWrite, Category = "Enemy Settings")
    bool IsActive = false;

    // Object Registry
    UObjectRegistry ObjectRegistry;
    UPROPERTY(EditDefaultsOnly, Category = "Object Registry")
    ERegisteredObjectTypes RegisteredObjectType = ERegisteredObjectTypes::ERO_Monster;


    UPROPERTY(NotEditable)
    float LerpAlpha = 0;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        ObjectRegistry = UObjectRegistry::Get();
        if(IsValid(ObjectRegistry)) 
        {
            ObjectRegistry.RegisterObject(this, RegisteredObjectType);
        }
        else
        {
            Print("Object Registry is not valid");
        }
    }

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason EndPlayReason)
    {
        if(IsValid(ObjectRegistry)) 
        {
            ObjectRegistry.DeregisterObject(this, RegisteredObjectType); // TODO: Change when we can test with enemies
        }
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        MoveAlongSpline(DeltaSeconds);
    }

    UFUNCTION()
    void OnUnitSpawn(USplineComponent path)
    {
        Path = path;
        IsActive = true;
        OnEnemySpawn.Broadcast(this);
    }

    UFUNCTION()
    void OnUnitDeath()
    {
        Path = nullptr;
        IsActive = false;
        OnEnemyDeath.Broadcast(this);
    }

    UFUNCTION()
    void MoveAlongSpline(float DeltaSeconds)
    {
        if(Path == nullptr || !IsActive) return;

        float Length = Path.GetSplineLength();
        if(LerpAlpha >= 1.f)
        {
            Print("Goal Reached");
            ATDGameMode gameMode = Cast<ATDGameMode>(Gameplay::GetGameMode());
            if(gameMode != nullptr)
            {
                gameMode.OnEnemyReachedGoal(this);
            }
            IsActive = false;
            LerpAlpha = 0;
            /////
            this.DestroyActor();
            /////
            return;
        }

        LerpAlpha += (MoveSpeed / Length) * DeltaSeconds;

        float distance = Math::Lerp(0, Length, LerpAlpha);

        FTransform tf = Path.GetTransformAtDistanceAlongSpline(distance, ESplineCoordinateSpace::World);

        SetActorLocation(tf.Location);
        SetActorRotation(tf.Rotation);
    }
};