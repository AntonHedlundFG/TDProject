// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/PlayerState.h"
#include "TDPlayerState.generated.h"

/**
 * 
 */
UCLASS()
class TDPROJECT_API ATDPlayerState : public APlayerState
{
	GENERATED_BODY()
	
public:

	virtual void CopyProperties(APlayerState* PlayerState) override;
	virtual void BeginPlay() override;

	UPROPERTY()
	FString UniqueOwnerNetID;

	UPROPERTY(Replicated, EditAnywhere, BlueprintReadWrite)
	int Gold = 0;

protected:

	UPROPERTY(EditAnywhere, BlueprintReadOnly, meta = (ClampMin = 0))
	int StartingGold = 1000;
};
