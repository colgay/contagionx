#include <amxmodx>
#include <hamsandwich>
#include <oo>
#include <ctg_const>
#include <ctg_util>

new Obj:g_oPlayerHandler;

public plugin_init()
{
    register_plugin("[CTG] Game Rules", CTG_VERSION);

    RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn", 0, true);
    RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn_Post", 1, true);
}

public OnPlayerSpawn(id)
{
    if (!pev_valid(id) || !(1 <= get_ent_data(id, "CBasePlayer", "m_iTeam") <= 2))
        return;

	static team; team = !team;
	set_ent_data(id, "CBasePlayer", "m_iTeam", team + 1); // fix spawn points
	set_ent_data(id, "CBasePlayer", "m_bNotKilled", true);

	new weapon_bits = pev(id, pev_weapons);
	if (~weapon_bits & WEAPON_SUIT_BIT)
		set_pev(id, pev_weapons, weapon_bits | WEAPON_SUIT_BIT);
}

public OnPlayerSpawn_Post(id)
{
    if (!is_user_alive(id) || !(1 <= get_ent_data(id, "CBasePlayer", "m_iTeam") <= 2))
        return;

    new Obj:o_player = oo_call(g_oPlayerHandler, "GetPlayer");
    if (o_player != @null)
    {
        oo_call(o_player, "ChangePlayerClass", oo_call(o_player, "GetTeam") == Team_Zombie ? "Zombie" : "Human");
    }
}