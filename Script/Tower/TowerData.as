class UTowerData : UDataAsset
{
    // Fire rate in seconds
    UPROPERTY(Category = "Tower")
    float FireRate = 1.0f;
    // How often the tower should update its target
    UPROPERTY(Category = "Tower")
    float TargetUpdateRate = 0.5f;
    // Percentage of the target's velocity to lead (1 = 100% of the target's velocity, 0 = no lead, -1 = 100% of the target's velocity in the opposite direction)
    UPROPERTY(EditAnywhere, Category = "Tower|Tracking", meta = (EditCondition = "bShouldTrackTarget"))
    float TrackingLeadPercentage = 0.0f;
    // How often the tower should update its target's position
    UPROPERTY(EditAnywhere, Category = "Tower|Tracking", meta = (EditCondition = "bShouldTrackTarget"))
    float TrackingUpdateRate = 0.1f;
    // Degrees per second
    UPROPERTY(EditAnywhere, Category = "Tower|Tracking", meta = (EditCondition = "bShouldTrackTarget"))
    float RotationSpeedXAxis = 0.0f;    
    // Degrees per second
    UPROPERTY(EditAnywhere, Category = "Tower|Tracking", meta = (EditCondition = "bShouldTrackTarget"))
    float RotationSpeedYAxis = 0.0f;


    UPROPERTY()
    FProjectileData ProjectileData;
}