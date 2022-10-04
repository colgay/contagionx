#include <amxmodx>
#include <amxmisc>
#include <ctg_const>
#include <ctg_gamemode_const>

new Array:g_GameModes;
new g_GameModeCount;

new Trie:g_GameModeUniqueId;

new g_CurrentGameMode = CTG_NULL;
new g_LastGameMode = CTG_NULL;

new g_fwGameModeStart[Forward_e];
new g_fwGameModeEnd;
new g_fwRet;

public plugin_init()
{
	register_plugin("[CTG] Game Mode", CTG_VERSION, "colg");

	register_logevent("LogEvent_RoundEnd", 2, "1=Round_End");
	register_event("TextMsg", "Event_GameRestart", "a", "2=#Game_will_restart_in");
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0");

	g_fwGameModeStart[FwPre] = CreateMultiForward("ctg_OnGameModeStart", ET_CONTINUE, FP_CELL);
	g_fwGameModeStart[FwPost] = CreateMultiForward("ctg_OnGameModeStart_P", ET_IGNORE, FP_CELL);

	g_fwGameModeEnd = CreateMultiForward("ctg_OnGameModeEnd", ET_IGNORE, FP_CELL);
}

public plugin_natives()
{
	register_library("ctg_gamemode");

	register_native("ctg_CreateGameMode", "native_CreateGameMode");
	register_native("ctg_StartGameMode", "native_StartGameMode");
	register_native("ctg_FindGameMode", "native_FindGameMode");
	register_native("ctg_GetGameModeData", "native_GetGameModeData");

	register_native("ctg_GetCurrentGameMode", "native_GetCurrentGameMode");
	register_native("ctg_GetLastGameMode", "native_GetLastGameMode");

	register_native("ctg_GetRandomPlayer", "native_GetRandomPlayer");

	g_GameModes = ArrayCreate(GameMode_e);
	g_GameModeUniqueId = TrieCreate();
}

public native_CreateGameMode()
{
	new name[32], unique_id[32];
	get_string(1, name, charsmax(name));
	get_string(2, unique_id, charsmax(unique_id));

	new flags = get_param(3);

	return CreateGameMode(name, unique_id, flags);
}

public native_StartGameMode()
{
	new index = get_param(1);

	new unique_id[32];
	get_string(2, unique_id, charsmax(unique_id));

	if (index == CTG_NULL && unique_id[0])
		index = FindGameMode(unique_id);

	StartGameMode(index);
}

public native_FindGameMode()
{
	new name[32];
	get_string(1, name, charsmax(name));

	return FindGameMode(name);
}

public native_GetGameModeData()
{
	new index = get_param(1);

	static data[GameMode_e];
	GetGameModeData(index, data);

	set_array(2, data, GameMode_e);
}

public native_GetCurrentGameMode()
{
	return g_CurrentGameMode;
}

public native_GetLastGameMode()
{
	return g_LastGameMode;
}

// ctg_GetRandomPlayer(const callback[], const flags[]);
public native_GetRandomPlayer(plugin_id)
{
	new callback[32];
	get_string(1, callback, charsmax(callback));

	new GetPlayersFlags:flags = GetPlayersFlags:get_param(2);
	new fwd_id = CreateOneForward(plugin_id, callback, FP_CELL);

	new players[32], num;
	get_players_ex(players, num, flags);

	new player_id, ret, i;

	while (num > 0)
	{
		i = random(num);
		player_id = players[i];
		ExecuteForward(fwd_id, ret, player_id);

		if (ret == 1) // is you
			return player_id;
		
		// erase player from the list
		players[i] = players[--num];
	}

	DestroyForward(fwd_id);

	return 0; // no player was selected
}

public Event_NewRound()
{
	g_CurrentGameMode = CTG_NULL;
}

public Event_GameRestart()
{
	LogEvent_RoundEnd();
}

public LogEvent_RoundEnd()
{
	ExecuteForward(g_fwGameModeEnd, g_fwRet, g_CurrentGameMode);

	g_CurrentGameMode = CTG_NULL;
}

StartGameMode(gamemode_id)
{
	ExecuteForward(g_fwGameModeStart[FwPre], g_fwRet, gamemode_id);

	g_CurrentGameMode = gamemode_id;
	g_LastGameMode = gamemode_id;

	ExecuteForward(g_fwGameModeStart[FwPost], g_fwRet, gamemode_id);
}

CreateGameMode(const name[], const unique_id[], flags)
{
	static data[GameMode_e];
	copy(data[GM_Name], charsmax(data[GM_Name]), name);
	copy(data[GM_UniqueId], charsmax(data[GM_UniqueId]), unique_id);
	data[GM_Flags] = flags;

	ArrayPushArray(g_GameModes, data);
	TrieSetCell(g_GameModeUniqueId, unique_id, g_GameModeCount);
	g_GameModeCount++;

	return g_GameModeCount - 1;
}

GetGameModeData(index, data[GameMode_e])
{
	return ArrayGetArray(g_GameModes, index, data);
}

FindGameMode(const name[])
{
	new index;
	if (TrieGetCell(g_GameModeUniqueId, name, index))
		return index;

	return CTG_NULL;
}