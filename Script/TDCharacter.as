class ATDCharacter : ARegisteredCharacter
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
    APlayerController player;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Super::BeginPlay();
        player = Cast<APlayerController>(Controller);
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
    }

    UFUNCTION(BlueprintCallable)
    void Interact()
    {
        InteractionComponent.TryInteract(player);
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
