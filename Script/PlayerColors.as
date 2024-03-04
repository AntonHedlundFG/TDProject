event void FOnMaterialsUpdated();

class UPlayerColorsDataAsset : UDataAsset
{
    UPROPERTY(Replicated, ReplicatedUsing = OnRep_PlayerSpecificMaterials)
    private TMap<uint8, UMaterial> PlayerSpecificMaterials;

    // When triggered, informs other objects that a material has been changed. 
    // For example, if a player chooses a different color in runtime, all towers should update their color accordingly.
    FOnMaterialsUpdated OnMaterialsUpdated;

    UMaterial GetMaterialOf(uint8 PlayerIndex)
    {
        if (!PlayerSpecificMaterials.Contains(PlayerIndex) || PlayerSpecificMaterials[PlayerIndex] == nullptr)
            return nullptr;

        return PlayerSpecificMaterials[PlayerIndex];
    }

    void SetMaterialOf(uint8 PlayerIndex, UMaterial NewMaterial)
    {
        if (!System::IsServer()) return;

        if (PlayerSpecificMaterials.Contains(PlayerIndex))
        {
            PlayerSpecificMaterials[PlayerIndex] = NewMaterial;
        }
        else
        {
            PlayerSpecificMaterials.Add(PlayerIndex, NewMaterial);
        }
        OnRep_PlayerSpecificMaterials();
    }

    UFUNCTION()
    void OnRep_PlayerSpecificMaterials()
    {
        OnMaterialsUpdated.Broadcast();
    }
}