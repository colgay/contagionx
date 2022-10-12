#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <oo>

#include <ctg_const>
#include <ctg_util>

new PlayerClassInfo:g_objClassInfo;

public oo_init()
{
	oo_class("Zombie", "PlayerClass")
	{
		new const cl[] = "Zombie";
		oo_ctor(cl, "Ctor", @cell); // (player_index);
		oo_dtor(cl, "Dtor");

		oo_mthd(cl, "SetPropsAfter", @cell);
		oo_mthd(cl, "GetClassInfo");
		oo_mthd(cl, "CanPickupItem");
	}
}

public plugin_precache()
{
	g_objClassInfo = any:oo_new("PlayerClassInfo", "Zombie", "Infected");
	oo_call(g_objClassInfo, "LoadJson", "zombie");
}

public plugin_init()
{
	register_plugin("[CTG] Zombie", CTG_VERSION, "holla");

	oo_call(g_objClassInfo, "CreateCvar", "zombie", "hp", "1500", FCVAR_NONE);
	oo_call(g_objClassInfo, "CreateCvar", "zombie", "gravity", "0.5", FCVAR_NONE);
	oo_call(g_objClassInfo, "CreateCvar", "zombie", "speed", "0.95", FCVAR_NONE);
}

public Zombie@Ctor(player_index)
{
	oo_super_ctor("PlayerClass", player_index);
}

public Zombie@Dtor() {}

public Zombie@SetPropsAfter(id)
{
	DropPlayerWeapons(id);
	SetPlayerTeam(id, CS_TEAM_T);
}

public PlayerClassInfo:Zombie@GetClassInfo()
{
	return g_objClassInfo;
}

public bool:Zombie@CanPickupItem()
{
	return false;
}