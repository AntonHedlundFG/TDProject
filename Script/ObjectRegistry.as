class UObjectRegistry : UGameInstanceSubsystem
{
    TMap<UClass, FListWrapper> ObjectLists;

    void RegisterObject(UObject Object, UClass ClassType)
    {
        if (!ObjectLists.Contains(ClassType))
        {
            ObjectLists.Add(ClassType, FListWrapper());
        }

        ObjectLists[ClassType].Objects.Add(Object);
    }

    void DeregisterObject(UObject Object, UClass ClassType)
    {
        ObjectLists[ClassType].Objects.RemoveSingleSwap(Object);
        if (ObjectLists[ClassType].Objects.IsEmpty())
            ObjectLists.Remove(ClassType);
    }

    TArray<UObject> GetAllObjectsOfType(UClass ClassType)
    {
        if (!ObjectLists.Contains(ClassType))
            return TArray<UObject>();
        return ObjectLists[ClassType].Objects;
    }
}

class ARegisteredActor : AActor
{
    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        UObjectRegistry::Get().RegisterObject(this, Class);
    }

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason EndPlayReason)
    {
        UObjectRegistry::Get().DeregisterObject(this, Class);
    }
}

class URegisteredSceneComponent : USceneComponent
{
    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        UObjectRegistry::Get().RegisterObject(this, Class);
    }

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason EndPlayReason)
    {
        UObjectRegistry::Get().DeregisterObject(this, Class);
    }
}

class URegisteredComponent : UActorComponent
{
    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        UObjectRegistry::Get().RegisterObject(this, Class);
    }

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason EndPlayReason)
    {
        UObjectRegistry::Get().DeregisterObject(this, Class);
    }
}

struct FListWrapper
{
    TArray<UObject> Objects;
}