class UPurchasable_Upgrade : UPurchasable
{
    UPROPERTY()
    FProjectileData Data;
    UPROPERTY()
    TArray<UPurchasable> NewPurchasables;

    void OnPurchase(ATowerBase Tower) override
    {
        Super::OnPurchase(Tower);

        ATower tower = Cast<ATower>(Tower);
        if(IsValid(tower))
        {
            tower.ProjectileData = Data;
            tower.Purchasables = NewPurchasables;
        } 
    }
}