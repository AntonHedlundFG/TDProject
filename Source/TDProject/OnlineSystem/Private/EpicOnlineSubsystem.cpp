// Fill out your copyright notice in the Description page of Project Settings.


#include "TDProject\OnlineSystem\Public\EpicOnlineSubsystem.h"
#include "OnlineSubsystem.h"
#include "OnlineSubsystemTypes.h"
#include "OnlineSubsystemUtils.h"
#include "Interfaces/OnlineIdentityInterface.h"
#include "Kismet/GameplayStatics.h"
#include "TDProject\OnlineSystem\Public\LobbyGameMode.h"
#include "Interfaces/OnlineExternalUIInterface.h"

#include "Kismet/KismetSystemLibrary.h"
#include "Engine/EngineBaseTypes.h"


void UEpicOnlineSubsystem::Initialize(FSubsystemCollectionBase& Collection)
{
	IOnlineSubsystem* Subsystem = Online::GetSubsystem(GetWorld());
	if (!Subsystem) return;
	IOnlineSessionPtr Session = Subsystem->GetSessionInterface();
	if (!Session) return;

	// Hooks up callback function for accepting game invites via the social overlay
	Session->OnSessionUserInviteAcceptedDelegates.AddUObject(this, &UEpicOnlineSubsystem::OnSessionUserInviteAccepted);
}

void UEpicOnlineSubsystem::Deinitialize()
{
	IOnlineSubsystem* Subsystem = Online::GetSubsystem(GetWorld());
	if (!Subsystem) return;
	IOnlineSessionPtr Session = Subsystem->GetSessionInterface();
	if (!Session) return;

	Session->ClearOnSessionUserInviteAcceptedDelegates(this);
}

FString UEpicOnlineSubsystem::GetSelfUsername()
{
	IOnlineSubsystem* Subsystem = Online::GetSubsystem(GetWorld());
	if (!Subsystem) return FString();
	IOnlineIdentityPtr Identity = Subsystem->GetIdentityInterface();
	if (!Identity) return FString();

	if (IsPlayerLoggedIn())
	{
		return Identity->GetPlayerNickname(0);
	}

	return FString("Unnamed Player");
}

void UEpicOnlineSubsystem::AttemptLoginWithAccountPortal()
{
	AttemptLogin(FString(), FString(), FString("accountportal"));
}

void UEpicOnlineSubsystem::AttemptDeveloperLogin(const FString& Token, const int Port)
{
	AttemptLogin(FString("127.0.0.1:") + FString::FromInt(Port), Token, FString("developer"));
}

void UEpicOnlineSubsystem::AttemptLogin(const FString& ID, const FString& Token, const FString& LoginType)
{
	IOnlineSubsystem* Subsystem = Online::GetSubsystem(GetWorld());
	if (!Subsystem) return;
	IOnlineIdentityPtr Identity = Subsystem->GetIdentityInterface();
	if (!Identity) return;

	if (IsWaitingForLoginAttempt())
	{
		UE_LOG(LogTemp, Warning, TEXT("There is already a Login attempt in progress."));
		return;
	}

	FOnlineAccountCredentials Credentials;
	Credentials.Id = ID;
	Credentials.Token = Token;
	Credentials.Type = LoginType;
	Identity->OnLoginCompleteDelegates->AddUObject(this, &UEpicOnlineSubsystem::OnLoginAttemptCompleted);
	bIsAttemptingLogin = true;
	Identity->Login(0, Credentials);
}

bool UEpicOnlineSubsystem::IsPlayerLoggedIn()
{
	IOnlineSubsystem* Subsystem = Online::GetSubsystem(GetWorld());
	if (!Subsystem) return false;
	IOnlineIdentityPtr Identity = Subsystem->GetIdentityInterface();
	if (!Identity) return false;

	return Identity->GetLoginStatus(0) == ELoginStatus::LoggedIn;
}

void UEpicOnlineSubsystem::OnLoginAttemptCompleted(int32 LocalUserNum, bool bWasSuccessful, const FUniqueNetId& UserId, const FString& Error)
{
	if (bWasSuccessful)
	{
		FindReconnectableGames();
	}
	else
	{
		UE_LOG(LogTemp, Warning, TEXT("Login Error: %s"), *Error);
	}
	bIsAttemptingLogin = false;

	IOnlineSubsystem* Subsystem = Online::GetSubsystem(GetWorld());
	if (!Subsystem) return;
	IOnlineIdentityPtr Identity = Subsystem->GetIdentityInterface();
	if (!Identity) return;
	Identity->ClearOnLoginCompleteDelegates(LocalUserNum, this);

}

