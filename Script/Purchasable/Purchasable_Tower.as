class UPurchasable_Tower : UPurchasable
{
    UPROPERTY()
    TSubclassOf<ATower> towerToBuild;

    void OnPurchase(ATowerBase Tower) override
    {
        Super::OnPurchase(Tower);

        ATower SpawnedTower = Cast<ATower>(SpawnActor(towerToBuild, Tower.ActorLocation, Tower.ActorRotation, FName(), true ));
        SpawnedTower.OwningPlayerIndex = Tower.OwningPlayerIndex;
        SpawnedTower.UpdateMeshColors();
        SpawnedTower.SetActorLabel(SpawnedTower.DefaultActorLabel);
        FinishSpawningActor(SpawnedTower);

        Tower.DestroyActor();
    }
}