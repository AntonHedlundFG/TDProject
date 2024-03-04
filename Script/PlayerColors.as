event void FOnMaterialsUpdated();

class UPlayerColorsDataAsset : UDataAsset
{
    UPROPERTY(Replicated, ReplicatedUsing = OnRep_PlayerSpecificMaterials)
    private TMap<uint8, FVector> PlayerSpecificColors;

    // When triggered, informs other objects that a material has been changed. 
    // For example, if a player chooses a different color in runtime, all towers should update their color accordingly.
    UPROPERTY()
    FOnMaterialsUpdated OnMaterialsUpdated;

    UFUNCTION()
    FVector GetColorOf(uint8 PlayerIndex)
    {
        if (!PlayerSpecificColors.Contains(PlayerIndex))
            return FVector();

        return PlayerSpecificColors[PlayerIndex];
    }

    UFUNCTION()
    void SetColorOf(uint8 PlayerIndex, FVector NewColor)
    {
        if (!System::IsServer()) return;

        if (PlayerSpecificColors.Contains(PlayerIndex))
        {
            PlayerSpecificColors[PlayerIndex] = NewColor;
        }
        else
        {
            PlayerSpecificColors.Add(PlayerIndex, NewColor);
        }
        OnRep_PlayerSpecificMaterials();
    }

    UFUNCTION()
    void OnRep_PlayerSpecificMaterials()
    {
        OnMaterialsUpdated.Broadcast();
    }
}