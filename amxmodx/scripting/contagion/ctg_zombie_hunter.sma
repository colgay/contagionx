#include <amxmodx>
#include <oo>

#include <ctg_const>

new PlayerClassInfo:g_objClassInfo;

public oo_init()
{
	oo_class("Hunter", "Zombie")
	{
		new const cl[] = "Hunter";
		oo_ctor(cl, "Ctor", @cell); // (player_index);
		oo_dtor(cl, "Dtor");

		oo_mthd(cl, "GetClassInfo");
	}
}

public plugin_precache()
{
	g_objClassInfo = any:oo_new("PlayerClassInfo", "Hunter", "Leap");
	oo_call(g_objClassInfo, "LoadJson", "zombie");
	oo_call(g_objClassInfo, "LoadJson", "hunter");
}

public plugin_init()
{
	register_plugin("[CTG] Hunter", CTG_VERSION, "holla");

	oo_call(g_objClassInfo, "CreateCvar", "hunter", "hp", "1000", FCVAR_NONE);
	oo_call(g_objClassInfo, "CreateCvar", "hunter", "gravity", "0.75", FCVAR_NONE);
	oo_call(g_objClassInfo, "CreateCvar", "hunter", "speed", "1.25", FCVAR_NONE);
}

public Hunter@Ctor(player_index)
{
	oo_super_ctor("Zombie", player_index);
}

public Hunter@Dtor() { }

public PlayerClassInfo:Hunter@GetClassInfo()
{
	return g_objClassInfo;
}