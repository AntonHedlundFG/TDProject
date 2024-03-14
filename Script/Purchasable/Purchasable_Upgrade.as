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
            tower.TowerData = Data;
            tower.Purchasables.Remove(this);
            for(int i = 0; i < NewPurchasables.Num(); i++)
            {
                tower.Purchasables.Add(NewPurchasables[i]);
            }
        } 
    }
}