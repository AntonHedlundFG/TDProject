
class UTDEnemyWaveInfo : UDataAsset
{
    UPROPERTY()
    TArray<FWave> WaveArray;
}

struct FWave
{
    UPROPERTY()
    FString WaveName = "";
    UPROPERTY()
    TMap<TSubclassOf<ATDEnemy>, int> WaveMap;
}