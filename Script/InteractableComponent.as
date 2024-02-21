delegate void FOnInteractDelegate();
delegate bool FCanInteractDelegate(APlayerController ControllerUsing);

class UInteractableComponent : URegisteredSceneComponent
{
    FOnInteractDelegate OnInteract;
    FCanInteractDelegate CanInteract;

    bool TryInteract(APlayerController ControllerUsing)
    {
        if (!OnInteract.IsBound())
        {
            Print(FString("Trying to interact with unbound interactable"));
            return false;
        }

        const bool bCanInteract = (CanInteract.IsBound() ? CanInteract.Execute(ControllerUsing) : true);
        if (bCanInteract)
        {
            OnInteract.Execute();
        }
        return bCanInteract;
    }
};

class UInteractionComponent : UActorComponent
{
    float InteractionDistance = 250.0f;

    UFUNCTION(BlueprintCallable)
    UInteractableComponent SearchForInteractables()
    {
        UInteractableComponent Nearest;
        float BestDistance = MAX_flt;
        for (UObject Object : UObjectRegistry::Get().GetAllObjectsOfType(UInteractableComponent::StaticClass()))
        {
            UInteractableComponent Component = Cast<UInteractableComponent>(Object);
            const float Distance = Component.WorldLocation.Distance(Owner.ActorLocation);
            if (Distance > InteractionDistance || Distance > BestDistance) continue;

            Nearest = Component;
            BestDistance = Distance;
        }
        return Nearest;
    }

    UFUNCTION(BlueprintCallable)
    bool TryInteract(APlayerController User)
    {
        UInteractableComponent Nearest = SearchForInteractables();
        if (!IsValid(Nearest)) return false;

        return Nearest.TryInteract(User);
    }

}