delegate void FOnPurchasedDelegate(APlayerController User);
delegate bool FCanBePurchasedDelegate(APlayerController User);

//For this component, only bind OnPurchasedDelegate. It already binds the OnInteract/CanInteract delegates and checks if the user can afford the purchase.
//A purchased building is considered "always unaffordable" for CanPurchase() 
class UPricedInteractableComponent : UInteractableComponent
{
    default bReplicates = true;

    //Must be bound!
    UPROPERTY(NotVisible)
    FOnPurchasedDelegate OnPurchasedDelegate;

    UPROPERTY(NotVisible)
    FCanBePurchasedDelegate CanBePurchasedDelegate;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Priced Interactable")
    int Price = 100;

    UPROPERTY(Transient, Replicated, BlueprintReadOnly, VisibleAnywhere, Category = "Priced Interactable")
    bool bIsPurchased = false;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Super::BeginPlay();
        CanInteractDelegate.BindUFunction(this, n"CanPurchase");
        if (System::IsServer())
            OnInteractDelegate.BindUFunction(this, n"Purchase");
    }

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason EndPlayReason)
    {
        Super::EndPlay(EndPlayReason);
    }

    UFUNCTION()
    bool CanPurchase(APlayerController User, uint8 Param)
    {
        if (bIsPurchased) 
            return false;

        if (CanBePurchasedDelegate.IsBound() && !CanBePurchasedDelegate.Execute(User))
            return false;
        
        ATDPlayerState State = Cast<ATDPlayerState>(User.PlayerState);
        if (State == nullptr)
            return false;

        return State.Gold >= Price;
    }

    UFUNCTION()
    void Purchase(APlayerController User, uint8 Param)
    {
        ATDPlayerState State = Cast<ATDPlayerState>(User.PlayerState);
        if (State == nullptr)
        {
            Print("User has wrong PlayerState class, has no Gold");
            return;
        }

        if (!CanPurchase(User, Param))
        {
            Print("User cannot afford purchase. This should not happen, as costs should be checked before calling Purchase()");
            return;   
        }

        State.Gold -= Price;
        bIsPurchased = true;
        OnPurchasedDelegate.ExecuteIfBound(User);
    }

}