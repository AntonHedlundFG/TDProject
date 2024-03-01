class UObjectPool : UObject
{
    UPROPERTY(VisibleAnywhere)
    TSubclassOf<APoolableActor> ObjectClass;

    UPROPERTY(VisibleAnywhere)
    TArray<APoolableActor> ObjectPool;

    UFUNCTION()
    void Initialize(TSubclassOf<APoolableActor> InObjectClass, int64 Size = 10)
    {
        ObjectClass = InObjectClass;
        for (int32 i = 0; i < Size; i++)
        {
            SpawnPoolableActor();
        }
    }

    UFUNCTION()
    APoolableActor GetObject(FVector Location = FVector::ZeroVector, FRotator Rotation = FRotator::ZeroRotator)
    {
        APoolableActor Object = nullptr;
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
        
        return Object;
    }


    UFUNCTION()
    void ReturnObject(APoolableActor Object)
    {
        if(IsValid(Object))
        {
            Object.SetActorHiddenInGame(true);
            ObjectPool.Add(Object);
        }
    }

    UFUNCTION()
    void ClearPool()
    {
        for (APoolableActor Object : ObjectPool)
        {
            if(IsValid(Object))
            {
                Object.DestroyActor();
            }
        }
        ObjectPool.Empty();
    }

    UFUNCTION()
    APoolableActor SpawnPoolableActor(bool bIsActive = false, FVector Location = FVector::ZeroVector, FRotator Rotation = FRotator::ZeroRotator)
    {
        APoolableActor Object = Cast<APoolableActor>(SpawnActor(ObjectClass, Location, Rotation));
        if(IsValid(Object))
        {
            Object.Initialize(this);
            if(!bIsActive)
            {            
                ReturnObject(Object);
            }
        }
        return Object;
    }

}

class APoolableActor : AActor
{
    UPROPERTY(VisibleAnywhere)
    UObjectPool Pool;

    UFUNCTION()
    void Initialize(UObjectPool InPool)
    {
        Pool = InPool;
    }

    UFUNCTION()
    void ReturnToPool()
    {
        if(IsValid(Pool))
        {
            Pool.ReturnObject(this);
        }
        else
        {
            DestroyActor();
        }
    }
}