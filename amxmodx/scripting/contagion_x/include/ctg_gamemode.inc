#if defined _ctg_gamemode_included
	#endinput
#endif
#define _ctg_gamemode_included

#include <ctg_const>
#include <ctg_gamemode_const>

native ctg_CreateGameMode(const name[], const unique_id[], flags);

native ctg_StartGameMode(index=CTG_NULL, const unique_id[]="");

native ctg_FindGameMode(const unique_id[]);

native ctg_GetGameModeData(index, data[GameMode_e]);

native ctg_GetRandomPlayer(const callback[], GetPlayersFlags:flags=GetPlayers_None);

native ctg_GetCurrentGameMode();
native ctg_GetLastGameMode();

forward ctg_OnGameModeStart(gamemode);
forward ctg_OnGameModeStart_P(gamemode);

forward ctg_OnGameModeEnd(gamemode);