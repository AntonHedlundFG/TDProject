class UTDEnemyData : UDataAsset
{
    UPROPERTY(BlueprintReadWrite, Category = "Enemy Settings")
    int PointValue = 1;
    UPROPERTY(BlueprintReadWrite, Category = "Enemy Settings")
    int KillBounty = 1;
    UPROPERTY(BlueprintReadWrite, Category = "Enemy Settings")
    int Damage = 1;
    UPROPERTY(BlueprintReadWrite, Category = "Enemy Settings")
    float MoveSpeed = 500;
    UPROPERTY(BlueprintReadWrite, Category = "Enemy Settings")
    int MaxHealth = 500;
    UPROPERTY(BlueprintReadWrite, Category = "Enemy Settings")
    UMaterialInstance Material;
    UPROPERTY(BlueprintReadWrite, Category = "Enemy Settings")
    FLinearColor Color;
    UPROPERTY(BlueprintReadWrite, Category = "Enemy Settings")
    bool bRemoveDamageEffectsOnCreation = true;
    UPROPERTY(BlueprintReadWrite, Category = "Enemy Settings")
    UTDEnemyData NextLevelEnemy;
}