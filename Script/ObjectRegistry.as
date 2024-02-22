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