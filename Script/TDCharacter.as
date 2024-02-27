﻿class ATDCharacter : ACharacter
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

    UPROPERTY()
    UHealthBarWidget HealthBarWidget;
    UPROPERTY()
    TSubclassOf<UHealthBarWidget> HealthBarWidgetClass;



    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        PlayerController = Cast<APlayerController>(Controller);
        UObjectRegistry::Get().RegisterObject(this, ERegisteredObjectTypes::ERO_Monster);  // TODO: Change when we can test with enemies

        HealthSystemComponent.OnHealthChanged.AddUFunction(this, n"OnHealthChanged");
        TArray<UUserWidget> FoundWidgets;
        Widget::GetAllWidgetsOfClass(FoundWidgets, HealthBarWidgetClass, false);
        if (FoundWidgets.Num() > 0)
        {
            HealthBarWidget = Cast<UHealthBarWidget>(FoundWidgets[0]);
            if(IsValid(HealthBarWidget)){
                Print("HealthBarWidget is valid");
            }
        }
        
    }

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason EndPlayReason)
    {
        UObjectRegistry::Get().DeregisterObject(this, ERegisteredObjectTypes::ERO_Monster); // TODO: Change when we can test with enemies
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
    void OnHealthChanged(int32 Health, int32 MaxHealth)
    {
        if (Health <= 0)
        {
            // Death Logic Here
            DisableInput(PlayerController);
        }
        if(System::IsServer())
        {
            // Server Logic Here
        }
        else
        {
            // Client Logic Here
        }
    }

}
