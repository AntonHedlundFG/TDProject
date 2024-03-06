
class UTDEnemyWaveInfo : UDataAsset
{
    UPROPERTY()
    TArray<FWave> Waves;
}

struct FWave
{
    UPROPERTY()
    int SpawnFrequency;
    UPROPERTY()
    TArray<FWaveSection> WaveSections;
}

struct FWaveSection
{
    UPROPERTY()
    TSubclassOf<ATDEnemy> unit;
    UPROPERTY()
    int amount;
}