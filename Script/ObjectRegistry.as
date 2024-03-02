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

    AActor GetClosestActorOfType(ERegisteredObjectTypes Type, FVector Location, float MaxDistance = MAX_flt)
    {
        TArray<UObject> Objects = GetAllObjectsOfType(Type);
        if (Objects.IsEmpty())
            return nullptr;

        AActor Closest = nullptr;
        float MinDistance = MAX_flt;
        for (int i = 0; i < Objects.Num(); i++)
        {
            AActor Current = Cast<AActor>(Objects[i]);
            float Distance = Location.Distance(Current.GetActorLocation());
            if (Distance < MinDistance && Distance < MaxDistance)
            {
                MinDistance = Distance;
                Closest = Current;
            }
        }
        return Closest;
    }

    TArray<AActor> GetAllInRangeActorsOfType(ERegisteredObjectTypes Type, FVector Location, float MaxDistance = MAX_flt)
    {
        TArray<UObject> Objects = GetAllObjectsOfType(Type);
        if (Objects.IsEmpty())
            return TArray<AActor>();

        TArray<AActor> InRangeActors;
        for (int i = 0; i < Objects.Num(); i++)
        {
            AActor Current = Cast<AActor>(Objects[i]);
            float Distance = Location.Distance(Current.GetActorLocation());
            if (Distance < MaxDistance)
            {
                InRangeActors.Add(Current);
            }
        }
        return InRangeActors;
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