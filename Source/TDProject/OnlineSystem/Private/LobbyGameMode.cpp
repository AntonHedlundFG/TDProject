// Fill out your copyright notice in the Description page of Project Settings.


#include "TDProject\OnlineSystem\Public\LobbyGameMode.h"
#include "TDProject\OnlineSystem\Public\EpicOnlineSubsystem.h"

void ALobbyGameMode::PostLogin(APlayerController* NewPlayer)
{
	if (!NewPlayer->IsLocalController())
	{
		auto Subsystem = GetGameInstance()->GetSubsystem<UEpicOnlineSubsystem>();
		if (IsValid(Subsystem))
			Subsystem->PlayerConnected(NewPlayer);
	}
	
	
	Super::PostLogin(NewPlayer);
}
