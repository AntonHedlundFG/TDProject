// Fill out your copyright notice in the Description page of Project Settings.


#include "TDPlayerState.h"
#include "Net/UnrealNetwork.h"


void ATDPlayerState::GetLifetimeReplicatedProps(TArray< FLifetimeProperty >& OutLifetimeProps) const
{
	Super::GetLifetimeReplicatedProps(OutLifetimeProps);
	DOREPLIFETIME(ATDPlayerState, Gold);
	DOREPLIFETIME(ATDPlayerState, PlayerIndex);
}

void ATDPlayerState::CopyProperties(APlayerState* PlayerState)
{
	if (ATDPlayerState* CastState = Cast<ATDPlayerState>(PlayerState))
	{
		CastState->UniqueOwnerNetID = UniqueOwnerNetID;
		CastState->Gold = Gold;
		CastState->PlayerIndex = PlayerIndex;
	}
}

void ATDPlayerState::BeginPlay()
{
	if (GetNetMode() <= ENetMode::NM_ListenServer)
		Gold = StartingGold;
}

