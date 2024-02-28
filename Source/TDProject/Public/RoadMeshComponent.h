// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "ProceduralMeshComponent.h"
#include "RoadMeshComponent.generated.h"

/**
 * 
 */
UCLASS(Blueprintable)
class TDPROJECT_API URoadMeshComponent : public UProceduralMeshComponent
{
	GENERATED_BODY()
	
public:

	UPROPERTY(EditAnywhere)
	class USplineComponent* SplineRef;

	UPROPERTY(EditAnywhere)
	class UMaterial* MaterialRef;

protected:

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float LengthPerPoint = 100.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float RoadWidth = 100.0f;

	UFUNCTION(CallInEditor)
	void GenerateMeshFromSpline();

	TArray<FVector> GeneratePointsAlongPath() const;
};
