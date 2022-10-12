#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <cstrike>
#include <hamsandwich>
#include <orpheu>
#include <orpheu_stocks>
#include <json>
#include <oo>

#include <ctg_const>
#include <ctg_util>

#define MAX_PREVIOUS_GAMEMODES 10 // max previous gamemode objects to store

new g_pGameRules;
new g_GameThinkEntity;
new g_fwEntSpawn;
new Trie:g_Objectives;
new Float:g_RoundStartTime;
new Float:g_RoundTime;
new Float:g_RespawnTime[MAX_PLAYERS + 1];
new bool:g_IsKilled[MAX_PLAYERS + 1];

new GameMode:g_objCurrGameMode = @null;
new Array:g_aPrevGameModes = Invalid_Array;
new g_NextGameMode[STRLEN_SHORT];
new g_DefaultGameMode[STRLEN_SHORT];

new Float:CvarRespawnTime;
new CvarRoundTime;

public oo_init()
{
	// Game Mode Class
	oo_class("GameMode");
	{
		new const cl[] = "GameMode";

		oo_var(cl, "is_started", 1); // bool:
		oo_var(cl, "is_ended", 1); // bool:
		oo_var(cl, "is_deathmatch", 1); // bool:

		oo_ctor(cl, "Ctor");
		oo_dtor(cl, "Dtor");

		oo_mthd(cl, "Start");
		oo_mthd(cl, "End");
		oo_mthd(cl, "WinConditions"); // bool:()
		oo_mthd(cl, "RoundTimeExpired");
		oo_mthd(cl, "Think", @cell); // (ent)

		oo_mthd(cl, "GetCurrentMode"); // GameMode:()
		oo_mthd(cl, "GetPreviousMode", @cell); // GameMode:(step)
		oo_mthd(cl, "GetNextMode", @stringex, @cell) // bool:(output[], len)
		oo_mthd(cl, "SetNextMode", @string); // bool:(const classname[])
		oo_mthd(cl, "ClearPreviousModes");
		oo_mthd(cl, "SetPlayerRespawnTime", @cell, @float); // (player_id, Float:respawn_time)
		oo_mthd(cl, "CanPlayerRespawn", @cell); // (player_id)
		oo_mthd(cl, "RespawnPlayer", @cell); // (player_id)
		oo_mthd(cl, "GetRoundStartTime");
		
		oo_mthd(cl, "OnNewRound");
		oo_mthd(cl, "OnRoundStart");
		oo_mthd(cl, "OnJoinTeam", @cell, @cell); // (player_id, team)
		oo_mthd(cl, "OnPlayerSpawn", @cell); // (player_id)
		oo_mthd(cl, "OnPlayerKilled", @cell, @cell, @cell); // (player_id, attacker, shouldgib)
	}
}

public plugin_precache()
{
	OrpheuRegisterHook(OrpheuGetFunction("InstallGameRules"), "OnInstallGameRules", OrpheuHookPost);

	g_Objectives = TrieCreate();

	LoadJson();

	if (TrieGetSize(g_Objectives) > 0)
		g_fwEntSpawn = register_forward(FM_Spawn, "OnEntSpawn");
}

public OnInstallGameRules()
{
	g_pGameRules = OrpheuGetReturn();
}

public OnEntSpawn(ent)
{
	if (!pev_valid(ent))
		return FMRES_IGNORED;
	
	static class[STRLEN_SHORT];
	entity_get_string(ent, EV_SZ_classname, class, charsmax(class));

	if (TrieKeyExists(g_Objectives, class))
	{
		remove_entity(ent);
		return FMRES_SUPERCEDE;
	}

	return FMRES_IGNORED;
}

public plugin_init()
{
	register_plugin("[CTG] Game Mode", CTG_VERSION, "holla");

	if (g_fwEntSpawn)
		unregister_forward(FM_Spawn, g_fwEntSpawn);

	register_event("HLTV", "OnEventNewRound", "a", "1=0", "2=0");
	register_event("TextMsg", "OnEventCommenceRestart", "a", "2=#Game_Commencing", "2=#Game_will_restart_in");
	register_logevent("OnEventRoundStart", 2, "1=Round_Start");
	register_logevent("OnEventRoundEnd", 2, "1=Round_End");
	register_logevent("OnEventJoinTeam", 3, "1=joined team");

	register_think("gamemode", "OnGameThink");

	RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn_Post", 1);
	RegisterHam(Ham_Killed, "player", "OnPlayerKilled_Post", 1);

	OrpheuRegisterHookFromObject(g_pGameRules, "CheckWinConditions", "CGameRules", "OnCheckWinConditions");

	g_aPrevGameModes = ArrayCreate(1);

	new pcvar = create_cvar("ctg_gamemode_respawn_time", "5.0");
	bind_pcvar_float(pcvar, CvarRespawnTime);

	CvarRoundTime = get_cvar_pointer("mp_roundtime");
}

