#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <ctg_const>
#include <orpheu>
#include <orpheu_stocks>
#include <oo>

#include <ctg_util>

#define TASK_START 0

new Float:CvarStartDelay;

new g_pGameRules;
new GameMode:g_objGameMode = @null;

new g_fwStartGameMode[ForwardType];
new g_fwRet;

public plugin_precache()
{
	OrpheuRegisterHook(OrpheuGetFunction("InstallGameRules"), "OnInstallGameRules", OrpheuHookPost);
}

public plugin_init()
{
	register_plugin("[CTG] Game Rules", "0.2", "holla");

	register_event("HLTV", "OnEventNewRound", "a", "1=0", "2=0");
	register_event("TextMsg", "OnEventCommenceRestart", "a", "2=#Game_Commencing", "2=#Game_will_restart_in");

	register_logevent("OnEventRoundStart", 2, "1=Round_Start");
	register_logevent("OnEventRoundEnd", 2, "1=Round_End");

	register_forward(FM_PlayerPreThink, "OnPlayerPreThink");

	OrpheuRegisterHookFromObject(g_pGameRules, "CheckWinConditions", "CGameRules", "OnCheckWinConditions");
	OrpheuRegisterHookFromObject(g_pGameRules, "FPlayerCanRespawn", "CGameRules", "OnPlayerCanRespawn");

	g_fwStartGameMode[FW_PRE] = CreateMultiForward("ctg_on_gamemode_start", ET_CONTINUE);
	g_fwStartGameMode[FW_POST] = CreateMultiForward("ctg_on_gamemode_start_post", ET_IGNORE);

	new pcvar = create_cvar("ctg_gamestart_delay", "20");
	bind_pcvar_float(pcvar, CvarStartDelay);

	set_task(5.0, "haha", _, _, _, "b");

	g_objGameMode = oo_new("GameMode");
}

public haha()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (is_user_connected(i) && !is_user_bot(i))
		{
			engclient_cmd(i, "MP3Volume", "1.0");
			query_client_cvar(i, "MP3Volume", "GetMP3Volume");
		}
	}
}

public GetMP3Volume(id, const cvar[], const value[])
{
	server_print("%n: %s=%s", id, cvar, value);
}

public OnInstallGameRules()
{
	g_pGameRules = OrpheuGetReturn();
}

public OnEventNewRound()
{
}

public OnEventRoundStart()
{
}

public OnEventRoundEnd()
{
	remove_task(TASK_START);
	oo_call(g_objGameMode, "End");
}

public OnEventCommenceRestart()
{
	remove_task(TASK_START);
}

public OrpheuHookReturn:OnCheckWinConditions()
{
	// if a winner has already been determined.. then get the heck out of here
	if (get_gamerules_int(@CHLMP, "m_iRoundWinStatus") != WINSTATUS_NONE)
	{
		InitializePlayerCounts();
		return OrpheuSupercede;
	}

	InitializePlayerCounts();

	// check game mode win conditions
	if (oo_object_exists(g_objGameMode))
		oo_call(g_objGameMode, "CheckWinConditions");

	return OrpheuSupercede; // block original conditions
}

public OrpheuHookReturn:OnPlayerCanRespawn(gr, id)
{
	server_print("OnPlayerCanRespawn");
	return OrpheuSupercede; // block respawn check
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