void UEpicOnlineSubsystem::FindReconnectableGames(bool bResetNextReconnectSlot)
{
	if (bResetNextReconnectSlot)
		NextReconnectSlot = 0;

	// If we've searched through all slots, stop searching and reset counter.
	if (NextReconnectSlot >= MAX_RECONNECT_SLOTS)
	{
		NextReconnectSlot = 0;
		return;
	}

	FindReconnectableGame(NextReconnectSlot);

}

void UEpicOnlineSubsystem::ReconnectIfAble()
{
	if (!ReconnectSessionSearch.IsValid()
		|| ReconnectSessionSearch->SearchResults.Num() == 0
		|| JoinSessionHandle.IsValid())
	{
		return;
	}
	IOnlineSubsystem* Subsystem = Online::GetSubsystem(GetWorld());
	if (!Subsystem) return;
	IOnlineSessionPtr Session = Subsystem->GetSessionInterface();
	if (!Session) return;

	JoinSessionHandle = Session->OnJoinSessionCompleteDelegates.AddUObject(this, &UEpicOnlineSubsystem::OnJoinSessionCompleted);
	Session->JoinSession(0, SESSION_NAME, ReconnectSessionSearch->SearchResults[0]);
}

void UEpicOnlineSubsystem::FindReconnectableGame(int ReconnectSlotIndex)
{
	IOnlineSubsystem* Subsystem = Online::GetSubsystem(GetWorld());
	if (!Subsystem) return;
	IOnlineSessionPtr Session = Subsystem->GetSessionInterface();
	if (!Session) return;

	OnReconnectSessionSearchUpdate.Broadcast(false);
	auto PC = UGameplayStatics::GetPlayerController(this, 0);
	auto NetID = GetUniqueNetIdOf(PC);
	if (!NetID.IsValid())
	{
		UE_LOG(LogTemp, Warning, TEXT("Could not search for reconnectable games, NetID is invalid."));
		return;
	}

	ReconnectSessionSearch = MakeShareable(new FOnlineSessionSearch());
	ReconnectSessionSearch->MaxSearchResults = 1;
	ReconnectSessionSearch->QuerySettings.SearchParams.Empty();

	ReconnectSessionSearch->QuerySettings.Set(GetReconnectKeyName(ReconnectSlotIndex), NetID->ToString(), EOnlineComparisonOp::Equals);

	FindReconnectSessionsHandle = Session->OnFindSessionsCompleteDelegates.AddUObject(this, &UEpicOnlineSubsystem::OnFindReconnectableGamesCompleted);
	Session->FindSessions(0, ReconnectSessionSearch.ToSharedRef());
}

void UEpicOnlineSubsystem::OnFindReconnectableGamesCompleted(bool bWasSuccessful)
{
	IOnlineSubsystem* Subsystem = Online::GetSubsystem(GetWorld());
	if (!Subsystem) return;
	IOnlineSessionPtr Session = Subsystem->GetSessionInterface();
	if (!Session) return;

	Session->ClearOnFindSessionsCompleteDelegates(this);
	FindReconnectSessionsHandle.Reset();

	if (bWasSuccessful)
	{
		UE_LOG(LogTemp, Warning, TEXT("Succeeded in searching for reconnect sessions with slot %d"), NextReconnectSlot);
		bool bFoundSession = !ReconnectSessionSearch->SearchResults.IsEmpty();
		OnReconnectSessionSearchUpdate.Broadcast(bFoundSession);
		if (!bFoundSession)
		{
			NextReconnectSlot++;
			FindReconnectableGames(false);
		}
	}
	else
	{
		OnReconnectSessionSearchUpdate.Broadcast(false);
		UE_LOG(LogTemp, Warning, TEXT("Failed in searching for reconnect sessions with slot %d"), NextReconnectSlot);
	}
}

void UEpicOnlineSubsystem::AddPlayerToReconnectableList(APlayerController* Player)
{
	auto NetID = GetUniqueNetIdOf(Player);
	DisconnectedPlayers.AddUnique(NetID->ToString());
	UpdateReconnectablePlayerList();
}