public plugin_cfg()
{
	OnEventNewRound();
}

public plugin_natives()
{
	register_library("ctg_gamemode");

	register_native("ctg_gamemode_get_current", "native_gamemode_get_current");
	register_native("ctg_gamemode_set_next", "native_gamemode_set_next");
	register_native("ctg_gamemode_set_default", "native_gamemode_set_default");
	register_native("ctg_gamemode_is", "native_gamemode_is");
}

public GameMode:native_gamemode_get_current(plugin_id, num_params)
{
	return g_objCurrGameMode;
}

public bool:native_gamemode_set_next(plugin_id, num_params)
{
	static classname[STRLEN_SHORT];
	get_string(1, classname, charsmax(classname));

	return SetNextGameMode(classname);
}

public native_gamemode_set_default(plugin_id, num_params)
{
	static classname[STRLEN_SHORT];
	get_string(1, classname, charsmax(classname));

	copy(g_DefaultGameMode, charsmax(g_DefaultGameMode), classname);
}

public bool:native_gamemode_is(plugin_id, num_params)
{
	if (g_objCurrGameMode == @null)
		return false;
	
	static classname[STRLEN_SHORT];
	get_string(1, classname, charsmax(classname));

	return oo_isa(g_objCurrGameMode, classname, bool:get_param(2));
}

public OnEventNewRound()
{
	RemoveGameThinkEntity();

	if (g_NextGameMode[0])
	{
		ChangeGameMode(g_NextGameMode);
	}
	else if (g_objCurrGameMode != @null)
	{
		static classname[STRLEN_SHORT];
		oo_get_classname(g_objCurrGameMode, classname, charsmax(classname));
		ChangeGameMode(classname);
	}
	else
	{
		ChangeGameMode(g_DefaultGameMode);
	}

	if (g_objCurrGameMode != @null)
		oo_call(g_objCurrGameMode, "OnNewRound");

	g_RoundTime = get_pcvar_float(CvarRoundTime) * 60.0;
}

public OnEventRoundStart()
{
	g_RoundStartTime = get_gametime();

	if (g_objCurrGameMode != @null)
		oo_call(g_objCurrGameMode, "OnRoundStart");
}

public OnEventJoinTeam()
{
	static loguser[STRLEN_LONG], name[STRLEN_SHORT];
	read_logargv(0, loguser, charsmax(loguser));
	parse_loguser(loguser, name, charsmax(name));

	new id = get_user_index(name);
	if (!is_user_connected(id))
		return;
	
	static teamchar[2];
	read_logargv(2, teamchar, charsmax(teamchar));

	new team = 0;

	switch (teamchar[0])
	{
		case 'T': team = 1;
		case 'C': team = 2;
		case 'S': team = 3;
	}

	server_print("haha %s haha", teamchar[0]);

	if (team)
	{
		if (g_objCurrGameMode != @null)
		{
			oo_call(g_objCurrGameMode, "OnJoinTeam", id, team);
		}
	}
}

public OnEventCommenceRestart()
{
	ClearPreviousGameModes();
	RemoveGameThinkEntity();
	oo_delete(g_objCurrGameMode);
	g_objCurrGameMode = @null;
}

public OnEventRoundEnd()
{
	RemoveGameThinkEntity();
}

public OnGameThink(ent)
{
	if (!is_valid_ent(ent))
		return;
	
	if (g_objCurrGameMode != @null)
		oo_call(g_objCurrGameMode, "Think", ent);
}

public OnPlayerSpawn_Post(id)
{
	if (!is_user_alive(id))
		return;

	g_IsKilled[id] = false;
	
	if (g_objCurrGameMode != @null)
		oo_call(g_objCurrGameMode, "OnPlayerSpawn", id);
}

