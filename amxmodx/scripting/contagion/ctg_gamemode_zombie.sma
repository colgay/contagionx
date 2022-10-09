#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <orpheu>
#include <oo>

#include <ctg_const>
#include <ctg_playerclass>
#include <ctg_gamemode>
#include <ctg_util>

new Float:CvarStartTime;

public oo_init()
{
	// Game Mode Class
	oo_class("ZombieMode", "GameMode");
	{
		new const cl[] = "ZombieMode";
		oo_ctor(cl, "Ctor");
		oo_dtor(cl, "Dtor");

		oo_mthd(cl, "Start");
		oo_mthd(cl, "End");

		oo_mthd(cl, "WinConditions");
		oo_mthd(cl, "RoundTimeExpired");
		oo_mthd(cl, "RespawnPlayer", @cell);
		oo_mthd(cl, "Think", @cell);

		oo_mthd(cl, "OnNewRound");
		oo_mthd(cl, "OnRoundStart");
		oo_mthd(cl, "OnJoinTeam", @cell, @cell);
	}
}

public plugin_init()
{
	register_plugin("[CTG] Game Mode: Infection", CTG_VERSION, "holla");

	ctg_gamemode_set_default("ZombieMode");

	new pcvar = create_cvar("ctg_gamemode_start_time", "20.0");
	bind_pcvar_float(pcvar, CvarStartTime);
}

public ZombieMode@Ctor()
{
	oo_super_ctor("GameMode");
}

public ZombieMode@Dtor() {}

public ZombieMode@Think(ent)
{
	new this = @this;
	oo_call(this, "GameMode@Think", ent); // call super

	if (!oo_get(this, "is_started")) // gamemode not started yet
	{
		static countdown;
		new Float:curr_time = get_gametime();
		new Float:roundstart_time = Float:oo_call(this, "GetRoundStartTime");

		// is this the first think?
		if (curr_time < roundstart_time + 0.2) // is 0.2 safe enough?
		{
			countdown = clamp(floatround(CvarStartTime), 0, 10);
			set_pev(ent, pev_nextthink, curr_time + floatmax(CvarStartTime - 10.0, 0.2));
			return;
		}

		// not ready to start yet
		if (curr_time < roundstart_time + CvarStartTime)
		{
			client_print(0, print_center, "First infection in %d seconds", countdown);

			static word[STRLEN_SHORTER];
			num_to_word(countdown, word, charsmax(word));
			client_cmd(0, "spk ^"fvox/%s^"", word);

			countdown--;
			set_pev(ent, pev_nextthink, curr_time + 1.0);
			return;
		}

		oo_call(this, "Start"); // start the gamemode
	}
}

public ZombieMode@Start()
{
	new this = @this;
	oo_call(this, "GameMode@Start"); // call super class method

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
		ctg_playerclass_change(player, "Zombie", true); // turn player into to zombie
		set_pev(player, pev_health, pev(player, pev_health) * 5.0); // hp x 5
		client_print(0, print_center, "%n is the first zombie!", player); // print message
	}

	oo_set(this, "is_deathmatch", true);
}

public ZombieMode@End()
{
	oo_call(@this, "GameMode@End"); // call super class method
}

public ZombieMode@WinConditions()
{
	new this = @this;
	if (!oo_get(this, "is_started") || oo_get(this, "is_ended"))
		return;

	new human_count = 0;
	new zombie_count = 0;
	new spawnable_count = 0;

	for (new i = 1; i <= MaxClients; i++) // loop through all players
	{
		if (!is_user_connected(i)) // filter not connected
			continue;
		
		if (IsPlayerSpawnable(i))
		{
			if (is_user_alive(i))
			{
				if (ctg_playerclass_is(i, "Human", true))
					human_count++;
				else if (ctg_playerclass_is(i, "Zombie", true))
					zombie_count++;
			}
		}

		spawnable_count++;
	}

	if (spawnable_count > 1 && human_count < 1) // all humans are dead
	{
		TerminateRound(10.0, WINSTATUS_TERRORISTS, ROUND_TERRORISTS_WIN, "Zombies Win", "terwin");
		oo_call(@this, "End");
		return;
	}

	if (spawnable_count > 1 && zombie_count < 1 && human_count < 1) // all players are dead
	{
		TerminateRound(5.0, WINSTATUS_DRAW, ROUND_END_DRAW, "Round Draw", "rounddraw");
		oo_call(@this, "End");
		return;
	}
}

public ZombieMode@RoundTimeExpired()	
{
	new human_count = 0;
	new zombie_count = 0;
	new spawnable_count = 0;
	for (new i = 1; i <= MaxClients; i++) // loop through all players
	{
		if (!is_user_connected(i)) // filter not connected
			continue;
		
		if (IsPlayerSpawnable(i))
		{
			if (is_user_alive(i))
			{
				if (ctg_playerclass_is(i, "Human", true))
					human_count++;
				else if (ctg_playerclass_is(i, "Zombie", true))
					zombie_count++;
			}
		}

		spawnable_count++;
	}

	if (human_count > 0 && zombie_count > 0 && spawnable_count > 0)
	{
		TerminateRound(10.0, WINSTATUS_CTS, ROUND_CTS_WIN, "Humans Win", "ctwin");
		oo_call(@this, "End");
		return;
	}

	TerminateRound(5.0, WINSTATUS_DRAW, ROUND_END_DRAW, "Round Draw", "rounddraw");
	oo_call(@this, "End");
}

public ZombieMode@RespawnPlayer(id)
{
	ctg_playerclass_change(id, "Zombie", false);
	oo_call(@this, "GameMode@RespawnPlayer", id); // call super method
}

public ZombieMode@OnNewRound()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!is_user_connected(i))
			continue;

		
		ctg_playerclass_change(i, "Human", false);
	}
}

public ZombieMode@OnJoinTeam(id, CsTeams:team)
{
	if (CS_TEAM_T <= team <= CS_TEAM_CT)
	{
		ctg_playerclass_change(id, "Human", false);
	}
	else if (team == CS_TEAM_SPECTATOR)
	{
		ctg_playerclass_change(id, "", false); // delete
	}
}