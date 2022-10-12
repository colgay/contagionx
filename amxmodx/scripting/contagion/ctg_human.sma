#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <oo>

#include <ctg_const>
#include <ctg_playerclass>
#include <ctg_util>

new PlayerClassInfo:g_objClassInfo;

public oo_init()
{
	oo_class("Human", "PlayerClass")
	{
		new const cl[] = "Human";
		oo_ctor(cl, "Ctor", @cell); // (player_index);
		oo_dtor(cl, "Dtor");

		oo_mthd(cl, "SetPropsAfter", @cell);
		oo_mthd(cl, "GetClassInfo");
		oo_mthd(cl, "CanPickupItem");
		oo_mthd(cl, "CanDropItem");
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

	RegisterHam(Ham_CS_Item_CanDrop, "player", "OnItemCanDrop");
}

public OnItemCanDrop(ent)
{
	if (!pev_valid(ent))
		return HAM_IGNORED;
	
	new player = get_ent_data_entity(ent, "CBasePlayerItem", "m_pPlayer");
	if (!is_user_connected(player))
		return HAM_IGNORED;

	new PlayerClass:obj = ctg_playerclass_get(ent);
	if (obj != @null && oo_isa(obj, "Human", true))
	{
		SetHamReturnInteger(oo_call(obj, "CanDropItem") ? 1 : 0);
		return HAM_OVERRIDE;
	}

	return HAM_IGNORED;
}

public Human@Ctor(player_index)
{
	oo_super_ctor("PlayerClass", player_index);
}

public Human@Dtor() { }

public Human@SetPropsAfter(id)
{
	SetPlayerTeam(id, CS_TEAM_CT);
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

public bool:Human@CanDropItem()
{
	return true;
}