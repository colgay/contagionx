#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <cstrike>
#include <orpheu>
#include <orpheu_stocks>
#include <oo>

#include <ctg_const>
#include <ctg_util>

#define MAX_PREVIOUS_GAMEMODES 8 // max previous gamemode objects to store

new g_pGameRules;
new g_GameThinkEntity;

new GameMode:g_objCurrGameMode = @null;
new Array:g_aPrevGameModes = Invalid_Array;
new g_NextGameMode[STRLEN_SHORT] = "GameMode";

new Float:CvarStartDelay;

public oo_init()
{
	// Game Mode Class
	oo_class("GameMode");
	{
		new const cl[] = "GameMode";

		oo_var(cl, "is_started", 1); // bool:
		oo_var(cl, "is_ended", 1); // bool:

		oo_ctor(cl, "Ctor");
		oo_dtor(cl, "Dtor");

		oo_mthd(cl, "Start");
		oo_mthd(cl, "End"); 
		oo_mthd(cl, "WinConditions"); // bool:()
		oo_mthd(cl, "Think", @cell); // (ent)

		oo_mthd(cl, "GetCurrentMode"); // GameMode:()
		oo_mthd(cl, "GetPreviousMode", @cell); // GameMode:(step)
		oo_mthd(cl, "GetNextMode", @stringex, @cell) // bool:(output[], len)
		oo_mthd(cl, "SetNextMode", @string); // bool:(const classname[])
		oo_mthd(cl, "ClearPreviousModes");
		
		oo_mthd(cl, "OnNewRound");
		oo_mthd(cl, "OnRoundStart");
		oo_mthd(cl, "OnJoinTeam", @cell, @cell); // (player_id, team)
	}
}

public plugin_precache()
{
	OrpheuRegisterHook(OrpheuGetFunction("InstallGameRules"), "OnInstallGameRules", OrpheuHookPost);
}

public OnInstallGameRules()
{
	g_pGameRules = OrpheuGetReturn();
}

public plugin_init()
{
	register_plugin("[CTG] Game Mode", CTG_VERSION, "holla");

	register_event("HLTV", "OnEventNewRound", "a", "1=0", "2=0");
	register_event("TextMsg", "OnEventCommenceRestart", "a", "2=#Game_Commencing", "2=#Game_will_restart_in");
	register_logevent("OnEventRoundStart", 2, "1=Round_Start");
	register_logevent("OnEventRoundEnd", 2, "1=Round_End");
	register_logevent("OnEventJoinTeam", 3, "1=joined team");

	register_think("gamemode", "OnGameThink");

	OrpheuRegisterHookFromObject(g_pGameRules, "CheckWinConditions", "CGameRules", "OnCheckWinConditions");

	g_aPrevGameModes = ArrayCreate(1);

	new pcvar = create_cvar("ctg_gamemode_start_delay", "20");
	bind_pcvar_float(pcvar, CvarStartDelay);

	OnEventNewRound();
}

public plugin_natives()
{
	register_library("ctg_gamemode");

	register_native("ctg_gamemode_get_current", "native_gamemode_get_current");
	register_native("ctg_gamemode_set_next", "native_gamemode_set_next");
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

public OnEventNewRound()
{
	RemoveGameThinkEntity();

	if (g_NextGameMode[0])
		ChangeGameMode(g_NextGameMode);

	if (g_objCurrGameMode != @null)
		oo_call(g_objCurrGameMode, "OnNewRound");
}

public OnEventRoundStart()
{
	if (g_objCurrGameMode != @null)
		oo_call(g_objCurrGameMode, "OnRoundStart");
}

public OnEventJoinTeam()
{
	static loguser[80], name[32];
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

	if (team)
	{
		if (g_objCurrGameMode != @null)
			oo_call(g_objCurrGameMode, "OnJoinTeam", id, team);
	}
}

public OnEventCommenceRestart()
{
	RemoveGameThinkEntity();
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

public OrpheuHookReturn:OnCheckWinConditions()
{
	InitializePlayerCounts();

	if (g_objCurrGameMode != @null)
		oo_call(g_objCurrGameMode, "WinConditions");

	return OrpheuSupercede;
}

public GameMode@Ctor()
{
	new this = @this;
	oo_set(this, "is_started", false);
	oo_set(this, "is_ended", false);
}

public GameMode@Dtor() {}

public GameMode@OnNewRound() {}
public GameMode@OnJoinTeam() {}

public GameMode@OnRoundStart()
{
	server_print("GameMode@OnRoundStart()");
	CreateGameThinkEntity();
	SetGameNextThink(CvarStartDelay);
}

public GameMode@Start()
{
	new this = @this;
	oo_set(this, "is_started", true);
	oo_set(this, "is_ended", false);
}

public GameMode@End()
{
	new this = @this;
	oo_set(this, "is_ended", true);
}

public GameMode@Think(ent)
{
	new this = @this;
	new bool:is_started = bool:oo_get(this, "is_started");
	new bool:is_ended = bool:oo_get(this, "is_ended");

	if (!is_started)
	{
		oo_call(this, "Start");
	}
	else
	{
		if (is_ended)
		{
			RemoveGameThinkEntity();
			return;
		}
	}

	SetGameNextThink(0.1);
}

public GameMode@WinConditions()
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
	while (ArraySize(g_aPrevGameModes) > 0)
	{
		oo_delete(ArrayGetCell(g_aPrevGameModes, 0));
		ArrayDeleteItem(g_aPrevGameModes, 0);
	}
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
		remove_entity(g_GameThinkEntity);
}

SetGameNextThink(Float:time)
{
	entity_set_float(g_GameThinkEntity, EV_FL_nextthink, get_gametime() + time);
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