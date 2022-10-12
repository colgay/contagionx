#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
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
		oo_var(cl, "allow_infect", 1);

		oo_ctor(cl, "Ctor");
		oo_dtor(cl, "Dtor");

		oo_mthd(cl, "Start");
		oo_mthd(cl, "End");

		oo_mthd(cl, "WinConditions");
		oo_mthd(cl, "RoundTimeExpired");
		oo_mthd(cl, "RespawnPlayer", @cell); // (player)
		oo_mthd(cl, "Think", @cell); // (entity)

		oo_mthd(cl, "InfectPlayer", @cell, @cell, @cell); // (victim, attacker, headshot)
		oo_mthd(cl, "CanPlayerInfect", @cell, @cell); // (victim, attacker)

		oo_mthd(cl, "OnNewRound");
		//oo_mthd(cl, "OnRoundStart");
		oo_mthd(cl, "OnJoinTeam", @cell, @cell); // (player, team)
		oo_mthd(cl, "OnTakeDamage", @cell, @cell, @cell, @float, @cell); // (id, inflictor, attacker, Float:damage, damagebits)
	}
}

public plugin_init()
{
	register_plugin("[CTG] Game Mode: Zombie", CTG_VERSION, "holla");

	RegisterHam(Ham_TakeDamage, "player", "OnPlayerTakeDamage");

	ctg_gamemode_set_default("ZombieMode");

	new pcvar = create_cvar("ctg_gamemode_start_time", "20.0");
	bind_pcvar_float(pcvar, CvarStartTime);
}

public OnPlayerTakeDamage(id, inflictor, attacker, Float:damage, damagebits)
{
	new GameMode:mode_obj = ctg_gamemode_get_current();
	if (mode_obj == @null || !oo_isa(mode_obj, "ZombieMode", true))
		return HAM_IGNORED;

	return oo_call(mode_obj, "OnTakeDamage", id, inflictor, attacker, damage, damagebits);
}

public ZombieMode@Ctor()
{
	oo_super_ctor("GameMode");
	oo_set(oo_this(), "allow_infect", false);
}

public ZombieMode@Dtor() {}

public ZombieMode@Think(ent)
{
	new this = oo_this();
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
	new this = oo_this();
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
	new this = oo_this();
	oo_set(this, "is_deathmatch", false);
	oo_set(this, "allow_infect", false);
	oo_call(this, "GameMode@End"); // call super class method
}

public ZombieMode@WinConditions()
{
	new this = oo_this();
	oo_call(this, "GameMode@WinConditions");

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
		oo_call(oo_this(), "End");
		return;
	}

	if (spawnable_count > 1 && zombie_count < 1 && human_count < 1) // all players are dead
	{
		TerminateRound(5.0, WINSTATUS_DRAW, ROUND_END_DRAW, "Round Draw", "rounddraw");
		oo_call(oo_this(), "End");
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
		oo_call(oo_this(), "End");
		return;
	}

	TerminateRound(5.0, WINSTATUS_DRAW, ROUND_END_DRAW, "Round Draw", "rounddraw");
	oo_call(oo_this(), "End");
}

public ZombieMode@RespawnPlayer(id)
{
	ctg_playerclass_change(id, "Zombie", false);
	oo_call(oo_this(), "GameMode@RespawnPlayer", id); // call super method
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
		cs_set_user_team(id, CS_TEAM_CT, CS_NORESET);
	}
	else if (team == CS_TEAM_SPECTATOR)
	{
		ctg_playerclass_change(id, "", false); // delete
	}
}

public bool:ZombieMode@InfectPlayer(victim, attacker, headshot)
{
	if (!oo_call(this, "CanPlayerInfect", id, attacker))
		return false;
	
	if (!is_user_connected(attacker) || attacker == victim)
		return false;

	SendDeathMsg(attacker, victim, headshot, "infection");
	FixDeadAttrib(victim);

	InfectionEffects(victim);
	ctg_playerclass_change(victim, "Zombie");
	return true;
}

public ZombieMode@OnTakeDamage(id, inflictor, attacker, Float:damage, damagebits)
{
	new this = oo_this();

	if (~damagebits & DMG_BULLET)
		return HAM_IGNORED;

	if (id == attacker || inflictor != attacker || !is_user_alive(attacker))
		return HAM_IGNORED;

	if (ctg_playerclass_is(attacker, "Zombie", true) && ctg_playerclass_is(id, "Human", true))
	{
		if (get_user_weapon(attacker) != CSW_KNIFE)
			return HAM_IGNORED;
		
		new Float:hp;
		pev(id, pev_health, hp);

		if (damage >= hp)
		{
			if (oo_call(this, "InfectPlayer", id, attacker, 0))
			{
				set_ent_data_float(id, @CBPLR, "m_flVelocityModifier", 0.0);

				// half hp on first infection
				pev(id, pev_health, hp);
				set_pev(id, pev_health, hp * 0.5);
				return HAM_SUPERCEDE;
			}
		}
	}
	
	return HAM_IGNORED;
}

public bool:ZombieMode@CanPlayerInfect(victim, attacker)
{
	if (!oo_get(@this, "allow_infect"))
		return false;
	
	return true;
}

public ctg_on_playerclass_change_post(id)
{
	if (is_user_alive(id))
	{
		new GameMode:mode_obj = ctg_gamemode_get_current();
		if (mode_obj != @null)
			oo_call(mode_obj, "WinConditions");
	}
}

InfectionEffects(id)
{
	new origin[3]
	get_user_origin(id, origin)

	message_begin(MSG_PVS, SVC_TEMPENTITY, origin);
	write_byte(TE_IMPLOSION); // TE id
	write_coord(origin[0]); // x
	write_coord(origin[1]); // y
	write_coord(origin[2]); // z
	write_byte(64); // radius
	write_byte(8); // count
	write_byte(3); // duration
	message_end();

	message_begin(MSG_PVS, SVC_TEMPENTITY, origin);
	write_byte(TE_PARTICLEBURST); // TE id
	write_coord(origin[0]); // x
	write_coord(origin[1]); // y
	write_coord(origin[2]); // z
	write_short(4); // radius
	write_byte(70); // color
	write_byte(1); // duration (will be randomized a bit)
	message_end();

	message_begin(MSG_PVS, SVC_TEMPENTITY, origin);
	write_byte(TE_DLIGHT); // TE id
	write_coord(origin[0]); // x
	write_coord(origin[1]); // y
	write_coord(origin[2]); // z
	write_byte(10); // radius
	write_byte(0); // r
	write_byte(200); // g
	write_byte(0); // b
	write_byte(2); // life
	write_byte(0); // decay rate
	message_end();
}