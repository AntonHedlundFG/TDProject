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
	if (GetLocalRole() == ROLE_Authority)
	{
		auto Subsystem = GetGameInstance()->GetSubsystem<UEpicOnlineSubsystem>();
		
		if (IsValid(Subsystem))
		{
			Subsystem->PlayerDisconnected(this);
		}
	}
	Super::OnNetCleanup(Connection);
}

void AOnlinePlayerController::SetTraveling(bool bNewState)
{
	if (GetNetMode() > ENetMode::NM_ListenServer) return;
	
	bIsTraveling = bNewState;
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