#include <amxmodx>
#include <cstrike>
#include <hamsandwich>

new g_msgScoreAttrib;

public plugin_init()
{
	register_plugin("CT No C4", "0.1", "colg");

	g_msgScoreAttrib = get_user_msgid("ScoreAttrib");

	register_message(g_msgScoreAttrib, "Message_ScoreAttrib");

	RegisterHam(Ham_Killed, "player", "OnPlayerKilled_Post", 1);
}

public Message_ScoreAttrib(msgid, msgdest, id)
{
	if (msgdest == MSG_ONE) // one player
	{
		if (is_user_connected(id) && !is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT) // is dead ct
		{
			new flags = get_msg_arg_int(2);
			if (flags & (1 << 1)) // has bomb flag
				set_msg_arg_int(2, ARG_BYTE, flags & ~(1 << 1)); // remove bomb flag
		}
	}
}

// after died
public OnPlayerKilled_Post(id)
{
	// this player is ct
	if (is_user_connected(id) && cs_get_user_team(id) == CS_TEAM_CT)
	{
		static maxClients;
		maxClients || (maxClients = get_maxplayers());

		new bomber = 0;
		// find the bomber index
		for (new i = 1; i <= MaxClients; i++)
		{
			if (is_user_connected(i) && cs_get_user_team(i) == CS_TEAM_T && cs_get_user_plant(i))
			{
				bomber = i;
				break;
			}
		}

		// has found
		if (bomber)
		{
			static msgScoreAttrib;
			msgScoreAttrib || (msgScoreAttrib = get_user_msgid("ScoreAttrib"));

			new flags = 0;
			if (!is_user_alive(bomber))
				flags |= (1 << 0); // dead flag

			message_begin(MSG_ONE, msgScoreAttrib, _, id);
			write_byte(bomber); // remove the bomb flag for this player
			write_byte(0);
			message_end();
		}
	}
}