class UPurchasable : UDataAsset
{
    UPROPERTY()
    int Price = 100;

    UPROPERTY()
    FString Name = "Default";

    void OnPurchase(ATDPlayerState PlayerState, ATowerBase Tower)
    {
        PlayerState.Gold -= Price;
    }
}