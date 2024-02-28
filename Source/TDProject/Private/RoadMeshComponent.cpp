// Fill out your copyright notice in the Description page of Project Settings.


#include "RoadMeshComponent.h"
#include "Components/SplineComponent.h"

void URoadMeshComponent::GenerateMeshFromSpline()
{
	if (!SplineRef)
		SplineRef = GetOwner()->GetComponentByClass<USplineComponent>();
	
	if (!SplineRef)
	{
		UE_LOG(LogTemp, Warning, TEXT("No Spline component reference available. Cancelling!"));
		return;
	}


    ClearAllMeshSections();

    TArray<FVector> Points = GeneratePointsAlongPath();
    if (Points.Num() < 3) return;

    TArray<FVector> Vertices;
    TArray<FVector> Normals;
    TArray<int> Triangles;
    TArray<FLinearColor> Colors;
    TArray<FVector2D> UV;
    TArray<FProcMeshTangent> Tangents; //EMPTY

    //Manually handle first point
    FVector FirstForward = SplineRef->GetTangentAtDistanceAlongSpline(0.0f, ESplineCoordinateSpace::Local).GetSafeNormal(); //(Points[1] - Points[0]).GetSafeNormal();
    FVector RightDirection = FVector::CrossProduct(FirstForward, SplineRef->GetDefaultUpVector(ESplineCoordinateSpace::Local)); // Forward x Up = Right; Right x Forward = Up; Up x Right = Forward
    Vertices.Add(Points[0] - RightDirection * RoadWidth);
    Vertices.Add(Points[0] + RightDirection * RoadWidth);
    Normals.Add(FVector::UpVector); Normals.Add(FVector::UpVector); // It might be appropriate to change this to RightDirection.CrossProduct(FirstForward) instead of UpVector

    for (int i = 1; i < Points.Num(); i++)
    {
        FVector CurrentForward = SplineRef->GetTangentAtDistanceAlongSpline(SplineRef->GetSplineLength() * i / Points.Num(), ESplineCoordinateSpace::Local).GetSafeNormal();//(Points[i] - Points[i-1]).GetSafeNormal();
        FVector CurrentRight = FVector::CrossProduct(CurrentForward, FVector::UpVector);
        FVector CurrentUp = FVector::CrossProduct(CurrentRight, CurrentForward);
        Vertices.Add(Points[i] - CurrentRight * RoadWidth);
        Vertices.Add(Points[i] + CurrentRight * RoadWidth);
        int T = Vertices.Num() - 1;
        Triangles.Add(T); Triangles.Add(T - 2); Triangles.Add(T - 1);
        Triangles.Add(T - 1); Triangles.Add(T - 2); Triangles.Add(T - 3);
        Normals.Add(CurrentUp);
        Normals.Add(CurrentUp);
        Colors.Add(FLinearColor::Blue); Colors.Add(FLinearColor::Blue);
        float UVY = float(i) / float(Points.Num());
        UV.Add(FVector2D(0.0f, UVY)); FVector2D(1.0f, UVY);
    }

    SetMaterial(0, MaterialRef);
    //CreateMeshSection_LinearColor(0, Vertices, Triangles, Normals, UV, UV, UV, UV, Colors, Tangents, false);
    CreateMeshSection_LinearColor(0, Vertices, Triangles, Normals, UV, Colors, Tangents, true);
}


TArray<FVector> URoadMeshComponent::GeneratePointsAlongPath() const
{
    int NumberOfPoints = SplineRef->GetSplineLength() / LengthPerPoint;
    float ActualLengthPerPoint = SplineRef->GetSplineLength() / NumberOfPoints;

    TArray<FVector> Points;
    for (float i = 0.0f; i <= SplineRef->GetSplineLength(); i += ActualLengthPerPoint)
    {
        Points.Add(SplineRef->GetLocationAtDistanceAlongSpline(i, ESplineCoordinateSpace::Local));
    }
    return Points;
}