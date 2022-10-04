#include <amxmodx>
#include <cstrike>
#include <ctg_const>
#include <orpheu>
#include <orpheu_stocks>
#include <hamsandwich>
#include <oo>

native Object:ctg_GetPlayerObject(id);

new g_pGameRules;
new Object:g_oGameRules;

public plugin_precache()
{
	OrpheuRegisterHook(OrpheuGetFunction("InstallGameRules"), "OnInstallGameRules", OrpheuHookPost);
}

public OnInstallGameRules()
{
	g_pGameRules = OrpheuGetReturn();
}

public oo_init()
{
	new Class:gr = oo_class("GameRules");
	{
		oo_method(gr, MT_CTOR, "Ctor");

		oo_method(gr, MT_METHOD, "ChangePlayerClass", FP_CELL);
		oo_method(gr, MT_METHOD, "CheckWinConditions");
	}
}

public plugin_init()
{
	register_plugin("[CTG] Game Rules", CTG_VERSION, "colg");

	RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn_Post", 1);

	OrpheuRegisterHookFromObject(g_pGameRules, "CheckWinConditions", "CGameRules", "OnCheckWinConditions");

	g_oGameRules = oo_new("GameRules");
}

public OnPlayerSpawn_Post(id)
{
	if (is_user_alive(id))
	{
		new Object:oPlayer = ctg_GetPlayerObject(id);
		new Object:oClass = Object:oo_get(oPlayer, "m_oClass"); // get class object
		if (oClass != @null)
		{
			new Class:cClass = oo_get_object_class(oClass); // get class id

			new classname[64];
			oo_get_class_name(cClass, classname, charsmax(classname)); // get class name

			oo_call(oPlayer, "ChangeClass", classname);
		}
	}
}

public OnCheckWinConditions()
{
	//oo_call(g_oGameRules, "CheckWinConditions");
	return OrpheuSupercede;
}

public GameRules@ChangePlayerClass(Object:oPlayer)
{
	new id = oo_get(oPlayer, "m_Index");
	new PlayerTeam:team = oo_get(oPlayer, "m_Team");

	switch (team)
	{
		case Team_Human:
			cs_set_user_team(id, CS_TEAM_CT, CS_NORESET);
		case Team_Zombie:
			cs_set_user_team(id, CS_TEAM_T, CS_NORESET);
	}
}

public GameRules@CheckWinConditions()
{

}