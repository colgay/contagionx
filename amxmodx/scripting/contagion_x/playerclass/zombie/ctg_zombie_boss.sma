#include <amxmodx>
#include <ctg_core>

new CBoss;
new bool:g_IsBoss[MAX_PLAYERS + 1];

public plugin_precache()
{
	CBoss = ctg_CreatePlayerClass(ctg_Zombie(), "Boss", "boss", "", Team_Zombie);
}

public plugin_init()
{
	register_plugin("[CTG] Zombie: Boss", CTG_VERSION, "colg");
}

public plugin_natives()
{
	register_library("ctg_boss");

	register_native("ctg_Boss", "native_Boss");
	register_native("ctg_IsBoss", "native_IsBoss");
}

public native_Boss()
{
	return CBoss;
}

public native_IsBoss()
{
	new id = get_param(1);
	return g_IsBoss[id];
}

public ctg_OnChangePlayerClass_P(id, class_id)
{
	if (ctg_HasPlayerClassParent(class_id, CBoss))
	{
		g_IsBoss[id] = true;
	}
	else
	{
		g_IsBoss[id] = false;
	}
}

public client_disconnected(id)
{
	g_IsBoss[id] = false;
}