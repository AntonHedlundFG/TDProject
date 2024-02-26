// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "LobbyGameMode.generated.h"

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

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Online Services")
	bool bPlayersCanReconnectDuringMatch = true;

	void ClearIdToPawnMap() { IdToPawnMap.Empty(); }

private:

	TMap<FString, APawn*> IdToPawnMap;

};
