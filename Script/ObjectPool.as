class UActorObjectPool : UObject
{
    UPROPERTY(VisibleAnywhere)
    TSubclassOf<AActor> ObjectClass;

    UPROPERTY(VisibleAnywhere)
    TArray<AActor> ObjectPool;

    UFUNCTION()
    void Initialize(TSubclassOf<AActor> InObjectClass, int64 Size = 10)
    {
        ObjectClass = InObjectClass;
        for (int32 i = 0; i < Size; i++)
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
    AActor SpawnPoolableActor(bool bIsActive = false, FVector Location = FVector::ZeroVector, FRotator Rotation = FRotator::ZeroRotator)
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

class UPoolableComponent : UActorComponent 
{
    AActor ParentActor;

    UPROPERTY(VisibleAnywhere)
    UActorObjectPool Pool;

    UFUNCTION()
    void Initialize(UActorObjectPool InPool)
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
        else
        {
            ParentActor.DestroyActor();
        }
    }
}