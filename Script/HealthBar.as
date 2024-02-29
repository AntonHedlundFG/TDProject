class UHealthBarWidgetComponent : UWidgetComponent
{

    APlayerController PlayerController;
    APawn PlayerPawn;
    APlayerCameraManager CameraManager;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        CameraManager = Gameplay::GetPlayerCameraManager(0);
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        if (IsValid(CameraManager))
        {
            FVector ToCamera = CameraManager.GetActorLocation() - GetOwner().GetActorLocation();
            FRotator LookAtRotation = ToCamera.Rotation();
            SetWorldRotation(LookAtRotation);
        }
    }
}

class UHealthBarWidget : UUserWidget
{
    UFUNCTION(BlueprintCallable, Category = "HealthBar")
    void UpdateHealthBar(int32 HealthValue, int32 MaxHealthValue)
    {
        // Careful not to divide by zero
        if (MaxHealthValue == 0)
        {
            Print("MaxHealthValue is zero! Cannot calculate health percentage!");
            return;
        }

        // Calculate the percentage of health remaining in the range 0..1
        float HealthPercentage = float(HealthValue) / float(MaxHealthValue);
        SetHealthBarPercentage(HealthPercentage);

        if(HealthPercentage <= 0.0f || HealthPercentage >= 1.0f)
        {
            SetVisibility(ESlateVisibility::Hidden);
        }
        else
        {
            SetVisibility(ESlateVisibility::Visible);
        }

    }

    UFUNCTION(BlueprintEvent)
    void SetHealthBarPercentage(float HealthPercentage)
    {
        Print("SetHealthBarPercentage called but not overriden in blueprint! Please override this function in blueprint!");
    }

}