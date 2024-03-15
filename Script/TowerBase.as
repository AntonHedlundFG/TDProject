﻿class ATowerBase : AActor
{
    default bReplicates = true;

    // Components
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;
    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent Mesh;
    default Mesh.bVisible = true;
    UPROPERTY(DefaultComponent)
    UInteractableComponent InteractableComp;

    // UPROPERTY()
    // TArray<TSubclassOf<ATower>> BuildableTowers;
    UPROPERTY(Replicated)
    TArray<UPurchasable> Purchasables;
    
   
    // Owning player index
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Tower|Ownership", Replicated, ReplicatedUsing = UpdateMeshColors)
    uint8 OwningPlayerIndex = 0;
    // Player colors data asset
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Replicated, Category = "Tower|Ownership")
    UPlayerColorsDataAsset PlayerColors;


    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        //Bind InteractableComponent delegate functions.
        InteractableComp.OnLocalInteractDelegate.BindUFunction(this, n"TryLocalInteract");
        if (System::IsServer())
        {
            InteractableComp.CanInteractDelegate.BindUFunction(this, n"CanInteract");
            InteractableComp.OnInteractDelegate.BindUFunction(this, n"ServerInteract");
        }
        UpdateMeshColors(); //Set mesh color
    }

    UFUNCTION()
    void UpdateMeshColors()
    {
        if (PlayerColors == nullptr) return;

        FVector PlayerColor = PlayerColors.GetColorOf(OwningPlayerIndex);
        TArray<UActorComponent> OutComponents;
        GetAllComponents(UStaticMeshComponent::StaticClass(), OutComponents);
        for (UActorComponent Comp : OutComponents)
        {
            Cast<UStaticMeshComponent>(Comp).SetVectorParameterValueOnMaterials(FName("Tint"), PlayerColor);
        }
    }

    UFUNCTION()
    void TryLocalInteract(APlayerController User, uint8 Param)
    {
        ATDPlayerState PS = Cast<ATDPlayerState>(User.PlayerState);
        
        if (PS == nullptr || Purchasables.Num() <= 0 || PS.PlayerIndex != OwningPlayerIndex)
            return;

        LocalInteract_BP(User, Param);
    }

    UFUNCTION(BlueprintEvent)
    void LocalInteract_BP(APlayerController User, uint8 Param)
    {
        
    }

    UFUNCTION()
    bool CanInteract(APlayerController User, uint8 Param)
    {
        ATDPlayerState PS = Cast<ATDPlayerState>(User.PlayerState);

        //Cast and player index checks.
        if(PS == nullptr || PS.PlayerIndex != OwningPlayerIndex) return false;
        
        //Purchasable null checks.
        if(Purchasables.Num() <= 0 || Purchasables[Param] == nullptr) return false;

        return PS.Gold >= Purchasables[Param].Price;
    }


    UFUNCTION()
    void ServerInteract(APlayerController User, uint8 Param)
    {
        if(!System::IsServer()) return;

        ATDPlayerState PS = Cast<ATDPlayerState>(User.PlayerState);

        if(Purchasables[Param] == nullptr || PS == nullptr) return;

        Purchasables[Param].OnPurchase(PS, this);
    }


};