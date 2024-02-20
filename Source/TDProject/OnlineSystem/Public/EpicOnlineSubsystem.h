// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Subsystems/GameInstanceSubsystem.h"
#include "OnlineSessionSettings.h"
#include "Interfaces/OnlineSessionInterface.h"
#include "EpicOnlineSubsystem.generated.h"


#define SESSION_NAME FName(TEXT("SessionName")) // Used to track multiple sessions.
#define SESSION_TITLE FName(TEXT("SessionTitle")) // The advertised session name

/** Determines how many player ID reconnect slots are published in the
* advertised Session. If more players than this are disconnected simultaneously, 
* not all will be able to reconnect. Set this value to something appropriate to
* your game.
*/ 
#define MAX_RECONNECT_SLOTS 5 

DECLARE_DYNAMIC_MULTICAST_DELEGATE(FOnSessionSearchUpdate);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FOnReconnectSessionSearchUpdate, bool, CanReconnect);

UENUM(BlueprintType)
enum class PlayerConnectedResult : uint8
{
	Error				UMETA(DisplayName = "Error"),
	Success				UMETA(DisplayName = "Success"),
	AlreadyConnected	UMETA(DisplayName = "Already Connected")
};

struct FUniqueNetIdRepl;

/** Can be expanded to contain information that you want to show in the
* Server List in the main menu. Any additions will need to be handled 
* through the SessionSettings, written by the server either on session creation
* or runtime; as well as read by the OnFindSessionCompleted function.
*/
USTRUCT(BlueprintType, Category = "Online Services")
struct FSessionDetails {
	GENERATED_BODY()

public:

	UPROPERTY(BlueprintReadOnly)
	FString SessionName = FString();

	UPROPERTY(BlueprintReadOnly)
	int OpenConnections = 0;

	UPROPERTY(BlueprintReadOnly)
	int MaxConnections = 0;

};

/** This is a list of all search results from the "Find Games" button.
* It contains everything that should be presented in the UI to determine
* Which game to join. The index of the selected game in this list is used
* to call the JoinSession(int index) function.
* For UI: subscribe to OnSessionSearchUpdate to know when to redraw UI, 
* find the actual list in SessionSearchResults.
*/
USTRUCT(BlueprintType, Category = "Online Services")
struct FSessionSearchResults {
	GENERATED_BODY()

public:
	UPROPERTY(BlueprintReadOnly)
	TArray<FSessionDetails> Sessions;
};


/**
 * 
 */
UCLASS()
class TDPROJECT_API UEpicOnlineSubsystem : public UGameInstanceSubsystem
{
	GENERATED_BODY()

public:
	virtual void Initialize(FSubsystemCollectionBase& Collection) override;
	virtual void Deinitialize() override;

#pragma region Logging_In

public:

	UFUNCTION(BlueprintCallable, Category = "Online Services")
	FString GetSelfUsername();

	// Opens the browser where user can log in with Epic account.
	UFUNCTION(BlueprintCallable, Category = "Online Services")
	void AttemptLoginWithAccountPortal();

	/* Tries to login using the EOS Dev Auth tool.Only for internal use.
	* @param Token - Developer Login Token as defined in the DevAuth tool
	*/
	UFUNCTION(BlueprintCallable, Category = "Online Services")
	void AttemptDeveloperLogin(const FString& Token, const int Port = 8081);

	/** Generic login function where LoginType is specified manually.
	* Use AttemptLoginWithAccountPortal or AttemptDeveloperLogin instead when applicable.
	* See https://docs.unrealengine.com/5.2/en-US/online-subsystem-eos-plugin-in-unreal-engine/
	* for LoginTypes
	*/
	UFUNCTION(BlueprintCallable, Category = "Online Services")
	void AttemptLogin(const FString& ID, const FString& Token, const FString& LoginType);

	UFUNCTION(BlueprintCallable, BlueprintPure, Category = "Online Services")
	bool IsWaitingForLoginAttempt() { return bIsAttemptingLogin; }

