class UObjectRegistry : UGameInstanceSubsystem
{
    TMap<ERegisteredObjectTypes, FListWrapper> ObjectLists;

    void RegisterObject(UObject Object, ERegisteredObjectTypes Type)
    {
        if (!ObjectLists.Contains(Type))
        {
            ObjectLists.Add(Type, FListWrapper());
        }

        ObjectLists[Type].Objects.Add(Object);
    }

    void DeregisterObject(UObject Object, ERegisteredObjectTypes Type)
    {
        ObjectLists[Type].Objects.RemoveSingleSwap(Object);
        if (ObjectLists[Type].Objects.IsEmpty())
            ObjectLists.Remove(Type);
    }

    TArray<UObject> GetAllObjectsOfType(ERegisteredObjectTypes Type)
    {
        if (!ObjectLists.Contains(Type))
            return TArray<UObject>();
        return ObjectLists[Type].Objects;
    }

}

enum ERegisteredObjectTypes
{
    ERO_InteractableComponent,
    ERO_Monster,
    ERO_Player
}

struct FListWrapper
{
    TArray<UObject> Objects;
}

/*class UObjectRegistry : UGameInstanceSubsystem
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

class ARegisteredPawn : APawn
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

class ARegisteredCharacter : ACharacter
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
}*/