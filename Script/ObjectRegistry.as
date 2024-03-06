class UObjectRegistry : UGameInstanceSubsystem
{
    TMap<ERegisteredObjectTypes, FListWrapper> ObjectLists;

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

mixin void RegisterObject(UObject Object, ERegisteredObjectTypes Type)
{
    UObjectRegistry ObjectRegistry = UObjectRegistry::Get();
    if(IsValid(ObjectRegistry)) 
    {
        if (!ObjectRegistry.ObjectLists.Contains(Type))
        {
            ObjectRegistry.ObjectLists.Add(Type, FListWrapper());
        }

        ObjectRegistry.ObjectLists[Type].Objects.Add(Object);
    }
    else
        Print(f"No Object Registry available");
}

mixin void DeregisterObject(UObject Object, ERegisteredObjectTypes Type)
{
    UObjectRegistry ObjectRegistry = UObjectRegistry::Get();
    if(IsValid(ObjectRegistry)) 
    {
        ObjectRegistry.ObjectLists[Type].Objects.RemoveSingleSwap(Object);
        if (ObjectRegistry.ObjectLists[Type].Objects.IsEmpty())
            ObjectRegistry.ObjectLists.Remove(Type);
    }
    else
        Print(f"No Object Registry available");
}

mixin TArray<AActor> GetAllInRangeActorsOfType(AActor Actor, ERegisteredObjectTypes Type, float MaxDistance = MAX_flt)
{
    UObjectRegistry ObjectRegistry = UObjectRegistry::Get();
    if(IsValid(ObjectRegistry))
    {
        return ObjectRegistry.GetAllInRangeActorsOfType(Type, Actor.ActorLocation, MaxDistance);
    }
    Print(f"No Object Registry available");
    return TArray<AActor>();
}