
class UTDEnemyWaveInfo : UDataAsset
{
    UPROPERTY()
    TArray<FWave> Waves;
}

struct FWave
{
    UPROPERTY()
    float SpawnFrequency;
    UPROPERTY()
    TArray<FWaveSection> WaveSections;
}

struct FWaveSection
{
    UPROPERTY()
    UTDEnemyData unit;
    UPROPERTY()
    int amount;
}