void UEpicOnlineSubsystem::RemovePlayerFromReconnectableList(APlayerController* Player)
{
	auto NetID = GetUniqueNetIdOf(Player);
	DisconnectedPlayers.Remove(NetID->ToString());
	UpdateReconnectablePlayerList();
}

void UEpicOnlineSubsystem::UpdateReconnectablePlayerList()
{
	IOnlineSubsystem* Subsystem = Online::GetSubsystem(GetWorld());
	if (!Subsystem) return;
	IOnlineSessionPtr Session = Subsystem->GetSessionInterface();
	if (!Session) return;

	FOnlineSessionSettings Settings = *Session->GetSessionSettings(SESSION_NAME);

	for (int i = 0; i < MAX_RECONNECT_SLOTS; i++)
	{
		if (i < DisconnectedPlayers.Num())
			Settings.Set(GetReconnectKeyName(i), DisconnectedPlayers[i], EOnlineDataAdvertisementType::ViaOnlineService);
		else
			Settings.Set(GetReconnectKeyName(i), FString("EMPTY"), EOnlineDataAdvertisementType::ViaOnlineService);
	}
	Session->UpdateSession(SESSION_NAME, Settings);
}

FName UEpicOnlineSubsystem::GetReconnectKeyName(int index)
{
	FString Str = FString("DisconnectID") + FString::FromInt(index);
	FName Name = FName(Str);
	return Name;
}

void UEpicOnlineSubsystem::HostSession(const int32& NumberOfPublicConnections, const FString& SessionTitle, const FString& LevelURL)
{
	IOnlineSubsystem* Subsystem = Online::GetSubsystem(GetWorld());
	if (!Subsystem) return;
	IOnlineSessionPtr Session = Subsystem->GetSessionInterface();
	if (!Session) return;

	if (HostSessionHandle.IsValid())
	{
		UE_LOG(LogTemp, Warning, TEXT("There is already a hosting attempt in progress."));
		return;
	}

	FOnlineSessionSettings SessionSettings;
	SessionSettings.NumPublicConnections = NumberOfPublicConnections;
	SessionSettings.bAllowInvites = true;
	SessionSettings.bShouldAdvertise = true;
	SessionSettings.bAllowJoinInProgress = true;
	SessionSettings.bAllowJoinViaPresence = true;
	SessionSettings.bAllowInvites = true;
	SessionSettings.bUsesPresence = true;
	SessionSettings.Set(SESSION_TITLE, SessionTitle, EOnlineDataAdvertisementType::ViaOnlineService);

	CachedLevelURL = LevelURL;
	HostSessionHandle = Session->OnCreateSessionCompleteDelegates.AddUObject(this, &UEpicOnlineSubsystem::OnHostSessionCompleted);
	Session->CreateSession(0, SESSION_NAME, SessionSettings);
}

void UEpicOnlineSubsystem::DestroySession()
{
	IOnlineSubsystem* Subsystem = Online::GetSubsystem(GetWorld());
	if (!Subsystem) return;
	IOnlineSessionPtr Session = Subsystem->GetSessionInterface();
	if (!Session) return;

	Session->OnDestroySessionCompleteDelegates.AddUObject(this, &UEpicOnlineSubsystem::OnDestroySessionCompleted);
	Session->DestroySession(SESSION_NAME);
}

void UEpicOnlineSubsystem::FindSessions(int MaxSearchResults)
{
	if (FindSessionsHandle.IsValid()) return;

	IOnlineSubsystem* Subsystem = Online::GetSubsystem(GetWorld());
	if (!Subsystem) return;
	IOnlineSessionPtr Session = Subsystem->GetSessionInterface();
	if (!Session) return;

	SessionSearchResults.Sessions.Empty();
	OnSessionSearchUpdate.Broadcast();

	SessionSearch = MakeShareable(new FOnlineSessionSearch());
	SessionSearch->MaxSearchResults = MaxSearchResults;
	SessionSearch->QuerySettings.SearchParams.Empty();

	FindSessionsHandle = Session->OnFindSessionsCompleteDelegates.AddUObject(this, &UEpicOnlineSubsystem::OnFindSessionCompleted);
	Session->FindSessions(0, SessionSearch.ToSharedRef());
}

