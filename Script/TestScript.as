class ATestScript : AActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Print(FString("Test"));
    }
};