public OnPlayerKilled_Post(id, attacker, shouldgib)
{
	g_IsKilled[id] = true;

	if (g_objCurrGameMode != @null)
		oo_call(g_objCurrGameMode, "OnPlayerKilled", id, attacker, shouldgib);
}

public client_disconnected(id)
{
	g_IsKilled[id] = false;
	g_RespawnTime[id] = 0.0;
}

public OrpheuHookReturn:OnCheckWinConditions()
{
	if (g_objCurrGameMode != @null)
		oo_call(g_objCurrGameMode, "WinConditions");

	return OrpheuSupercede;
}

public GameMode@Ctor()
{
	new this = oo_this();
	oo_set(this, "is_started", false);
	oo_set(this, "is_ended", false);
	oo_set(this, "is_deathmatch", false);
}

public GameMode@Dtor() {}

public GameMode@OnNewRound() {}
public GameMode@OnJoinTeam() {}

public GameMode@OnRoundStart()
{
	new ent = CreateGameThinkEntity();
	entity_set_float(ent, EV_FL_nextthink, get_gametime());
}

public GameMode@OnPlayerSpawn(id) {}

public GameMode@OnPlayerKilled(id)
{
	if (oo_call(@this, "CanPlayerRespawn", id))
	{
		g_RespawnTime[id] = get_gametime() + CvarRespawnTime;
	}
}

public GameMode@Start()
{
	new this = oo_this();
	oo_set(this, "is_started", true);
	oo_set(this, "is_ended", false);
}

public GameMode@End()
{
	new this = oo_this();
	oo_set(this, "is_ended", true);
}

public GameMode@Think(ent)
{
	new this = oo_this();
	new Float:curr_time = get_gametime();

	// gamemode is started
	if (oo_get(this, "is_started"))
	{
		// gamemode is ended?
		if (oo_get(this, "is_ended"))
		{
			RemoveGameThinkEntity();
			return;
		}

		// deathmatch?
		if (oo_get(this, "is_deathmatch"))
		{
			// check respawn time for all players
			for (new i = 1; i <= MaxClients; i++)
			{
				// time to respawn
				if (g_IsKilled[i] && curr_time >= g_RespawnTime[i])
				{
					// can respawn?
					if (oo_call(this, "CanPlayerRespawn", i))
					{
						// respawn player
						oo_call(this, "RespawnPlayer", i);
					}
				}
			}
		}

		// check if round time is expired
		if (curr_time >= g_RoundStartTime + g_RoundTime)
		{
			oo_call(this, "RoundTimeExpired");
		}
	}

	entity_set_float(ent, EV_FL_nextthink, curr_time + 0.1);
}

public GameMode@WinConditions()
{
	InitializePlayerCounts();
}

public GameMode@RoundTimeExpired()
{
}

public GameMode:GameMode@GetCurrentMode()
{
	return g_objCurrGameMode;
}

public GameMode:GameMode@GetPreviousMode(step)
{
	new size = ArraySize(g_aPrevGameModes);
	new index = (step >= size) ? size-1 : step;

	return GameMode:ArrayGetCell(g_aPrevGameModes, index);
}

public bool:GameMode@GetNextMode(output[], len)
{
	if (g_NextGameMode[0] == '^0')
		return false;

	copy(output, len, g_NextGameMode);
	return true;
}

public bool:GameMode@SetNextMode(const classname[])
{
	return SetNextGameMode(classname);
}

public GameMode@ClearPreviousModes()
{
	ClearPreviousGameModes();
}

public GameMode@SetPlayerRespawnTime(id, Float:respawn_time)
{
	g_RespawnTime[id] = respawn_time;
}

public bool:GameMode@CanPlayerRespawn(id)
{
	// player is already alive
	if (is_user_alive(id))
		return false;
	
	// player is not spawnable
	if (!IsPlayerSpawnable(id))
		return false;

	new this = oo_this();
	// gamemode is not started OR ended OR not deathmatch
	if (!oo_get(this, "is_started") || oo_get(this, "is_ended") || !oo_get(this, "is_deathmatch"))
		return false;

	// pass
	return true;
}

public GameMode@RespawnPlayer(id)
{
	ExecuteHamB(Ham_CS_RoundRespawn, id);
}

