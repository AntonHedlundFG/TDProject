// Fill out your copyright notice in the Description page of Project Settings.


#include "TDProject\OnlineSystem\Public\LobbyGameMode.h"
#include "TDProject\OnlineSystem\Public\EpicOnlineSubsystem.h"

void ALobbyGameMode::PostLogin(APlayerController* NewPlayer)
{
	auto Subsystem = GetGameInstance()->GetSubsystem<UEpicOnlineSubsystem>();

	if (!Subsystem || !Subsystem->IsPlayerLoggedIn())
	{
		Super::PostLogin(NewPlayer);
		return;
	}

	Subsystem->PlayerConnected(NewPlayer);

	// -- HANDLE REPOSSESSING OF PAWNS WHEN RECONNECTING BELOW --

	//If we have no unique net ID we are currently not using online functionality, probably PIE.
	const FUniqueNetIdRepl UniqueNetID = Subsystem->GetUniqueNetIdOf(NewPlayer);

	const FString UniqueNetIDString = UniqueNetID->ToString();

	//Check if our map contains a pawn assigned to the players unique ID, if so, possess it.
	if (IdToPawnMap.Contains(UniqueNetIDString) && IsValid(IdToPawnMap[UniqueNetIDString]))
	{
		NewPlayer->Possess(IdToPawnMap[UniqueNetIDString]);
		IdToPawnMap.Remove(UniqueNetIDString);
	}

	//This is where a pawn gets spawned if the player doesn't already have one
	Super::PostLogin(NewPlayer);

	//Regardless of whether we spawned a new pawn or possessed a previous one, make sure it's mapped.
	IdToPawnMap.Add(UniqueNetIDString, NewPlayer->GetPawn());
}

void ALobbyGameMode::HandleSeamlessTravelPlayer(AController*& C)
{
	Super::HandleSeamlessTravelPlayer(C);

	// -- REGISTER PAWNS FOR REPOSSESSING WHEN SEAMLESSLY TRAVELLING --

	auto Subsystem = GetGameInstance()->GetSubsystem<UEpicOnlineSubsystem>();
	if (!Subsystem || !Subsystem->IsPlayerLoggedIn()) return;

	APlayerController* PC = Cast<APlayerController>(C);
	if (!PC || !PC->GetPawn()) return;

	const FUniqueNetIdRepl UniqueNetID = Subsystem->GetUniqueNetIdOf(PC);
	const FString UniqueNetIDString = UniqueNetID->ToString();

	IdToPawnMap.Add(UniqueNetIDString, PC->GetPawn());
}