	UFUNCTION(BlueprintCallable, BlueprintPure, Category = "Online Services")
	bool IsPlayerLoggedIn();

private:

	// Async callback function used by AttemptLogin() 
	void OnLoginAttemptCompleted(int32 LocalUserNum, bool bWasSuccessful, const FUniqueNetId& UserId, const FString& Error);
	
	UPROPERTY()
	bool bIsAttemptingLogin = false;

#pragma endregion

#pragma region Reconnecting

public:

	/** Call this to begin a search for sessions which you were disconnected from
	* and can reconnect to. 
	* @param bResetNextReconnectSlot - You probably want this to be true (default).
	* It determines whether the search starts over from index 0 or continues 
	* where it was last.
	*/
	UFUNCTION(BlueprintCallable, Category = "Online Services")
	void FindReconnectableGames(bool bResetNextReconnectSlot = true);

	/* Event broadcasts when a reconnectable session search finishes.
	* @return bool: true if a session was found, false otherwise.
	*/
	UPROPERTY(BlueprintAssignable, Category = "Online Services")
	FOnReconnectSessionSearchUpdate OnReconnectSessionSearchUpdate;

	/** This requires FindReconnectableGames() to be called.
	* To know if a reconnectable game is found, subscribe to
	* OnReconnectSessionSearchUpdate
	*/
	UFUNCTION(BlueprintCallable, Category = "Online Services")
	void ReconnectIfAble();
	
private:

	// Helper function for FindReconnectableGames(). Do not call manually.
	UFUNCTION(Category = "Online Services")
	void FindReconnectableGame(int ReconnectSlotIndex);

	// A counter for FindReconnectableGames(). Do not interfere with this manually.
	UPROPERTY()
	int NextReconnectSlot = 0;

	// Async callback function used by FindReconnectableGames() 
	void OnFindReconnectableGamesCompleted(bool bWasSuccessful);
	FDelegateHandle FindReconnectSessionsHandle;

	// Cached search results from async search, handled in OnFindReconnectableGamesCompleted
	TSharedPtr<FOnlineSessionSearch> ReconnectSessionSearch;

	UFUNCTION()
	void AddPlayerToReconnectableList(APlayerController* Player);

	UFUNCTION()
	void RemovePlayerFromReconnectableList(APlayerController* Player);

	// A list of ToString() representations for disconnected players that should
	// be able to reconnect. Handled by UpdateReconnectablePlayerList().
	UPROPERTY()
	TArray<FString> DisconnectedPlayers;

	// Do not call this manually. Use AddPlayerToReconnectableList
	// and RemovePlayerFromReconnectableList.
	UFUNCTION()
	void UpdateReconnectablePlayerList();

	// Macro-style function which gives the name used as a key in the 
	// advertised Session for disconnected players that can reconnect.
	UFUNCTION()
	FName GetReconnectKeyName(int index);

#pragma endregion

#pragma region Session Host, Search, Join

public:

	/** Starts a new session and publishes it to the Epic Online Services to be findable by other players.
	* @param NumberOfPublicConnections - Max number of players, including host.
	* @param SessionTitle - The publicly visible custom game name
	* @param LevelURL - The Unreal asset path for the level to load, including parameters
	*	for example, /Game/Levels/Lobby/Lobby?listen?port=7779
	*/
	UFUNCTION(BlueprintCallable, Category = "Online Services")
	void HostSession(const int32& NumberOfPublicConnections, const FString& SessionTitle, const FString& LevelURL);

	// Should be called whenever a server wants to stop a hosted session, or when a client disconnects
	// from a session.
	UFUNCTION(BlueprintCallable, Category = "Online Services")
	void DestroySession();
	
	/** Generic search for any hosted games.
	* @param MaxSearchResults - optional
	*/
	UFUNCTION(BlueprintCallable, Category = "Online Services")
	void FindSessions(int MaxSearchResults = 50);
	
