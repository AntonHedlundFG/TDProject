class ATowerBase : AActor
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
    
   
    // Owning player index
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Tower|Ownership")
    uint8 OwningPlayerIndex = 0;
    // Player colors data asset
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Tower|Ownership")
    UPlayerColorsDataAsset PlayerColors;


    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        if (System::IsServer())
        {
            //Bind InteractableComponent delegate functions.
            InteractableComp.OnLocalInteractDelegate.BindUFunction(this, n"LocalInteract_BP");
            InteractableComp.CanInteractDelegate.BindUFunction(this, n"CanInteract");
        }

        if (PlayerColors != nullptr)
        {
            FVector PlayerColor = PlayerColors.GetColorOf(OwningPlayerIndex);
            TArray<UActorComponent> OutComponents;
            GetAllComponents(UStaticMeshComponent::StaticClass(), OutComponents);
            for (UActorComponent Comp : OutComponents)
            {
                Cast<UStaticMeshComponent>(Comp).SetVectorParameterValueOnMaterials(FName("Tint"), PlayerColor);
            }
        }

    }

    UFUNCTION(BlueprintEvent)
    private void LocalInteract_BP(APlayerController User, uint8 Param)
    {
        
    }


    //perhaps not needed?
    UFUNCTION()
    private void LocalInteract(APlayerController User, uint8 Param)
    {
        LocalInteract_BP(User, Param);
    }

    UFUNCTION()
    private bool CanInteract(APlayerController User, uint8 Param)
    {
        ATDPlayerState PS = Cast<ATDPlayerState>(User.PlayerState);
        if (PS != nullptr)
        {
            return PS.PlayerIndex == OwningPlayerIndex;
        }

        return true;
    }


    UFUNCTION()
    void Build(TSubclassOf<ATower> tower)
    {
        if(!System::IsServer()) return;

        if(tower == nullptr) return;

        ATower SpawnedTower = Cast<ATower>(SpawnActor(tower, this.GetActorLocation(), this.GetActorRotation()));
        SpawnedTower.OwningPlayerIndex = this.OwningPlayerIndex;
        SpawnedTower.bIsBuilt = true;
        SpawnedTower.OnRep_IsBuilt();

        this.DestroyActor();
    }


    UFUNCTION()
    void OnGameEnded()
    {
        if(System::IsServer())
        {
            SetActorTickEnabled(false);
        }
    }

};