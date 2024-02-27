class UHealthBarWidget : UUserWidget
{
    UFUNCTION(BlueprintCallable, Category = "HealthBar")
    void UpdateHealthBar(int32 HealthValue, int32 MaxHealthValue)
    {
        // Calculate the percentage of health remaining in the range 0..1
        float HealthPercentage = float(HealthValue) / float(MaxHealthValue);
        SetHealthBarPercentage(HealthPercentage);

    }

    UFUNCTION(BlueprintEvent)
    void SetHealthBarPercentage(float HealthPercentage)
    {
        Print("SetHealthBarPercentage called but not overriden in blueprint! Please override this function in blueprint!");
    }

}