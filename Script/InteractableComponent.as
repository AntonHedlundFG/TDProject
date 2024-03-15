delegate void FOnInteractDelegate(APlayerController User, uint8 Param);
delegate bool FCanInteractDelegate(APlayerController User, uint8 Param);

class UInteractableComponent : USceneComponent
{
    //If true, interaction occurs locally and does not notify server. Only use for things that should open UI elements, and the like.
    //If servers need to be notified of UI selections, use the Server_TryInteract() function on the UInteractionComponent manually.
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Replicated)
    bool bIsLocallyInteractable = false;

    //Must be bound!
    UPROPERTY(NotVisible)
    FOnInteractDelegate OnInteractDelegate;

    //Only relevant if bIsLocallyInteractable = true;
    UPROPERTY(NotVisible)
    FOnInteractDelegate OnLocalInteractDelegate;

    //Can be bound, if unbound interaction is always available. If the bound functions returns false, the interaction fails.
    UPROPERTY(NotVisible)
    FCanInteractDelegate CanInteractDelegate;

    bool CanInteract(APlayerController ControllerUsing, uint8 Param = 0)
    {
        if (!CanInteractDelegate.IsBound())
            return true;
        return CanInteractDelegate.Execute(ControllerUsing, Param);
    }

    bool TryInteract(APlayerController ControllerUsing, uint8 Param = 0)
    {
        if (!OnInteractDelegate.IsBound())
        {
            Print(FString("Trying to interact with unbound interactable:") + Owner.GetActorNameOrLabel());
            return false;
        }

        const bool bCanInteract = (CanInteractDelegate.IsBound() ? CanInteractDelegate.Execute(ControllerUsing, Param) : true);
        if (bCanInteract)
        {
            OnInteractDelegate.Execute(ControllerUsing, Param);
        }
        return bCanInteract;
    }

    bool TryLocalInteract(APlayerController User, uint8 Param = 0)
    {
        OnLocalInteractDelegate.Execute(User, Param);
        return true;
        /* These checks don't seem to be neccesary. If required, one could make a separate CanInteractLocallyDelegate which can be bound for local checks.
        const bool bCanInteract = (CanInteractDelegate.IsBound() ? CanInteractDelegate.Execute(User, Param) : true);
        if (bCanInteract)
            OnLocalInteractDelegate.Execute(User, Param);
        return bCanInteract;
        */
    }

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        RegisterObject(ERegisteredObjectTypes::ERO_InteractableComponent);
    }
    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason EndPlayReason)
    {
        DeregisterObject(ERegisteredObjectTypes::ERO_InteractableComponent);
    }
};

class UInteractionComponent : UActorComponent
{
    default bReplicates = true;

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
            for (UObject Object : UObjectRegistry::Get().GetAllObjectsOfType(ERegisteredObjectTypes::ERO_InteractableComponent))
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
            for (UObject Object : UObjectRegistry::Get().GetAllObjectsOfType(ERegisteredObjectTypes::ERO_InteractableComponent))
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
    // Returns true if a nearby interactable is found, even if the interaction fails!
    UFUNCTION(BlueprintCallable)
    bool TryInteract(APlayerController User, uint8 Param = 0)
    {
        UInteractableComponent Nearest = SearchForInteractables();
        if (!IsValid(Nearest)) return false;

        if (!Nearest.bIsLocallyInteractable)
            Server_TryInteract(User, Nearest, Param);
        else
        {
            Local_TryInteract(User, Nearest, Param);
        }
        return true;
    }

    UFUNCTION(NotBlueprintCallable)
    void Local_TryInteract(APlayerController User, UInteractableComponent Target, uint8 Param = 0)
    {
        Target.TryLocalInteract(User, Param);
    }

    //This is called automatically upon interaction with an UInteractableComponent with bIsLocallyInteractable = false.
    //If it's true, you can call this function manually from the UI if relevant.
    UFUNCTION(Server)
    void Server_TryInteract(APlayerController User, UInteractableComponent Target, uint8 Param = 0)
    {
        Target.TryInteract(User, Param);
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


UCLASS(Abstract)
class UExampleLocalInteractable : UInteractableComponent
{
    default bIsLocallyInteractable = true;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Super::BeginPlay();
        
        OnLocalInteractDelegate.BindUFunction(this, n"LocalInteraction");

        if(System::IsServer())
        {
            OnInteractDelegate.BindUFunction(this, n"ServerInteraction");
            CanInteractDelegate.BindUFunction(this, n"CanAfford");
        }

    }

    UFUNCTION()
    void LocalInteraction(APlayerController User, uint8 Param)
    {
        //This happens locally. Create UI Widget here, and call Server_TryInteract() from the UI.
    }

    UFUNCTION()
    bool CanAfford(APlayerController User, uint8 Param)
    {
        //Check costs here, using Cast<ATDPlayerState>(User.PlayerState).Gold. 
        //I think it's OK to bind this only on server, and then handle which UI elements are affordable in the Widget instead.
        return true; 
    }

    UFUNCTION()
    void ServerInteraction(APlayerController User, uint8 Param)
    {
        //Perform purchase. If CanAfford checks costs, you don't need to do so here.
    }

    
}