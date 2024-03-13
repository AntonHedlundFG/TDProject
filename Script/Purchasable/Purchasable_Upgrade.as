class UPurchasable_Upgrade : UPurchasable
{
    FProjectileData data;

    void OnPurchase(ATowerBase Tower) override
    {
        Super::OnPurchase(Tower);

        //Tower.ProjectileData = data;
    }
}