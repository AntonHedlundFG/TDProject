class UPurchasable : UDataAsset
{
    UPROPERTY()
    int Price = 100;

    UPROPERTY()
    FString Name = "Default";

    void OnPurchase(ATowerBase Tower)
    {

    }
}