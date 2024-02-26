// Fill out your copyright notice in the Description page of Project Settings.


#include "TDProject\OnlineSystem\Public\OnlinePlayerController.h"
#include "TDProject\OnlineSystem\Public\LobbyGameMode.h"
#include "TDProject\OnlineSystem\Public\EpicOnlineSubsystem.h"
#include "Net/UnrealNetwork.h"

#include "Kismet/KismetSystemLibrary.h"

void AOnlinePlayerController::GetLifetimeReplicatedProps(TArray< FLifetimeProperty >& OutLifetimeProps) const
{
	Super::GetLifetimeReplicatedProps(OutLifetimeProps);
	DOREPLIFETIME(AOnlinePlayerController, bIsTraveling);
}

void AOnlinePlayerController::OnNetCleanup(UNetConnection* Connection)
{
	auto Subsystem = GetGameInstance()->GetSubsystem<UEpicOnlineSubsystem>();
	
	if (GetLocalRole() == ROLE_Authority)
	{
		if (IsValid(Subsystem) && Subsystem->IsPlayerLoggedIn())
		{
			Subsystem->PlayerDisconnected(this);
		}
	}
	if (IsLocalController())
		Subsystem->DestroySession();

	Super::OnNetCleanup(Connection);
}

void AOnlinePlayerController::SetTraveling(bool bNewState)
{
	if (GetNetMode() > ENetMode::NM_ListenServer) return;
	
	bIsTraveling = bNewState;
}

void AOnlinePlayerController::PawnLeavingGame()
{
	auto Subsystem = GetGameInstance()->GetSubsystem<UEpicOnlineSubsystem>();
	if (bDoNotDespawnPawnOnDisconnect && GetLocalRole() == ROLE_Authority 
		&& IsValid(Subsystem) && Subsystem->IsPlayerLoggedIn())
	{
	}
	else
	{
		Super::PawnLeavingGame();
	}
}

void AOnlinePlayerController::Server_ManualDisconnect_Implementation()
{
	auto Subsystem = GetGameInstance()->GetSubsystem<UEpicOnlineSubsystem>();
	Subsystem->UnregisterPlayer(this);
}

bool AOnlinePlayerController::Server_ManualDisconnect_Validate()
{
	return true;
}