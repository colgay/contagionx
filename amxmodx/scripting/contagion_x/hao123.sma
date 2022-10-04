#include <amxmodx>
#include <fun>
#include <hamsandwich>
#include <engine>
#include <fakemeta>
#include <cstrike>

new const g_RemoveEntities[][] =
{
	"func_bomb_target",
	"info_bomb_target",
	"hostage_entity",
	"monster_scientist",
	"func_hostage_rescue",
	"info_hostage_rescue",
	"info_vip_start",
	"func_vip_safetyzone",
	"func_escapezone",
	"func_buyzone"
};

new g_fwEntSpawn;

public OnEntSpawn(ent)
{
	if (!pev_valid(ent))
		return FMRES_IGNORED;

	new classname[32];
	pev(ent, pev_classname, classname, charsmax(classname));

	for (new i = 0; i < sizeof g_RemoveEntities; i++)
	{
		if (equal(classname, g_RemoveEntities[i]))
		{
			remove_entity(ent);
			return FMRES_SUPERCEDE;
		}
	}

	return FMRES_IGNORED;
}

public plugin_precache()
{
	g_fwEntSpawn = register_forward(FM_Spawn, "OnEntSpawn");
}

public plugin_init()
{
	RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn");
	RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn_Post", 1);
	RegisterHam(Ham_Touch, "weaponbox", "OnWeaponTouch");
	register_event("Money", "OnEventMoney", "g");
	unregister_forward(FM_Spawn, g_fwEntSpawn);
}

public OnEventMoney(msgid, msgdest, id)
{
	set_ent_data(id, "CBasePlayer", "m_iAccount", 0); // money
}

public OnPlayerSpawn(id)
{
	if (pev_valid(id) && is_user_bot(id) && get_ent_data(id, "CBasePlayer", "m_iTeam") == 2)
	{
		set_ent_data(id, "CBasePlayer", "m_iTeam", 1)
	}
}

public OnPlayerSpawn_Post(id)
{
	if (is_user_alive(id))
	{
		if (is_user_bot(id))
		{
			cs_set_user_money(id, 0);
			RequestFrame("StripWeapons", id);
		}
		else
		{
			cs_set_user_money(id, 16000);
		}

		set_user_health(id, 9999);
	}
}

public OnWeaponTouch(ent, id)
{
	return (is_user_bot(id)) ? HAM_SUPERCEDE : HAM_IGNORED;
}

public StripWeapons(id)
{
	strip_user_weapons(id);
	give_item(id, "weapon_knife");
}