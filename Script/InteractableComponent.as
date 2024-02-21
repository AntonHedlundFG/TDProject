delegate void FOnInteractDelegate();
delegate bool FCanInteractDelegate(APlayerController ControllerUsing);

class UInteractableComponent : USceneComponent
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

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        UObjectRegistry::Get().InteractableComponents.Add(this);
    }

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason EndPlayReason)
    {
        UObjectRegistry::Get().InteractableComponents.RemoveSingleSwap(this);
    }

};

class ATestInteractable : AActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    UStaticMeshComponent RootComp;

    UPROPERTY(DefaultComponent, Attach = RootComp)
    UInteractableComponent InteractableComp;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        InteractableComp.OnInteract.BindUFunction(this, n"TestInteract");
    }

    UFUNCTION()
    private void TestInteract()
    {
        Print(FString("Interacted!"));
    }
}

class UInteractionComponent : UActorComponent
{
    float InteractionDistance = 250.0f;

    UFUNCTION(BlueprintCallable)
    UInteractableComponent SearchForInteractables()
    {
        UInteractableComponent Nearest;
        float BestDistance = MAX_flt;
        for (UInteractableComponent Component : UObjectRegistry::Get().InteractableComponents)
        {
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