void UEpicOnlineSubsystem::JoinSession(int Index)
{
	if (Index < 0 || JoinSessionHandle.IsValid()) return;
	IOnlineSubsystem* Subsystem = Online::GetSubsystem(GetWorld());
	if (!Subsystem) return;
	IOnlineSessionPtr Session = Subsystem->GetSessionInterface();
	if (!Session) return;
	SessionSearchResults.Sessions.Empty();
	OnSessionSearchUpdate.Broadcast();
	if (SessionSearch->SearchResults.Num() > Index)
	{
		JoinSessionHandle = Session->OnJoinSessionCompleteDelegates.AddUObject(this, &UEpicOnlineSubsystem::OnJoinSessionCompleted);
		Session->JoinSession(0, SESSION_NAME, SessionSearch->SearchResults[Index]);
	}
}

bool UEpicOnlineSubsystem::IsInOrJoiningSession()
{
	IOnlineSubsystem* Subsystem = Online::GetSubsystem(GetWorld());
	if (!Subsystem) return false;
	IOnlineSessionPtr Session = Subsystem->GetSessionInterface();
	if (!Session) return false;

	EOnlineSessionState::Type type = Session->GetSessionState(SESSION_NAME);
	return type != EOnlineSessionState::Type::NoSession;
}

void UEpicOnlineSubsystem::RegisterPlayer(APlayerController* NewPlayer)
{
	if (!IsValid(NewPlayer))
	{
		UE_LOG(LogTemp, Warning, TEXT("Newly joined player has invalid PlayerController reference"));
		return;
	}

	FUniqueNetIdRepl UniqueNetIdRepl = GetUniqueNetIdOf(NewPlayer);

	TSharedPtr<const FUniqueNetId> UniqueNetId = UniqueNetIdRepl.GetUniqueNetId();
	if (UniqueNetId == nullptr)
	{
		UE_LOG(LogTemp, Warning, TEXT("Newly joined player has invalid Unique Net ID."));
		return;
	}

	IOnlineSubsystem* Subsystem = Online::GetSubsystem(GetWorld());
	if (!Subsystem) return;
	IOnlineSessionPtr Session = Subsystem->GetSessionInterface();
	if (!Session) return;

	if (Session->RegisterPlayer(SESSION_NAME, *UniqueNetId, false))
	{
		UE_LOG(LogTemp, Warning, TEXT("Successfully registered new player"));
	}
	else
	{
		UE_LOG(LogTemp, Warning, TEXT("Failed to register new player"));
	}

}

void UEpicOnlineSubsystem::UnregisterPlayer(APlayerController* LeavingPlayer)
{
	if (!IsValid(LeavingPlayer))
	{
		UE_LOG(LogTemp, Warning, TEXT("Leaving player has invalid controller."));
		return;
	}

	FUniqueNetIdRepl UniqueNetIdRepl = GetUniqueNetIdOf(LeavingPlayer);

	TSharedPtr<const FUniqueNetId> UniqueNetId = UniqueNetIdRepl.GetUniqueNetId();
	if (UniqueNetId == nullptr)
	{
		UE_LOG(LogTemp, Warning, TEXT("Leaving player has invalid NetID."));
		return;
	}

	IOnlineSubsystem* Subsystem = Online::GetSubsystem(GetWorld());
	if (!Subsystem) return;
	IOnlineSessionPtr Session = Subsystem->GetSessionInterface();
	if (!Session) return;

	if (Session->UnregisterPlayer(SESSION_NAME, *UniqueNetId))
	{
		UE_LOG(LogTemp, Warning, TEXT("Successfully unregistered leaving player"));
	}
	else
	{
		UE_LOG(LogTemp, Warning, TEXT("Leaving player could not be unregistered"));
	}

	RemovePlayerFromReconnectableList(LeavingPlayer);
}

void UEpicOnlineSubsystem::OnHostSessionCompleted(FName SessionName, bool bWasSuccessful)
{
	if (bWasSuccessful && !CachedLevelURL.IsEmpty())
	{
		GetWorld()->ServerTravel(CachedLevelURL, true);
	}
	CachedLevelURL.Empty();
	HostSessionHandle.Reset();

	IOnlineSubsystem* Subsystem = Online::GetSubsystem(GetWorld());
	if (!Subsystem) return;
	IOnlineSessionPtr Session = Subsystem->GetSessionInterface();
	if (!Session) return;
	Session->ClearOnCreateSessionCompleteDelegates(this);
	
	auto PC = GetGameInstance()->GetFirstLocalPlayerController();
	RegisterPlayer(PC);
}

