event void FOnEnemySpawnEvent(ATDEnemy Enemy);
event void FOnEnemyDeathEvent(ATDEnemy Enemy);


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


    UPROPERTY(BlueprintReadWrite, Replicated, ReplicatedUsing = OnRep_EnemyLevelChange, Category = "Enemy Settings")
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

    USceneComponent GetTargetComponent() { return Mesh; }


    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        InitialSetup();
    }

    UFUNCTION()
    void InitialSetup()
    {
        OnRep_EnemyLevelChange();
        HealthSystemComponent.OnHealthChanged.AddUFunction(this, n"OnHealthChanged");
        PoolableComponent.OnPoolEnterExit.AddUFunction(this, n"OnEnterExitPool");
    }

    UFUNCTION()
    void OnRep_EnemyLevelChange()
    {
        // Set up the enemy with the data from the data asset
        HealthSystemComponent.MaxHealth = EnemyData.MaxHealth;
        HealthSystemComponent.ResetHealth();
        PointValue = EnemyData.PointValue;
        KillBounty = EnemyData.KillBounty;
        Damage = EnemyData.Damage;
        MoveSpeed = EnemyData.MoveSpeed;
        if (EnemyData.bRemoveDamageEffectsOnCreation)
            DamageTypeComponent.RemoveAllInstances();
        // Set material
        Mesh.SetMaterial(0, EnemyData.Material);
        Mesh.SetVectorParameterValueOnMaterials(FName("Tint"), EnemyData.Color.ToFVector());
    }

    UFUNCTION()
    void OnEnterExitPool(bool bIsEnteringPool)
    {
        OnEnterExitPoolBPEvent(bIsEnteringPool);
        if(!bIsEnteringPool)
        {
            OnUnitSpawn(Path);
            RegisterObject(ERegisteredObjectTypes::ERO_Monster);
        }
    }

    UFUNCTION(BlueprintEvent)
    void OnEnterExitPoolBPEvent(bool bIsEntering)
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
        OnRep_EnemyLevelChange();
        Path = path;
        LerpAlpha = 0;
        IsActive = true;
        OnEnemySpawn.Broadcast(this);
    }

    
    UFUNCTION(BlueprintCallable)
    void OnHealthChanged(int32 Health, int32 MaxHealth)
    {
        if (Health <= 0)
        {
            OnZeroHealth();
        }
    }

    UFUNCTION()
    void OnZeroHealth()
    {
        if(!System::IsServer()) return;
        RewardPlayers();
        if(EnemyData.NextLevelEnemy != nullptr)
        {
            EnemyData = EnemyData.NextLevelEnemy;
            OnRep_EnemyLevelChange();
        }
        else
        {
            EnemyDeath();
        }
    }

    UFUNCTION()
    void EnemyDeath()
    {
        if (!IsActive) return;
        Path = nullptr;
        IsActive = false;
        OnEnemyDeath.Broadcast(this);
        PoolableComponent.ReturnToPool();
        DeregisterObject(ERegisteredObjectTypes::ERO_Monster);
    }

    UFUNCTION()
    void SetEnemyData(UTDEnemyData data)
    {
        EnemyData = data;
        OnRep_EnemyLevelChange();
    }

    UFUNCTION()
    void MoveAlongSpline(float DeltaSeconds)
    {
        if(Path == nullptr || !IsActive) return;

        float Length = Path.GetSplineLength();
        if(LerpAlpha >= 1.f)
        {
            OnEnemyGoalReached();
            return;
        }

        LerpAlpha += (MoveSpeed * SlowedByCold.GetValue() / Length) * DeltaSeconds;

        float distance = Math::Lerp(0, Length, LerpAlpha);

        FTransform tf = Path.GetTransformAtDistanceAlongSpline(distance, ESplineCoordinateSpace::World);
        tf.Location = FVector(tf.Location.X, tf.Location.Y, tf.Location.Z);

        SetActorLocation(tf.Location);
        SetActorRotation(tf.Rotation);
    }

    void OnEnemyGoalReached()
    {
            ATDGameMode gameMode = Cast<ATDGameMode>(Gameplay::GetGameMode());
            if(gameMode != nullptr)
            {
                gameMode.OnEnemyReachedGoal(this);
            }
            IsActive = false;
            LerpAlpha = 0;
            PoolableComponent.ReturnToPool();
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

};
