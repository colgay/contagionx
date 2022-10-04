#include <amxmodx>
#include <ctg_gamemode>
#include <ctg_util>

new g_GameModeId;

public plugin_init()
{
	register_plugin("[CTG] Game Mode: Infection", CTG_VERSION, "colg");

	g_GameModeId = ctg_CreateGameMode("Infection", "infection", 0);
}

public ctg_OnGameModeStart_P(gamemode_id)
{
	if (gamemode_id == g_GameModeId)
	{
		new zombie_num = floatround(CountPlayers(true) * 0.25, floatround_ceil); // count alive players
		new player;

		// make some zombies
		for (new i = 0; i < zombie_num; i++)
		{
			player = ctg_GetRandomPlayer("GetRandomZombieFilter", GetPlayers_ExcludeDead); // get random player with filter
			if (!player)
				break;
			
			ctg_ChangePlayerClass(player, ctg_Zombie()); // change to zombie
		}

		set_dhudmessage(255, 0, 0, -1.0, 0.25, 1, 1.0, 3.0, 0.1, 1.0);
		show_dhudmessage(0, "Infection Mode");
	}
}

public GetRandomZombieFilter(id)
{
	if (ctg_GetPlayerTeam(id) == Team_Zombie) // dont choose him, if he already is a zombie
		return false;
	
	return true;
}