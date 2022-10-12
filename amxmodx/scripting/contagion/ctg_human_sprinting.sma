#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <orpheu>
#include <ctg_const>
#include <ctg_playerclass>

new const g_CvarsNames[][] = 
{
	"cl_sidespeed",
	"cl_forwardspeed",
	"cl_backspeed",
	// "cl_upspeed",
	"cl_movespeedkey"
};

enum
{
	SIDE_SPEED,
	FORWARD_SPEED,
	BACK_SPEED,
	// UP_SPEED,
	MOVE_SPEED_KEY
};

new Float:g_UserCvarsValues[MAX_PLAYERS + 1][sizeof(g_CvarsNames)];
new bool:g_IsWalking[MAX_PLAYERS + 1];
new OrpheuStruct:g_ppmove;
new Float:g_move[MAX_PLAYERS + 1];
new Float:g_fwd[MAX_PLAYERS + 1];
new Float:sv_maxspeed;

public plugin_init()
{
	register_plugin("[CTG] Human Sprinting", CTG_VERSION, "Holla");
	OrpheuRegisterHook(OrpheuGetFunction("PM_Move"), "PM_Move");
	OrpheuRegisterHook(OrpheuGetFunction("PM_ReduceTimers"), "PM_ReduceTimers");

	register_forward(FM_PlayerPreThink, "OnPlayerPreThink");

	new pcvar = get_cvar_pointer("sv_maxspeed");
	bind_pcvar_float(pcvar, sv_maxspeed);
}

public OrpheuHookReturn:PM_Move(OrpheuStruct:ppmove , server)
{    
	g_ppmove = ppmove;
}

public OrpheuHookReturn:PM_ReduceTimers()
{
	//If you need player id for anything
	new id = OrpheuGetStructMember(g_ppmove, "player_index") + 1;

	if (!is_user_connected(id))
		return OrpheuIgnored;

	g_IsWalking[id] = false;

	new OrpheuStruct:cmd = OrpheuStruct:OrpheuGetStructMember(g_ppmove, "cmd");

	new Float:maxspeed = Float:OrpheuGetStructMember(g_ppmove, "maxspeed");
	if (maxspeed <= 1.0)
		return OrpheuIgnored;
	
	new Float:sidemove = Float:OrpheuGetStructMember(cmd, "sidemove");
	if (sidemove != 0.0)
		return OrpheuIgnored;

	new Float:forwardmove = Float:OrpheuGetStructMember(cmd, "forwardmove");
	if (forwardmove <= 0.0 || forwardmove == 200.0)
		return OrpheuIgnored;

	new Float:move = floatmin(g_UserCvarsValues[id][FORWARD_SPEED], maxspeed);
	if (floatround(forwardmove) == floatround(move * 0.52))
	{
		OrpheuSetStructMember(g_ppmove, "maxspeed", maxspeed * 1.3);
		OrpheuSetStructMember(cmd, "forwardmove", move * 1.3);
		g_IsWalking[id] = true;
	}

	return OrpheuIgnored;
}

public OnPlayerPreThink(id)
{
	if (g_IsWalking[id])
	{
		static Float:updateTime[33];
		if (get_gametime() > updateTime[id])
		{
			set_hudmessage(0, 255, 0, -1.0, -1.0, 0, 0.0, 0.15, 0.0, 0.0, 3);
			show_hudmessage(id, "正在 SHIFT + W ...");
			updateTime[id] = get_gametime() + 0.1;
		}
	}
}

public client_disconnected(id)
{
	remove_task(id);
}

public client_putinserver(id)
{
	if (!is_user_bot(id))
	{
		set_task(0.1, "CheckCvars", id);
		set_task(10.0, "CheckCvars", id, _, _, "b");
	}
}

public CheckCvars(id)
{
	if (is_user_connected(id))
	{
		new cvar_index[1];
		for (new i = 0; i < sizeof(g_CvarsNames); i++)
		{
			cvar_index[0] = i;
			query_client_cvar(id, g_CvarsNames[i], "CvarResult", sizeof(cvar_index), cvar_index);
		}
	}
}

public CvarResult(id, cvar[], value[], parms[])
{
	if (is_user_connected(id))
	{
		g_UserCvarsValues[id][parms[0]] = str_to_float(value);
		query_client_cvar(id, cvar, "CvarResult", 1, parms);
	}
}