	// List of search results given by FindSessions()
	UPROPERTY(BlueprintReadOnly, Category = "Online Services")
	FSessionSearchResults SessionSearchResults;

	// Event broadcasts whenever SessionSearchResults is updated, used for updating UI.
	UPROPERTY(BlueprintAssignable, Category = "Online Services")
	FOnSessionSearchUpdate OnSessionSearchUpdate;
	
	/** Joins a session found by FindSessions()
	* @param Index - The index in SessionSearchResults of the game you want to join.
	*/
	UFUNCTION(BlueprintCallable, Category = "Online Services")
	void JoinSession(int Index);

	// True if user is in a session, or in the process of trying to joine one.
	UFUNCTION(BlueprintCallable, BlueprintPure, Category = "Online Services")
	bool IsInOrJoiningSession();

	/** Registers a player into the current session. (Serverside)
	* You should most likely not use this, instead call PlayerConnected(), 
	* which also handles for example reconnecting functionality.
	*/
	UFUNCTION(Category = "Online Services")
	void RegisterPlayer(APlayerController* NewPlayer);

	/** Unregisters a player from the current session. (Serverside)
	* You should most likely not use this, instead call PlayerDisconnected(),
	* which also handles for example reconnecting functionality.
	*/
	UFUNCTION(Category = "Online Services")
	void UnregisterPlayer(APlayerController* LeavingPlayer);

private:

	// Async callback for HostSession()
	void OnHostSessionCompleted(FName SessionName, bool bWasSuccessful);
	FDelegateHandle HostSessionHandle;

	// Stores the Level URL from HostSession() to be handled by async callback.
	UPROPERTY()
	FString CachedLevelURL;

	// Async callback for DestroySession()
	void OnDestroySessionCompleted(FName SessionName, bool bWasSuccessful);

	// Async callback for FindSession()
	void OnFindSessionCompleted(bool bWasSuccessful);
	FDelegateHandle FindSessionsHandle;

	// Cached search results from async search, handled in OnFindSessionCompleted
	TSharedPtr<FOnlineSessionSearch> SessionSearch;

	// Async callback for JoinSession()
	void OnJoinSessionCompleted(FName SessionName, EOnJoinSessionCompleteResult::Type Result);
	FDelegateHandle JoinSessionHandle;

	// Async callback for accepting invites via the social overlay
	void OnSessionUserInviteAccepted(const bool bWasSuccessful, const int32 ControllerId, FUniqueNetIdPtr UserId, const FOnlineSessionSearchResult& InviteResult);

#pragma endregion

#pragma region Session Management

public:

	// Call this from server to handle player disconnects.
	// Probably best to do serverside on the PlayerController's OnNetCleanup.
	UFUNCTION(BlueprintCallable, Category = "Online Services")
	void PlayerDisconnected(APlayerController* Player);

	// Call this from server to handle player connects.
	// Probably best to do serverside on the GameMode's PostLogin.
	UFUNCTION(BlueprintCallable, Category = "Online Services")
	PlayerConnectedResult PlayerConnected(APlayerController* Player);

	// Uses the PlayerController's unique net ID to see if it is registered in the current session.
	UFUNCTION(BlueprintCallable, Category = "Online Services")
	bool IsPlayerInSession(APlayerController* Player);

	UFUNCTION(BlueprintPure, Category = "Online Services")
	bool IsSessionInProgress();

#pragma endregion

public:
	
	UFUNCTION(BlueprintCallable, Category = "Online Services")
	void ShowFriendsOverlay();

private:

	// Helper function to get UniqueNetId from both Local and Remote PlayerControllers.
	UFUNCTION(Category = "Online Services")
	FUniqueNetIdRepl GetUniqueNetIdOf(APlayerController* Player);

	UFUNCTION(BlueprintCallable, Category = "Online Services")
	void ServerTravel(const FString& LevelURL);
	
	
};
