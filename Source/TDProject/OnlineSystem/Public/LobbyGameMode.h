// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "LobbyGameMode.generated.h"

class ATDPlayerState;

/**
 * 
 */
UCLASS()
class TDPROJECT_API ALobbyGameMode : public AGameModeBase
{
	GENERATED_BODY()
	
public:

	virtual void PostLogin(APlayerController* NewPlayer) override;
	virtual void HandleSeamlessTravelPlayer(AController*& C) override;
	virtual void Logout(AController* Exiting) override;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Online Services")
	bool bPlayersCanReconnectDuringMatch = true;

private:

	TMap<FString, APawn*> IdToPawnMap;

	TArray<ATDPlayerState*> InactiveStates;

	uint8 NextPlayerIndex = 1; // Host is always 0

};
