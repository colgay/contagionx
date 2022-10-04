#include <amxmodx>
#include <ctg_core>

new g_Human;
new g_IsHuman[MAX_PLAYERS + 1];

public plugin_precache()
{
    g_Human = ctg_CreatePlayerClass(_, "Human", "human", "", Team_Human);
}

public plugin_init()
{
	register_plugin("[CTG] Human", CTG_VERSION, "colg");

	ctg_CreatePlayerClassCvars(g_Human, "human", 100, 1.0, 1.0, 1.0);
}

public plugin_natives()
{
	register_library("ctg_human");

	register_native("ctg_Human", "native_Human");
	register_native("ctg_IsHuman", "native_IsHuman");
}

public native_Human()
{
	return g_Human;
}

public native_IsHuman()
{
	new id = get_param(1);

	return g_IsHuman[id];
}

public ctg_OnChangePlayerClass_P(id, class_id)
{
	if (ctg_GetPlayerTeam(id) == Team_Human)
	{
		g_IsHuman[id] = true;
	}
	else
	{
		g_IsHuman[id] = false;
	}
}