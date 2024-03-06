class ATDCharacter : ACharacter
{
    // Input
    UPROPERTY(Category = "Input")
    UInputMappingContext IMC;
    UPROPERTY(Category = "Input")
    UInputAction MoveAction;
    UPROPERTY(Category = "Input")
    UInputAction LookAction;
    UPROPERTY(Category = "Input")
    UInputAction InteractAction;

    // Camera
    UPROPERTY(DefaultComponent, Category = "Camera")
    USpringArmComponent SpringArm;
    default SpringArm.bUsePawnControlRotation = true;
    default SpringArm.TargetArmLength = 550;
    UPROPERTY(DefaultComponent, Category = "Camera", Attach = SpringArm)
    UCameraComponent Camera;

    UPROPERTY(DefaultComponent)
    UInteractionComponent InteractionComponent;

    UPROPERTY()
    APlayerController PlayerController;

    // Player-Specific Mesh Colors
    UPROPERTY()
    UPlayerColorsDataAsset PlayerColors;
    private bool bShouldUpdateMaterialColor = true;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        PlayerController = Cast<APlayerController>(Controller);
        RegisterObject(ERegisteredObjectTypes::ERO_Player);
        
    }

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason EndPlayReason)
    {        
        DeregisterObject(ERegisteredObjectTypes::ERO_Player);
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        //Handle setting color on connecting. Waits for the PlayerState to be assigned. Cannot be done in BeginPlay as PlayerState can be null
        if (bShouldUpdateMaterialColor && PlayerState != nullptr)
        {
            if (PlayerColors == nullptr)
            {
                bShouldUpdateMaterialColor = false;
                return;
            }

            ATDPlayerState PS = Cast<ATDPlayerState>(PlayerState);
            if (PS != nullptr)
            {
                Mesh.SetVectorParameterValueOnMaterials(FName("Tint"), PlayerColors.GetColorOf(PS.PlayerIndex));
            }
            bShouldUpdateMaterialColor = false;
        }
    }

    UFUNCTION(BlueprintCallable)
    void Interact()
    {
        InteractionComponent.TryInteract(PlayerController);
    }

    UFUNCTION(BlueprintCallable)
    void Move(FVector2D Direction)
    {
        if (Direction.Size() > 0)
        {
            FVector Forward = GetActorForwardVector();
            FVector Right = GetActorRightVector();
            Forward.Z = 0;
            Right.Z = 0;
            Forward.Normalize();
            Right.Normalize();
            FVector Movement = Forward * Direction.Y + Right * Direction.X;
            Movement.Normalize();
            AddMovementInput(Movement, 1, true);
        }

        
    }

    UFUNCTION(BlueprintCallable)
    void Look(FVector2D Direction)
    {
        if (Direction.Size() > 0)
        {
            float Yaw = Direction.X;
            float Pitch = Direction.Y;
            AddControllerYawInput(Yaw);
            AddControllerPitchInput(Pitch);
        }
    }    

}
