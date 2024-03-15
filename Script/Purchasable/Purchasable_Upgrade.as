class UPurchasable_Upgrade : UPurchasable
{
    UPROPERTY()
    UTowerData Data;
    UPROPERTY()
    TArray<UPurchasable> NewPurchasables;

    void OnPurchase(ATDPlayerState PlayerState, ATowerBase Tower) override
    {
        Super::OnPurchase(PlayerState, Tower);
 
        ATower tower = Cast<ATower>(Tower);
        if(IsValid(tower))
        {
            tower.SetTowerData(Data);
            tower.Purchasables = NewPurchasables;
        } 
    }
}