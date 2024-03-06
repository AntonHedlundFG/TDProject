class UActorComponentObjectPool : UObject
{
    UPROPERTY(VisibleAnywhere)
    TSubclassOf<AActor> ObjectClass;

    UPROPERTY(VisibleAnywhere)
    TArray<AActor> ObjectPool;

    UFUNCTION()
    void Initialize(TSubclassOf<AActor> InObjectClass, int64 Size = 10, bool bExtendBySize = false)
    {
        if(InObjectClass == nullptr)
        {
            Print("ObjectClass is null, please set ObjectClass before initializing the pool");
            return;
        }
        ObjectClass = InObjectClass;

        int64 NewSpawnAmount = Size;
        if(!bExtendBySize)
        {
            NewSpawnAmount -= ObjectPool.Num();
        }

        for (int32 i = 0; i < NewSpawnAmount; i++)
        {
            SpawnPoolableActor();
        }
    }

    UFUNCTION()
    AActor GetObject(FVector Location = FVector::ZeroVector, FRotator Rotation = FRotator::ZeroRotator)
    {
        AActor Object = nullptr;
        if(ObjectPool.Num() > 0 && IsValid(ObjectPool[0]))
        {
            Object = ObjectPool[0];
            ObjectPool.RemoveAt(0);
            Object.SetActorLocation(Location);
            Object.SetActorRotation(Rotation);
            Object.SetActorHiddenInGame(false);
        }
        else
        {
            Object = SpawnPoolableActor(true, Location, Rotation);
        }
        
        Object.SetActorTickEnabled(true);
        Cast<UPoolableComponent>(Object.GetComponent(UPoolableComponent::StaticClass())).OnPoolEnterExit.Broadcast(false);

        return Object;
    }


    UFUNCTION()
    void ReturnObject(AActor Object)
    {
        if(IsValid(Object))
        {
            Object.SetActorHiddenInGame(true);
            Object.SetActorTickEnabled(false);
            ObjectPool.Add(Object);
            Cast<UPoolableComponent>(Object.GetComponent(UPoolableComponent::StaticClass())).OnPoolEnterExit.Broadcast(true);
        }
    }

    UFUNCTION()
    void ClearPool()
    {
        for (AActor Object : ObjectPool)
        {
            if(IsValid(Object))
            {
                Object.DestroyActor();
            }
        }
        ObjectPool.Empty();
    }

    UFUNCTION()
    private AActor SpawnPoolableActor(bool bIsActive = false, FVector Location = FVector::ZeroVector, FRotator Rotation = FRotator::ZeroRotator)
    {
        AActor Actor = Cast<AActor>(SpawnActor(ObjectClass, Location, Rotation));
        UPoolableComponent PoolableComponent = UPoolableComponent::GetOrCreate(Actor);
        if(IsValid(Actor))
        {

            PoolableComponent.Initialize(this);
            if(!bIsActive)
            {            
                ReturnObject(Actor);
            }
        }
        return Actor;
    }

}

event void FOnPoolEnterExit(bool bIsEntering);

class UPoolableComponent : UActorComponent 
{
    AActor ParentActor;
    FOnPoolEnterExit OnPoolEnterExit;

    UPROPERTY(VisibleAnywhere)
    UActorComponentObjectPool Pool;

    UFUNCTION()
    void Initialize(UActorComponentObjectPool InPool)
    {
        Pool = InPool;
        ParentActor = GetOwner();
    }

    UFUNCTION()
    void ReturnToPool()
    {
        if(IsValid(Pool))
        {
            Pool.ReturnObject(ParentActor);
        }
        else if (IsValid(ParentActor))
        {
            ParentActor.DestroyActor();
        }
    }
}

class UObjectPoolSubsystem : UGameInstanceSubsystem
{
    UPROPERTY(VisibleAnywhere)
    TMap<TSubclassOf<AActor>, UActorComponentObjectPool> ObjectPools;

    UFUNCTION()
    void InitializePool(TSubclassOf<AActor> InObjectClass, int64 Size = 10)
    {
        UActorComponentObjectPool Pool = GetObjectPool(InObjectClass);
        Pool.Initialize(InObjectClass, Size, false);
    }

    UFUNCTION()
    UActorComponentObjectPool GetObjectPool(TSubclassOf<AActor> ObjectClass)
    {
        UActorComponentObjectPool Pool = nullptr;
        if(ObjectPools.Contains(ObjectClass))
        {
            Pool = ObjectPools[ObjectClass];
            Print("Pool already exists");
        }
        else
        {
            Pool = Cast<UActorComponentObjectPool>(NewObject(this, UActorComponentObjectPool::StaticClass()));
            Pool.Initialize(ObjectClass);
            ObjectPools.Add(ObjectClass, Pool);
            Print("Pool created");
        }
        return Pool;
    }

    UFUNCTION()
    AActor GetObject(TSubclassOf<AActor> InObjectClass, FVector Location = FVector::ZeroVector, FRotator Rotation = FRotator::ZeroRotator)
    {
        UActorComponentObjectPool Pool = GetObjectPool(InObjectClass);

        AActor Object = Pool.GetObject(Location, Rotation);

        return Object;
    }

    UFUNCTION()
    void ReturnObject(TSubclassOf<AActor> InObjectClass, AActor Object)
    {
        UActorComponentObjectPool Pool = GetObjectPool(InObjectClass);
        Pool.ReturnObject(Object);
    }
}