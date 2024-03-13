class UPurchasable_Upgrade : UPurchasable
{
    FProjectileData data;

    void OnPurchase(ATowerBase Tower) override
    {
        Super::OnPurchase(Tower);

        ATower tower = Cast<ATower>(Tower);
        if(IsValid(tower))
        {
            tower.ProjectileData = data;
        } 
    }
}