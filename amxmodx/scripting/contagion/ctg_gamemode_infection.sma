#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <orpheu>
#include <oo>

#include <ctg_const>
#include <ctg_playerclass>
#include <ctg_gamemode>
#include <ctg_util>

public oo_init()
{
	// Game Mode Class
	oo_class("InfectionMode", "GameMode");
	{
		new const cl[] = "InfectionMode";
		oo_ctor(cl, "Ctor");
		oo_dtor(cl, "Dtor");

		oo_mthd(cl, "Start");
		oo_mthd(cl, "End");

		oo_mthd(cl, "WinConditions");

		oo_mthd(cl, "OnNewRound");
		oo_mthd(cl, "OnJoinTeam", @cell, @cell);
	}
}

public plugin_precache()
{
	ctg_gamemode_set_next("InfectionMode");
}

public plugin_init()
{
	register_plugin("[CTG] Game Mode: Infection", CTG_VERSION, "holla");
}

public InfectionMode@Ctor()
{
	oo_super_ctor("GameMode");
}

public InfectionMode@Dtor() {}

public InfectionMode@Start()
{
	oo_call(@this, "GameMode@Start"); // call super class method

	new players[32], num = 0;
	for (new i = 1; i <= MaxClients; i++) // loop through all players
	{
		if (!is_user_connected(i) || !is_user_alive(i)) // filter not connected and dead
			continue;

		if (ctg_playerclass_is(i, "Zombie", true)) // if player is already a zombie (bug prevent)
			ctg_playerclass_change(i, "Human"); // turn back into human

		players[num++] = i; // add to list
	}

	if (num > 0) // number of players
	{
		new i = random(num); // random choose a player from the list
		new player = players[i]; // get the actual player index
		ctg_playerclass_change(player, "Zombie"); // turn player into to zombie
		client_print(0, print_center, "%n is the first zombie!", player); // print message
	}
}

public InfectionMode@End()
{
	oo_call(@this, "GameMode@End"); // call super class method
}

public InfectionMode@WinConditions()
{
	new human_count = 0;
	new spawnable_count = 0;
	for (new i = 1; i <= MaxClients; i++) // loop through all players
	{
		if (!is_user_connected(i)) // filter not connected
			continue;
		
		if (!(CS_TEAM_T <= cs_get_user_team(i) <= CS_TEAM_CT)
			|| get_ent_data(i, @CBPLR, "m_iMenu") == _:CS_Menu_ChooseAppearance) // filter not spawnable
			continue;

		if (is_user_alive(i) && ctg_playerclass_is(i, "Human", true)) // is alive human?
			human_count++; // count + 1
		
		spawnable_count++;
	}

	if (spawnable_count > 1 && human_count < 1) // all humans are dead
	{
		TerminateRound(10.0, WINSTATUS_TERRORISTS, ROUND_TERRORISTS_WIN, "Zombies Win", "terwin");
		oo_call(@this, "End");
		return;
	}
}

public InfectionMode@OnNewRound()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!is_user_connected(i))
			continue;

		ctg_playerclass_change(i, "Human", false);
	}
}

public InfectionMode@OnJoinTeam(id, CsTeams:team)
{
	if (CS_TEAM_T <= team <= CS_TEAM_CT)
	{
		ctg_playerclass_change(id, "Human", false);
	}
	else if (team == CS_TEAM_SPECTATOR)
	{
		ctg_playerclass_change(id, ""); // delete
	}
}