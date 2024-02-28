// Fill out your copyright notice in the Description page of Project Settings.


#include "RoadMeshComponent.h"
#include "Components/SplineComponent.h"
#include "Kismet/KismetSystemLibrary.h"

void URoadMeshComponent::GenerateMeshFromSpline()
{
	if (!SplineRef)
		SplineRef = GetOwner()->GetComponentByClass<USplineComponent>();
	
	if (!SplineRef)
	{
		UE_LOG(LogTemp, Warning, TEXT("No Spline component reference available. Cancelling!"));
		return;
	}

    //Reset previous mesh before creating new one
    ClearAllMeshSections();

    //Sample the desired number of points along the spline, at equidistant positions
    TArray<FVector> Points = GeneratePointsAlongPath();
    if (Points.Num() < 3) return;

    //Allocate all required mesh data
    TArray<FVector> Vertices;
    TArray<FVector> Normals;
    TArray<int> Triangles;
    TArray<FLinearColor> Colors;
    TArray<FVector2D> UV;
    TArray<FProcMeshTangent> Tangents; //EMPTY

    //Manually handle first point
    FVector FirstForward = SplineRef->GetTangentAtDistanceAlongSpline(0.0f, ESplineCoordinateSpace::Local).GetSafeNormal(); //(Points[1] - Points[0]).GetSafeNormal();
    FVector RightDirection = FVector::CrossProduct(FirstForward, SplineRef->GetDefaultUpVector(ESplineCoordinateSpace::Local)); // Forward x Up = Right; Right x Forward = Up; Up x Right = Forward
    
    // -- Main Road -- 
    Vertices.Add(Points[0] - RightDirection * RoadWidth + FVector::UpVector * RoadHeight);
    Vertices.Add(Points[0] + RightDirection * RoadWidth + FVector::UpVector * RoadHeight);
    Normals.Add(FVector::UpVector); 
    Normals.Add(FVector::UpVector); // It might be appropriate to change these to RightDirection.CrossProduct(FirstForward) instead of UpVector
    UV.Add(FVector2D(0.1f, 0.1f));
    UV.Add(FVector2D(0.9f, 0.1f));
    Colors.Add(FLinearColor::White);
    Colors.Add(FLinearColor::White);
    // -- Road Edge --
    Vertices.Add(Points[0] - RightDirection * (RoadWidth + EdgeWidth));
    Vertices.Add(Points[0] + RightDirection * (RoadWidth + EdgeWidth));
    Normals.Add(-RightDirection); 
    Normals.Add(RightDirection);
    UV.Add(FVector2D(0.0f, 0.1f));
    UV.Add(FVector2D(1.0f, 0.1f));
    Colors.Add(FLinearColor::Green);
    Colors.Add(FLinearColor::Green);

    FVector CurrentForward;
    FVector CurrentRight;
    FVector CurrentUp;
    for (int i = 1; i < Points.Num(); i++)
    {
        // -- Main Road --

        //Determine Forward using spline tangent.  
        CurrentForward = SplineRef->GetTangentAtDistanceAlongSpline(SplineRef->GetSplineLength() * i / Points.Num(), ESplineCoordinateSpace::Local).GetSafeNormal();
        //Right and Up are generated using cross products, using the global Up vector to make sure the path is flat from side to side.
        CurrentRight = FVector::CrossProduct(CurrentForward, FVector::UpVector);
        CurrentUp = FVector::CrossProduct(CurrentRight, CurrentForward);

        //Add left-side road vertex, then right-side. 
        Vertices.Add(Points[i] - CurrentRight * RoadWidth + CurrentUp * RoadHeight);
        Vertices.Add(Points[i] + CurrentRight * RoadWidth + CurrentUp * RoadHeight);
        
        //Establish triangles
        int T = Vertices.Num() - 1;
        Triangles.Add(T); Triangles.Add(T - 4); Triangles.Add(T - 1);
        Triangles.Add(T - 1); Triangles.Add(T - 4); Triangles.Add(T - 5);
        
        Normals.Add(CurrentUp);
        Normals.Add(CurrentUp);
        Colors.Add(FLinearColor::White); 
        Colors.Add(FLinearColor::White);

        //UV, X: left-to-right, Y: start-to-end.
        float UVY = float(i) / float(Points.Num());
        float LerpedUVY = FMath::Lerp(0.1f, 0.9f, UVY);
        
        UV.Add(FVector2D(0.1f, LerpedUVY));
        UV.Add(FVector2D(0.9f, LerpedUVY));



        // -- Side Edge -- 
        
        //Add left-side edge vertex, then right-side
        Vertices.Add(Points[i] - CurrentRight * (RoadWidth + EdgeWidth));
        Vertices.Add(Points[i] + CurrentRight * (RoadWidth + EdgeWidth));

        //Establish triangles
        T = Vertices.Num() - 1;
        Triangles.Add(T); Triangles.Add(T - 4); Triangles.Add(T - 2);
        Triangles.Add(T - 2); Triangles.Add(T - 4); Triangles.Add(T - 6);
        Triangles.Add(T - 1); Triangles.Add(T - 3); Triangles.Add(T - 7);
        Triangles.Add(T - 1); Triangles.Add(T - 7); Triangles.Add(T - 5); 

        Normals.Add(-CurrentRight); 
        Normals.Add(CurrentRight);
        Colors.Add(FLinearColor::Green);
        Colors.Add(FLinearColor::Green);

        UV.Add(FVector2D(0.0f, LerpedUVY));
        UV.Add(FVector2D(1.0f, LerpedUVY));
    }

    // -- Back -- 
    Vertices.Add(Points[0] - RightDirection * RoadWidth - FirstForward * EdgeWidth);
    Vertices.Add(Points[0] + RightDirection * RoadWidth - FirstForward * EdgeWidth);

    int T = Vertices.Num() - 1;
    Triangles.Add(0); Triangles.Add(1); Triangles.Add(T);
    Triangles.Add(0); Triangles.Add(T); Triangles.Add(T - 1);
    Triangles.Add(T); Triangles.Add(1); Triangles.Add(3);
    Triangles.Add(T - 1); Triangles.Add(2); Triangles.Add(0);

    Normals.Add(-FirstForward); 
    Normals.Add(-FirstForward);
    Colors.Add(FLinearColor::Green);
    Colors.Add(FLinearColor::Green);

    UV.Add(FVector2D(0.1f, 0.0f));
    UV.Add(FVector2D(0.9f, 0.0f));

    // -- Front --
    Vertices.Add(Points.Last() - CurrentRight * RoadWidth + CurrentForward * EdgeWidth);
    Vertices.Add(Points.Last() + CurrentRight * RoadWidth + CurrentForward * EdgeWidth);

    T = Vertices.Num() - 1;
    Triangles.Add(T - 1); Triangles.Add(T); Triangles.Add(T - 6);
    Triangles.Add(T - 1); Triangles.Add(T - 6); Triangles.Add(T - 7);
    Triangles.Add(T); Triangles.Add(T - 4); Triangles.Add(T - 6);
    Triangles.Add(T - 1); Triangles.Add(T - 7); Triangles.Add(T - 5);

    Normals.Add(CurrentForward); 
    Normals.Add(CurrentForward);
    Colors.Add(FLinearColor::Green);
    Colors.Add(FLinearColor::Green);

    UV.Add(FVector2D(0.1f, 1.0f));
    UV.Add(FVector2D(0.9f, 1.0f));

    TempUVs = UV;

    SetMaterial(0, MaterialRef);
    CreateMeshSection_LinearColor(0, Vertices, Triangles, Normals, UV, Colors, Tangents, true);
}


TArray<FVector> URoadMeshComponent::GeneratePointsAlongPath() const
{
    int NumberOfPoints = FMath::CeilToInt(SplineRef->GetSplineLength() / LengthPerPoint) + 1;
    float ActualLengthPerPoint = SplineRef->GetSplineLength() / (NumberOfPoints - 1);

    TArray<FVector> Points;
    for (int i = 0; i < NumberOfPoints; i++)
    {
        Points.Add(SplineRef->GetLocationAtDistanceAlongSpline(ActualLengthPerPoint * i, ESplineCoordinateSpace::Local));
    }
    return Points;
}