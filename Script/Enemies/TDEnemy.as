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
    UStaticMeshComponent Mesh;
    UPROPERTY(DefaultComponent)
    UHealthSystemComponent HealthSystemComponent;
    UPROPERTY()
    USplineComponent Path;

    UPROPERTY(BlueprintReadWrite, Category = "Enemy Settings")
    UTDEnemyData EnemyData;

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

    UPROPERTY(NotEditable)
    float LerpAlpha = 0;

    //Damage Type effects
    UPROPERTY(DefaultComponent, Category = "Damage Effects")
    UTDDamageTypeComponent DamageTypeComponent;
    UPROPERTY(DefaultComponent, Category = "Cold Slow")
    UDamageTypeMultiplier SlowedByCold;
    UPROPERTY(DefaultComponent, Category = "Fire Burn")
    UDamageTypeOverTime BurnedByFire;

    UPROPERTY(DefaultComponent)
    UPoolableComponent PoolableComponent;

    USceneComponent GetTargetComponent()
    {
        return Mesh;
    }


    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        RegisterObject(ERegisteredObjectTypes::ERO_Monster);

        Init();

        HealthSystemComponent.OnHealthChanged.AddUFunction(this, n"OnHealthChanged");
        PoolableComponent.OnPoolEnterExit.AddUFunction(this, n"EnterExitPool");
    }

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason EndPlayReason)
    {
        DeregisterObject(ERegisteredObjectTypes::ERO_Monster);
    }

    UFUNCTION()
    void Init()
    {
        // Set up the enemy with the data from the data asset
        HealthSystemComponent.MaxHealth = EnemyData.MaxHealth;
        HealthSystemComponent.ResetHealth();
        PointValue = EnemyData.PointValue;
        KillBounty = EnemyData.KillBounty;
        Damage = EnemyData.Damage;
        MoveSpeed = EnemyData.MoveSpeed;
        // Set material
        Mesh.SetMaterial(0, EnemyData.Material);
        Mesh.SetVectorParameterValueOnMaterials(FName("Tint"), EnemyData.Color.ToFVector());

        // Reset paath
        LerpAlpha = 0;
    }

    UFUNCTION()
    void EnterExitPool(bool bIsEntering)
    {
        Init();
        EnterExitPoolBPEvent(bIsEntering);
    }

    UFUNCTION(BlueprintEvent)
    void EnterExitPoolBPEvent(bool bIsEntering)
    {
        Print("EnterExitPoolBPEvent is not implemented in BP");
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
    void EnemyDeath()
    {
        Path = nullptr;
        IsActive = false;
        RewardPlayers();
        OnEnemyDeath.Broadcast(this);
        DestroyActor();
    }

    void RewardPlayers()
    {
        if (System::IsServer())
        {
            for (int i = 0; i < Gameplay::NumPlayerStates; i++)
            {
                ATDPlayerState PS = Cast<ATDPlayerState>(Gameplay::GetPlayerState(i));
                if (PS == nullptr) continue;
                PS.Gold += KillBounty;
            }
        }
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
            DestroyActor();
            /////
            return;
        }

        LerpAlpha += (MoveSpeed * SlowedByCold.GetValue() / Length) * DeltaSeconds;

        float distance = Math::Lerp(0, Length, LerpAlpha);

        FTransform tf = Path.GetTransformAtDistanceAlongSpline(distance, ESplineCoordinateSpace::World);
        tf.Location = FVector(tf.Location.X, tf.Location.Y, tf.Location.Z);

        SetActorLocation(tf.Location);
        SetActorRotation(tf.Rotation);
    }

    
    UFUNCTION(BlueprintCallable)
    void OnHealthChanged(int32 Health, int32 MaxHealth)
    {
        if (Health <= 0)
        {
            EnemyDeath();
        }
    }

};