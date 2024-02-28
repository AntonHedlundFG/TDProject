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

	UPROPERTY(EditAnywhere, Category = RoadMesh)
	class USplineComponent* SplineRef;

	UPROPERTY(EditAnywhere, Category = RoadMesh)
	class UMaterial* MaterialRef;

	UPROPERTY(VisibleAnywhere, Category = RoadMesh)
	TArray<FVector2D> TempUVs;

protected:

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = RoadMesh)
	float LengthPerPoint = 100.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = RoadMesh)
	float RoadWidth = 100.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = RoadMesh)
	float RoadHeight = 10.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = RoadMesh)
	float EdgeWidth = 10.0f;

	UFUNCTION(CallInEditor, Category = RoadMesh)
	void GenerateMeshFromSpline();

	TArray<FVector> GeneratePointsAlongPath() const;
};