void UEpicOnlineSubsystem::OnDestroySessionCompleted(FName SessionName, bool bWasSuccessful)
{
	IOnlineSubsystem* Subsystem = Online::GetSubsystem(GetWorld());
	if (!Subsystem) return;
	IOnlineSessionPtr Session = Subsystem->GetSessionInterface();
	if (!Session) return;
	Session->ClearOnDestroySessionCompleteDelegates(this);
}

void UEpicOnlineSubsystem::OnFindSessionCompleted(bool bWasSuccessful)
{
	IOnlineSubsystem* Subsystem = Online::GetSubsystem(GetWorld());
	if (!Subsystem) return;
	IOnlineSessionPtr Session = Subsystem->GetSessionInterface();
	if (!Session) return;

	Session->ClearOnFindSessionsCompleteDelegates(this);
	FindSessionsHandle.Reset();

	if (!bWasSuccessful)
	{
		UE_LOG(LogTemp, Warning, TEXT("Failed to find sessions"));
		return;
	}


	SessionSearchResults.Sessions.Empty();
	for (int i = 0; i < SessionSearch->SearchResults.Num(); i++)
	{
		FSessionDetails Details;

		FString GetName;
		SessionSearch->SearchResults[i].Session.SessionSettings.Get<FString>(SESSION_TITLE, GetName);
		Details.SessionName = GetName;

		Details.MaxConnections = SessionSearch->SearchResults[i].Session.SessionSettings.NumPublicConnections + SessionSearch->SearchResults[i].Session.SessionSettings.NumPrivateConnections;
		Details.OpenConnections = SessionSearch->SearchResults[i].Session.NumOpenPublicConnections + SessionSearch->SearchResults[i].Session.NumOpenPrivateConnections;
		SessionSearchResults.Sessions.Add(Details);
	}
	OnSessionSearchUpdate.Broadcast();
	
}

void UEpicOnlineSubsystem::OnJoinSessionCompleted(FName SessionName, EOnJoinSessionCompleteResult::Type Result)
{
	if (Result == EOnJoinSessionCompleteResult::Success)
	{
		if (APlayerController* PlayerController = UGameplayStatics::GetPlayerController(GetWorld(), 0))
		{
			IOnlineSubsystem* Subsystem = Online::GetSubsystem(GetWorld());
			if (!Subsystem) return;
			IOnlineSessionPtr Session = Subsystem->GetSessionInterface();
			if (!Session) return;
			Session->ClearOnJoinSessionCompleteDelegates(this);
			JoinSessionHandle.Reset();

			FString JoinAddress;
			Session->GetResolvedConnectString(SessionName, JoinAddress);
			if (!JoinAddress.IsEmpty())
			{
				PlayerController->ClientTravel(JoinAddress, ETravelType::TRAVEL_Absolute);
			}
		}
		return;
	}
	if (Result == EOnJoinSessionCompleteResult::SessionIsFull)
	{
		UE_LOG(LogTemp, Warning, TEXT("Session is full."));
	}
	else
	{
		UE_LOG(LogTemp, Warning, TEXT("Couldn't join session, unknown reason."));
	}

	//If we fail to join a session, we automatically search for new ones.
	FindSessions();
}

void UEpicOnlineSubsystem::OnSessionUserInviteAccepted(const bool bWasSuccessful, const int32 ControllerId, FUniqueNetIdPtr UserId, const FOnlineSessionSearchResult& InviteResult)
{
	if (!bWasSuccessful)
	{
		UE_LOG(LogTemp, Warning, TEXT("Accept attempt failed."));
		return;
	}
	if (IsInOrJoiningSession())
	{
		UE_LOG(LogTemp, Warning, TEXT("Already in or joining session, can't accept invite."));
		return;
	}

	IOnlineSubsystem* Subsystem = Online::GetSubsystem(GetWorld());
	if (!Subsystem) return;
	IOnlineSessionPtr Session = Subsystem->GetSessionInterface();
	if (!Session) return;

	JoinSessionHandle = Session->OnJoinSessionCompleteDelegates.AddUObject(this, &UEpicOnlineSubsystem::OnJoinSessionCompleted);
	Session->JoinSession(0, SESSION_NAME, InviteResult);
}

