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

    UPROPERTY(DefaultComponent)
    UHealthSystemComponent HealthSystemComponent;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        PlayerController = Cast<APlayerController>(Controller);
        UObjectRegistry::Get().RegisterObject(this, ERegisteredObjectTypes::ERO_Monster);
    }
    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason EndPlayReason)
    {
        UObjectRegistry::Get().DeregisterObject(this, ERegisteredObjectTypes::ERO_Monster);
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
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

    UFUNCTION(BlueprintCallable)
    void OnHealthChanged(float Health, float MaxHealth)
    {
        if (Health <= 0)
        {
            // Death Logic Here
            DisableInput(PlayerController);
            Print(f"Character {GetName()} has died!");
        }
    }

}
