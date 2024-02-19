// Copyright Epic Games, Inc. All Rights Reserved.

#include "TDProjectGameMode.h"
#include "TDProjectCharacter.h"
#include "UObject/ConstructorHelpers.h"

ATDProjectGameMode::ATDProjectGameMode()
{
	// set default pawn class to our Blueprinted character
	static ConstructorHelpers::FClassFinder<APawn> PlayerPawnBPClass(TEXT("/Game/ThirdPerson/Blueprints/BP_ThirdPersonCharacter"));
	if (PlayerPawnBPClass.Class != NULL)
	{
		DefaultPawnClass = PlayerPawnBPClass.Class;
	}
}