public Float:GameMode@GetRoundStartTime()
{
	return g_RoundStartTime;
}

bool:SetNextGameMode(const classname[])
{
	if (!oo_subclass_of(classname, "GameMode"))
		return false;
	
	copy(g_NextGameMode, charsmax(g_NextGameMode), classname);
	return true;
}

GameMode:ChangeGameMode(const classname[])
{
	if (!oo_subclass_of(classname, "GameMode"))
		return @null;

	if (g_objCurrGameMode != @null)
	{
		new size = ArraySize(g_aPrevGameModes);
		if (size >= MAX_PREVIOUS_GAMEMODES)
		{
			new index = size-1; // last element
			new GameMode:obj = any:ArrayGetCell(g_aPrevGameModes, index);
			oo_delete(obj); // delete object
			ArrayDeleteItem(g_aPrevGameModes, index);
		}

		if (size < 1) // empty array
			ArrayPushCell(g_aPrevGameModes, g_objCurrGameMode); // push
		else
			ArrayInsertCellBefore(g_aPrevGameModes, 0, g_objCurrGameMode); // insert before the first element

		g_objCurrGameMode = @null;
	}

	g_objCurrGameMode = oo_new(classname); // new object
	g_NextGameMode[0] = '^0';

	return g_objCurrGameMode;
}

CreateGameThinkEntity()
{
	RemoveGameThinkEntity();

	g_GameThinkEntity = create_entity("info_target");
	if (is_valid_ent(g_GameThinkEntity))
		entity_set_string(g_GameThinkEntity, EV_SZ_classname, "gamemode");

	return g_GameThinkEntity;
}

RemoveGameThinkEntity()
{
	if (is_valid_ent(g_GameThinkEntity))
	{
		entity_set_int(g_GameThinkEntity, EV_INT_flags, entity_get_int(g_GameThinkEntity, EV_INT_flags) | FL_KILLME);
		entity_set_float(g_GameThinkEntity, EV_FL_nextthink, get_gametime());
		g_GameThinkEntity = FM_NULLENT;
	}
}

ClearPreviousGameModes()
{
	while (ArraySize(g_aPrevGameModes) > 0)
	{
		oo_delete(ArrayGetCell(g_aPrevGameModes, 0));
		ArrayDeleteItem(g_aPrevGameModes, 0);
	}
}

InitializePlayerCounts(&numTrs=0, &numCts=0, &numSpawnableTrs=0, &numSpawnableCts=0)
{
	numTrs = 0;
	numCts = 0;
	numSpawnableTrs = 0;
	numSpawnableCts = 0;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!is_user_connected(i))
			continue;
		
		switch (cs_get_user_team(i))
		{
			case CS_TEAM_T:
			{
				numTrs++;

				if (get_ent_data(i, @CBPLR, "m_iMenu") != _:CS_Menu_ChooseAppearance)
					numSpawnableTrs++;
			}
			case CS_TEAM_CT:
			{
				numCts++;

				if (get_ent_data(i, @CBPLR, "m_iMenu") != _:CS_Menu_ChooseAppearance)
					numSpawnableCts++;
			}
		}
	}

	set_gamerules_int(@CHLMP, "m_iNumSpawnableTerrorist", numSpawnableTrs);
	set_gamerules_int(@CHLMP, "m_iNumSpawnableCT", numSpawnableCts);
	set_gamerules_int(@CHLMP, "m_iNumTerrorist", numTrs);
	set_gamerules_int(@CHLMP, "m_iNumCT", numCts);
}

LoadJson()
{
	static filepath[STRLEN_LONG];
	get_configsdir(filepath, charsmax(filepath));
	formatex(filepath, charsmax(filepath), "%s/contagion/gamemode.json", filepath);

	new JSON:json = json_parse(filepath, true, true);
	if (json == Invalid_JSON) // invalid json file
		return;

	new JSON:objectives_j = json_object_get_value(json, "objectives");
	if (objectives_j != Invalid_JSON)
	{
		static value[STRLEN_SHORT];
		for (new i = json_array_get_count(objectives_j) - 1; i >= 0; i--)
		{
			json_array_get_string(objectives_j, i, value, charsmax(value));
			TrieSetCell(g_Objectives, value, 1);
		}
		json_free(objectives_j);
	}

	json_free(json);
	server_print("Loaded json (%s)", filepath);
}