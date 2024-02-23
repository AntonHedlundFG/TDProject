class ATower : AActor
{
    default bReplicates = true;

    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent FinishedMesh;
    default FinishedMesh.bVisible = true;

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent PreviewMesh;
    default PreviewMesh.bVisible = false;

    UPROPERTY(DefaultComponent)
    UInteractableComponent InteractableComp;

    UPROPERTY(Category = "Tower")
    int32 Cost = 100;

    UPROPERTY(Category = "Tower")
    int32 Damage = 1;

    UPROPERTY(Category = "Tower")
    float Range = 1000.0f;

    UPROPERTY(Category = "Tower")
    float FireRate = 1.0f;

    UPROPERTY(Category = "Tower")
    TSubclassOf<AProjectile> ProjectileClass;

    UPROPERTY(DefaultComponent, Attach = Root)
    USceneComponent FirePoint;

    UPROPERTY(BlueprintReadOnly, VisibleAnywhere, Replicated, ReplicatedUsing = OnRep_IsBuilt, Transient, Category = "Tower")
    bool bIsBuilt = false;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        if (System::IsServer())
        {
            //Bind InteractableComponent delegate functions.
            InteractableComp.OnInteractDelegate.BindUFunction(this, n"Interact");
            InteractableComp.CanInteractDelegate.BindUFunction(this, n"CanInteract");
        }

        //Makes sure Mesh visibilities are correct from the start.
        OnRep_IsBuilt();
    }

    UFUNCTION()
    private bool CanInteract(APlayerController User)
    {
        return !bIsBuilt;
    }

    UFUNCTION()
    private void Interact(APlayerController User)
    {
        bIsBuilt = true;
        OnRep_IsBuilt();
    }

    UFUNCTION()
    void Fire()
    {
        if (ProjectileClass != nullptr)
        {
            FRotator Direction = FirePoint.GetWorldRotation();
            AProjectile Projectile = Cast<AProjectile>(SpawnActor(ProjectileClass, FirePoint.GetWorldLocation(), Direction));
            
            AStaticAOEProjectile StaticAOEProjectile = Cast<AStaticAOEProjectile>(Projectile);

            if(IsValid(StaticAOEProjectile)) // TODO: Replace with a better solution
            {
                StaticAOEProjectile.Range = Range;
                StaticAOEProjectile.SetActorScale3D(FVector(Range * 0.02f));
            }
        }
    }

    UFUNCTION()
    void OnRep_IsBuilt()
    {
        FinishedMesh.SetVisibility(bIsBuilt);
        PreviewMesh.SetVisibility(!bIsBuilt);

        if (System::IsServer() && bIsBuilt)
        {
            System::SetTimer(this, n"Fire", FireRate, true);
        }          
    }
};