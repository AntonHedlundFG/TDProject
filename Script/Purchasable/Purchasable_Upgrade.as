class UPurchasable_Upgrade : UPurchasable
{
    FProjectileData Data;
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