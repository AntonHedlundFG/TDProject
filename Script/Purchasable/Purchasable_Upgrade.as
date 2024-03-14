class UPurchasable_Upgrade : UPurchasable
{
    UPROPERTY()
    FProjectileData Data;
    UPROPERTY()
    TArray<UPurchasable> NewPurchasables;

    void OnPurchase(ATDPlayerState PlayerState, ATowerBase Tower) override
    {
        Super::OnPurchase(PlayerState, Tower);

        ATower tower = Cast<ATower>(Tower);
        if(IsValid(tower))
        {
            tower.TowerData.ProjectileData = Data;
            tower.Purchasables = NewPurchasables;
        } 
    }
}