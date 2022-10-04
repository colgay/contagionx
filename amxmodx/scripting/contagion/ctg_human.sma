#include <amxmodx>
#include <cstrike>
#include <oo>

#include <ctg_const>

new PlayerClassInfo:g_objClassInfo;

public oo_init()
{
	oo_class("Human", "PlayerClass")
	{
		new const cl[] = "Human";
		oo_ctor(cl, "Ctor", @cell); // (player_index);
		oo_dtor(cl, "Dtor");

		oo_mthd(cl, "AssignProps");
		oo_mthd(cl, "GetClassInfo");
		oo_mthd(cl, "CanPickupItem");
	}
}

public plugin_precache()
{
	g_objClassInfo = any:oo_new("PlayerClassInfo", "Human", "");
	oo_call(g_objClassInfo, "LoadJson", "human");
}

public plugin_init()
{
	register_plugin("[CTG] Human", CTG_VERSION, "holla");
}

public Human@Ctor(player_index)
{
	oo_super_ctor("PlayerClass", player_index);
}

public Human@Dtor() { }

public Human@AssignProps()
{
	new this = @this;
	new id = oo_get(this, "player_index");
	oo_call(@this, "PlayerClass@AssignProps");
	cs_set_user_team(id, CS_TEAM_CT, CS_NORESET, true);
}

public PlayerTeam:Human@GetTeam()
{
	return Team_Human;
}

public PlayerClassInfo:Human@GetClassInfo()
{
	return g_objClassInfo;
}

public bool:Human@CanPickupItem()
{
	return true;
}