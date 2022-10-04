#include <amxmodx>
#include <cstrike>
#include <fun>
#include <hamsandwich>

new pcvar_renderamt;

public plugin_init()
{
	register_plugin("Asshole", "0.1", "peter");

	RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn", 1);

	pcvar_renderamt = register_cvar("tr_invisible_amt", "50");
}

public OnPlayerSpawn(id)
{
	if (is_user_alive(id))
	{
		if (cs_get_user_team(id) == CS_TEAM_T)
		{
			set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, get_pcvar_num(pcvar_renderamt));
		}
		else if (cs_get_user_team(id) == CS_TEAM_CT)
		{
			set_user_rendering(id);
		}
	}
}