void UEpicOnlineSubsystem::PlayerDisconnected(APlayerController* Player)
{
	ALobbyGameMode* Mode = GetWorld()->GetAuthGameMode<ALobbyGameMode>();

	//We don't want to unregister a player if the game mode allows for reconnection during play
	if ((Mode && Mode->bPlayersCanReconnectDuringMatch))// && IsSessionInProgress())
	{
		IOnlineSubsystem* Subsystem = Online::GetSubsystem(GetWorld());
		if (!Subsystem) return;
		IOnlineSessionPtr Session = Subsystem->GetSessionInterface();
		if (!Session) return;

		if (IsPlayerInSession(Player))
		{
			AddPlayerToReconnectableList(Player);
		}
	}
	else
	{
		UnregisterPlayer(Player);
	}
}

PlayerConnectedResult UEpicOnlineSubsystem::PlayerConnected(APlayerController* Player)
{
	IOnlineSubsystem* Subsystem = Online::GetSubsystem(GetWorld());
	if (!Subsystem) return PlayerConnectedResult::Error;
	IOnlineSessionPtr Session = Subsystem->GetSessionInterface();
	if (!Session) return PlayerConnectedResult::Error;


	FUniqueNetIdRepl ID = GetUniqueNetIdOf(Player);
	RemovePlayerFromReconnectableList(Player);
	if (Session->IsPlayerInSession(SESSION_NAME, *ID.GetUniqueNetId()))
	{
		return PlayerConnectedResult::AlreadyConnected;
	}
	else
	{
		RegisterPlayer(Player);
		return PlayerConnectedResult::Success;
	}
}

bool UEpicOnlineSubsystem::IsPlayerInSession(APlayerController* Player)
{
	IOnlineSubsystem* Subsystem = Online::GetSubsystem(GetWorld());
	if (!Subsystem) return false;
	IOnlineSessionPtr Session = Subsystem->GetSessionInterface();
	if (!Session) return false;

	FUniqueNetIdRepl UniqueNetIdRepl = GetUniqueNetIdOf(Player);

	return Session->IsPlayerInSession(SESSION_NAME, *UniqueNetIdRepl.GetUniqueNetId());
}

bool UEpicOnlineSubsystem::IsSessionInProgress()
{
	IOnlineSubsystem* Subsystem = Online::GetSubsystem(GetWorld());
	if (!Subsystem) return false;
	IOnlineSessionPtr Session = Subsystem->GetSessionInterface();
	if (!Session) return false;

	EOnlineSessionState::Type State = Session->GetSessionState(SESSION_NAME);

	return State == EOnlineSessionState::Type::InProgress;
}

void UEpicOnlineSubsystem::ShowFriendsOverlay()
{
	IOnlineSubsystem* Subsystem = Online::GetSubsystem(GetWorld());
	if (!Subsystem) return;
	IOnlineExternalUIPtr ExternalUI = Subsystem->GetExternalUIInterface();
	if (!ExternalUI.IsValid()) return;

	ExternalUI->ShowFriendsUI(0);
}

FUniqueNetIdRepl UEpicOnlineSubsystem::GetUniqueNetIdOf(APlayerController* Player)
{
	FUniqueNetIdRepl UniqueNetIdRepl;
	if (Player->IsLocalPlayerController())
	{
		ULocalPlayer* LocalPlayer = Player->GetLocalPlayer();
		if (IsValid(LocalPlayer))
		{
			UniqueNetIdRepl = LocalPlayer->GetPreferredUniqueNetId();
		}
		else
		{
			UNetConnection* RemoteNetConnection = Cast<UNetConnection>(Player->Player);
			if (!IsValid(RemoteNetConnection))
			{
				UE_LOG(LogTemp, Warning, TEXT("Leaving player has neither valid local player nor remote"));
				return FUniqueNetIdRepl();
			}
			UniqueNetIdRepl = RemoteNetConnection->PlayerId;
		}
	}
	else
	{
		UNetConnection* RemoteNetConnection = Cast<UNetConnection>(Player->Player);
		if (!IsValid(RemoteNetConnection))
		{
			UE_LOG(LogTemp, Warning, TEXT("Leaving player has no valid remote connection."));
		}
		UniqueNetIdRepl = RemoteNetConnection->PlayerId;
	}
	return UniqueNetIdRepl;
}