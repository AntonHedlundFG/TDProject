delegate void FOnInteractDelegate();
delegate bool FCanInteractDelegate(APlayerController ControllerUsing);

class UInteractableComponent : URegisteredSceneComponent
{
    //Must be bound!
    UPROPERTY()
    FOnInteractDelegate OnInteract;

    //Can be bound, if unbound interaction is always available. If the bound functions returns false, the interaction fails.
    UPROPERTY()
    FCanInteractDelegate CanInteract;

    bool CanInteract(APlayerController ControllerUsing)
    {
        if (!CanInteract.IsBound())
            return true;
        return CanInteract.Execute(ControllerUsing);
    }

    bool TryInteract(APlayerController ControllerUsing)
    {
        if (!OnInteract.IsBound())
        {
            Print(FString("Trying to interact with unbound interactable:") + Owner.GetActorNameOrLabel());
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
    //Maximum range from character to an interactable
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Interaction)
    float InteractionDistance = 250.0f;

    // Determines if we find the nearest interactable, or the one most in front of the player
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Interaction)
    bool bUseDotProductInsteadOfDistance = true;

    //Searches within InteractionDistance to determine which interactable is the currently selected one.
    UFUNCTION(BlueprintCallable)
    UInteractableComponent SearchForInteractables()
    {
        if (bUseDotProductInsteadOfDistance)
        {
            //This version uses dot product to determine which interactable within range is in front of the character.
            UInteractableComponent Best;
            float BestDotProduct = -1.0f;
            for (UObject Object : UObjectRegistry::Get().GetAllObjectsOfType(UInteractableComponent::StaticClass()))
            {
                UInteractableComponent Component = Cast<UInteractableComponent>(Object);
                const float Distance = Component.WorldLocation.Distance(Owner.ActorLocation);
                if (Distance > InteractionDistance) continue;
                const FVector DeltaVector = (Component.WorldLocation - Owner.ActorLocation).GetSafeNormal();
                const float Dot = DeltaVector.DotProduct(Owner.ActorForwardVector);
                if (Dot > BestDotProduct)
                {
                    Best = Component;
                    BestDotProduct = Dot;
                }
            }
            return Best;
        }
        else
        {
            //This version only checks distances and finds the nearest object, regardless of character direction.
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
        
    }

    // Uses SearchForInteractables() to attempt an interaction with the currently selected interactable.
    UFUNCTION(BlueprintCallable)
    bool TryInteract(APlayerController User)
    {
        UInteractableComponent Nearest = SearchForInteractables();
        if (!IsValid(Nearest)) return false;

        return Nearest.TryInteract(User);
    }

    // Uses SearchForInteractables to check if an interaction with the currently selected interactable is possible.
    UFUNCTION(BlueprintCallable)
    bool CanInteract(APlayerController User)
    {
        UInteractableComponent Nearest = SearchForInteractables();
        if (!IsValid(Nearest)) return false;

        return Nearest.CanInteract(User);
    }

}